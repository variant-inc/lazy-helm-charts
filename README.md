# Helm Charts

This repository holds all helm charts that are used by DevOps

## Add Repo

To import the chart repository, do

`helm repo add variant-inc-helm-charts https://variant-inc.github.io/lazy-helm-charts/ --password <token>`

## Using a lazy-helm-chart as a Subchart

### Chart.yaml

```yaml
apiVersion: v2
name: coolapi
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: 1.16.0

# Insert the chart as a dependency
dependencies:
- name: <<Chart Name>>
  version: "0.2.0" #Version to use of the subchart
  repository: "https://variant-inc.github.io/lazy-helm-charts/"
```

### values.yaml

```yaml
# In your parent chart insert the name of the subchart as it's values' key
<<Chart Name>>:
  # Values for <<Chart Name>> goes here
  nameOverride: "coolapi"
  fullnameOverride: ""
  istio:
    enabled: true
    ## For traffic to the cluster
    ingress:
      public: false
      # # Provide only the full hostname
      host: ops-drivevariant.com
      # Add endpoints to be rerouted to / in public access
      redirects: []
      # # Should the endpoint be external or internal
      backend:
        service:
          name: '{{ include "chart.fullname" . }}'
          ## port should be number
          port: "{{ .Values.global.port }}"
```

### Pull the dependency chart and Install

`helm dependency update`

`helm template coolapi  . -n cool-test --values values.yaml`

`helm upgrade --install coolapi  . -n cool-test --values values.yaml --render-subchart-notes --create-namespace`
