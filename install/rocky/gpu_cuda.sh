# 커널 업데이트
# sudo dnf install kernel-4.18.0-553.36.1.el8_10.x86_64
# reboot

# nvidia driver 설치, rocky8 기준이므로 환경에 따라 수정 필요
sudo dnf install epel-release -y
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
sudo dnf install kernel-devel-$(uname -r) kernel-headers-$(uname -r) -y
sudo dnf install nvidia-driver nvidia-settings -y
sudo dnf -y install cuda-toolkit-12-8 # driver 570 인경우
sudo dnf -y module install nvidia-driver:open-dkms
sudo dkms autoinstall
# reboot

# nvidia-container-toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum-config-manager --enable nvidia-container-toolkit-experimental
sudo yum install -y nvidia-container-toolkit
sudo yum install -y nvidia-docker2

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

sudo systemctl restart docker
# nvidia container
sudo sed -i 's/default_runtime_name = "runc"/default_runtime_name = "nvidia"/g' /etc/containerd/config.toml
nvidia_config="\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes\]\n"
nvidia_config+="        \[plugins.\"io.containerd.grpc.v1.cri\"\.containerd.runtimes.nvidia\]\n"
nvidia_config+="          privileged_without_host_devices = false\n"
nvidia_config+="          runtime_engine = \"\"\n"
nvidia_config+="          runtime_root = \"\"\n"
nvidia_config+="          runtime_type = \"io\.containerd\.runc\.v2\"\n"
nvidia_config+="          \[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.nvidia.options\]\n"
nvidia_config+="            BinaryName = \"\/usr\/bin\/nvidia-container-runtime\"\n"
nvidia_config+="            SystemdCgroup = true\n\n"
sudo sed -i "s/\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes\]/$nvidia_config/g" /etc/containerd/config.toml
sudo systemctl restart containerd
