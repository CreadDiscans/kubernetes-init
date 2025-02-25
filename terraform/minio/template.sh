# helm repo add minio-operator https://operator.min.io
helm template operator minio-operator/operator -n minio-operator > yaml/minio.yaml
kubectl kustomize https://github.com/minio/operator/examples/kustomization/base/ > yaml/tenant-base.yaml