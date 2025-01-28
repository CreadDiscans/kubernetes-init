FROM kubeflownotebookswg/codeserver-python:v1.9.2

USER root

RUN apt-get update && apt-get install -y sudo && \
    echo "jovyan ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER jovyan