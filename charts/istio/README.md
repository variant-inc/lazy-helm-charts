# Istio Objects Helm Charts

## Install

To install the chart,
first add the repo

`helm repo add variant-in-helm-charts https://variant-inc.github.io/in-helm-charts/ --password <token>`

and then install the chart using

`helm upgrade --install devops-istio -n sample-ns -f values.yaml`
