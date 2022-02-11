# Helm CLI Usage

To install the chart,
first add the repo

`helm repo add variant-inc-helm-charts https://variant-inc.github.io/lazy-helm-charts/ --password <token>`

and then install the chart using

`helm upgrade --install my-cron variant-inc-helm-charts/variant-cron -n my-namespace --set "revision=abc123" --set "deployment.image.tag=ecr.amazonaws.com/my-project/my-cron:abc123 --set "schedule='* * * * *'"`
