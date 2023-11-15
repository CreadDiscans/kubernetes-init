if [ -f "cuda_ready" ]; then
    # CUDA 설치
    sudo echo 'detect cuda_ready'
    wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
    sudo sh cuda_11.8.0_520.61.05_linux.run
    echo 'export PATH=$PATH:/usr/local/cuda-11.8/bin' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64' >> ~/.bashrc
    source ~/.bashrc
    # nvidia-container-toolkit 설치
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && \
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    # nvidia docker 
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
    sudo sed -i "s/\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes\]/$nvidia_config/g" /etc/containerd/config.toml
    sudo systemctl restart containerd
else
    sudo apt update
    sudo apt install -y build-essential
    # nouveau 비활성화
    cat <<EOF | sudo tee -a /etc/modprobe.d/blacklist.conf
# For nvidia original driver
# disable nouveau driver
blacklist nouveau
blacklist lbm-nouveau
options nouveau modset=0
alias nouveau off
alias lbm-nouveau off
EOF
    sudo update-initramfs -u
    touch cuda_ready
    sudo reboot
fi
