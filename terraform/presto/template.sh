# helm repo add presto https://prestodb.github.io/presto-helm-charts
helm template presto presto/presto --namespace presto > yaml/presto.yaml
