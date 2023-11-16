if [ -f "cuda_ready" ]; then
    # nvidia-container-toolkit 설치
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
&& \
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo apt-get install -y nvidia-docker2
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
    nvidia_config+="            SystemdCgroup = true\n\n"
    sudo sed -i "s/\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes\]/$nvidia_config/g" /etc/containerd/config.toml
    sudo systemctl restart containerd
else
    sudo echo 'install cuda 11.8'
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2204-11-8-local_11.8.0-520.61.05-1_amd64.deb
    sudo cp /var/cuda-repo-ubuntu2204-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda
    touch cuda_ready
    sudo reboot
fi
