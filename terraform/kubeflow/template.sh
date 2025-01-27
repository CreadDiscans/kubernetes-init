if [ ! -d "manifests" ]; then
    git clone https://github.com/kubeflow/manifests.git --branch v1.9.1
fi

kustomize build manifests/common/knative/knative-serving/overlays/gateways > yaml/knative-serving.yaml
kustomize build manifests/common/istio-1-22/cluster-local-gateway/base > yaml/knative-gateway.yaml
kustomize build manifests/common/networkpolicies/base > yaml/networkpolicy.yaml
kustomize build manifests/common/kubeflow-roles/base > yaml/role.yaml
kustomize build manifests/common/istio-1-22/kubeflow-istio-resources/base > yaml/istio-resource.yaml
kustomize build manifests/apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user > yaml/pipeline.yaml 
kustomize build manifests/contrib/kserve/kserve > yaml/kserve.yaml
kustomize build manifests/contrib/kserve/models-web-app/overlays/kubeflow > yaml/kserve-web.yaml
kustomize build manifests/apps/katib/upstream/installs/katib-with-kubeflow > yaml/katib.yaml
kustomize build manifests/apps/centraldashboard/overlays/oauth2-proxy > yaml/centraldashboard.yaml
kustomize build manifests/apps/admission-webhook/upstream/overlays/cert-manager > yaml/admission-webhook.yaml
kustomize build manifests/apps/jupyter/notebook-controller/upstream/overlays/kubeflow > yaml/notebook.yaml
kustomize build manifests/apps/jupyter/jupyter-web-app/upstream/overlays/istio > yaml/notebook-web.yaml
kustomize build manifests/apps/pvcviewer-controller/upstream/default > yaml/pvc-viewer.yaml
kustomize build manifests/apps/profiles/upstream/overlays/kubeflow > yaml/profile.yaml
kustomize build manifests/apps/volumes-web-app/upstream/overlays/istio > yaml/volume-web.yaml
kustomize build manifests/apps/tensorboard/tensorboards-web-app/upstream/overlays/istio > yaml/tensorboard-web.yaml
kustomize build manifests/apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow > yaml/tensorboard.yaml
kustomize build manifests/apps/training-operator/upstream/overlays/kubeflow > yaml/training-operator.yaml
kustomize build manifests/common/user-namespace/base > yaml/user.yaml