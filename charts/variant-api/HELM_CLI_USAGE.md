# Helm CLI Usage

To install the chart,
first add the repo

`helm repo add variant-inc-helm-charts https://variant-inc.github.io/lazy-helm-charts/ --password <token>`

and then install the chart using

`helm upgrade --install my-api variant-inc-helm-charts/variant-api -n my-namespace --set "istio.ingress.host=dev-drivevariant.com" --set "revision=abc123" --set "deployment.image.tag=ecr.amazonaws.com/my-project/my-api:abc123"`
