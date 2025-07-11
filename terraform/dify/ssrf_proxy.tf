

resource "kubernetes_config_map" "ssrf_proxy_cm" {
  metadata {
    name      = "ssrf-proxy-cm"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    HTTP_PORT          = "3128"
    COREDUMP_DIR       = "/var/spool/squid"
    REVERSE_PROXY_PORT = "8194"
    SANDBOX_HOST       = "sandbox-service"
    SANDBOX_PORT       = "8194"
  }
}

resource "kubernetes_config_map" "ssrf_proxy_template" {
  metadata {
    name      = "ssrf-proxy-template"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    TEMPLATE   = <<EOF
acl localnet src 0.0.0.1-0.255.255.255	# RFC 1122 "this" network (LAN)
acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
acl localnet src 100.64.0.0/10		# RFC 6598 shared address space (CGN)
acl localnet src 169.254.0.0/16 	# RFC 3927 link-local (directly plugged) machines
acl localnet src 172.16.0.0/12		# RFC 1918 local private network (LAN)
acl localnet src 192.168.0.0/16		# RFC 1918 local private network (LAN)
acl localnet src fc00::/7       	# RFC 4193 local private network range
acl localnet src fe80::/10      	# RFC 4291 link-local (directly plugged) machines
acl SSL_ports port 443
# acl SSL_ports port 1025-65535   # Enable the configuration to resolve this issue: https://github.com/langgenius/dify/issues/12792
acl Safe_ports port 80		# http
acl Safe_ports port 21		# ftp
acl Safe_ports port 443		# https
acl Safe_ports port 70		# gopher
acl Safe_ports port 210		# wais
acl Safe_ports port 1025-65535	# unregistered ports
acl Safe_ports port 280		# http-mgmt
acl Safe_ports port 488		# gss-http
acl Safe_ports port 591		# filemaker
acl Safe_ports port 777		# multiling http
acl CONNECT method CONNECT
acl allowed_domains dstdomain .marketplace.dify.ai
http_access allow allowed_domains
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localhost
include /etc/squid/conf.d/*.conf
http_access deny all

################################## Proxy Server ################################
http_port $${HTTP_PORT}
coredump_dir $${COREDUMP_DIR}
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern \/(Packages|Sources)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
refresh_pattern \/Release(|\.gpg)$ 0 0% 0 refresh-ims
refresh_pattern \/InRelease$ 0 0% 0 refresh-ims
refresh_pattern \/(Translation-.*)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
refresh_pattern .		0	20%	4320


# cache_dir ufs /var/spool/squid 100 16 256
# upstream proxy, set to your own upstream proxy IP to avoid SSRF attacks
# cache_peer 172.1.1.1 parent 3128 0 no-query no-digest no-netdb-exchange default 

################################## Reverse Proxy To Sandbox ################################
http_port $${REVERSE_PROXY_PORT} accel vhost
cache_peer $${SANDBOX_HOST} parent $${SANDBOX_PORT} 0 no-query originserver
acl src_all src all
http_access allow src_all

# Unless the option's size is increased, an error will occur when uploading more than two files.
client_request_buffer_max_size 100 MB
    EOF
    ENTRYPOINT = <<EOF
#!/bin/bash

# Modified based on Squid OCI image entrypoint

# This entrypoint aims to forward the squid logs to stdout to assist users of
# common container related tooling (e.g., kubernetes, docker-compose, etc) to
# access the service logs.

# Moreover, it invokes the squid binary, leaving all the desired parameters to
# be provided by the "command" passed to the spawned container. If no command
# is provided by the user, the default behavior (as per the CMD statement in
# the Dockerfile) will be to use Ubuntu's default configuration [1] and run
# squid with the "-NYC" options to mimic the behavior of the Ubuntu provided
# systemd unit.

# [1] The default configuration is changed in the Dockerfile to allow local
# network connections. See the Dockerfile for further information.

echo "[ENTRYPOINT] re-create snakeoil self-signed certificate removed in the build process"
if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
    /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite > /dev/null 2>&1
fi

tail -F /var/log/squid/access.log 2>/dev/null &
tail -F /var/log/squid/error.log 2>/dev/null &
tail -F /var/log/squid/store.log 2>/dev/null &
tail -F /var/log/squid/cache.log 2>/dev/null &

# Replace environment variables in the template and output to the squid.conf
echo "[ENTRYPOINT] replacing environment variables in the template"
awk '{
    while(match($0, /\$${[A-Za-z_][A-Za-z_0-9]*}/)) {
        var = substr($0, RSTART+2, RLENGTH-3)
        val = ENVIRON[var]
        $0 = substr($0, 1, RSTART-1) val substr($0, RSTART+RLENGTH)
    }
    print
}' /etc/squid/squid.conf.template > /etc/squid/squid.conf

/usr/sbin/squid -Nz
echo "[ENTRYPOINT] starting squid"
/usr/sbin/squid -f /etc/squid/squid.conf -NYC 1
    EOF
  }
}


resource "kubernetes_deployment" "ssrf_proxy_deploy" {
  metadata {
    name      = "ssrf-proxy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "ssrf-proxy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ssrf-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "ssrf-proxy"
        }
      }
      spec {
        container {
          name  = "ssrf-proxy"
          image = "ubuntu/squid:latest"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.ssrf_proxy_cm.metadata.0.name
            }
          }
          command = [
            "sh",
            "-c",
            "cp /docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/\r$$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh"
          ]
          port {
            container_port = 3128
          }
          volume_mount {
            name       = "template"
            mount_path = "/etc/squid/squid.conf.template"
            sub_path   = "TEMPLATE"
          }
          volume_mount {
            name       = "template"
            mount_path = "/docker-entrypoint-mount.sh"
            sub_path   = "ENTRYPOINT"
          }
        }
        volume {
          name = "template"
          config_map {
            name = kubernetes_config_map.ssrf_proxy_template.metadata.0.name

          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service_ssrf_proxy" {
  metadata {
    name      = "ssrf-proxy-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    selector = kubernetes_deployment.ssrf_proxy_deploy.metadata.0.labels
    port {
      port        = 3128
      target_port = 3128
    }
  }
}
