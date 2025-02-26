# helm repo add stakater https://stakater.github.io/stakater-charts
helm template reloader stakater/reloader -n reloader > yaml/reloader.yaml