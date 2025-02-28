# helm repo add jenkins https://charts.jenkins.io
helm template jenkins jenkins/jenkins -n jenkins > yaml/jenkins.yaml