# helm repo add superset https://apache.github.io/superset
helm template superset superset/superset -n superset > yaml/superset.yaml