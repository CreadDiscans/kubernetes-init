# nvidia driver설치 및 nvidia-smi 동작 확인
sudo dnf -y install cuda-toolkit-13-0 # cuda 버전 확인

curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit

# /etc/nvidia-container-runtime/config.toml 에서 crun이 맨 앞으로 오도록
# [nvidia-container-runtime]
# runtimes = ["crun", "runc"]

cat <<EOF | sudo tee /etc/crio/crio.conf.d/99-nvidia.conf
[crio]

  [crio.runtime]
    default_runtime = "nvidia"

    [crio.runtime.runtimes]

      [crio.runtime.runtimes.nvidia]
        runtime_path = "/usr/bin/nvidia-container-runtime"
        runtime_type = "oci"
        runtime_root = "/run/nvidia-container-runtime"
EOF
sudo nvidia-ctk runtime configure --runtime=crio --set-as-default --config=/etc/crio/crio.conf.d/99-nvidia.conf
sudo systemctl restart crio
