# Variant Handler Helm Chart

![Version: 1.0.2](https://img.shields.io/badge/Version-1.0.2-informational?style=flat-square)

A Helm chart for kubernetes handler

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | (map) Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| autoscaling.enabled | bool | `false` | Flag to trigger HPA, Allowd values true or false |
| autoscaling.maxReplicas | int | `5` | Maximum replicas of pod |
| autoscaling.minReplicas | int | `1` | Minimum replicas of pod |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | (int) CPU Utilization Percentage. |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read. See [secrets](#secrets) for more details. |
| configVars | object | `{}` | (map) User defined environment variables are implemented here. |
| deployment.args | list | `[]` | (list) List of arguments that can be passed in the image. |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | (string) IfNotPresent, Always, Never |
| deployment.image.tag | string | `"tag"` | (string) The full URL of the image to be deployed containing the tag |
| deployment.podAnnotations | object | `{}` | (map) https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deployment.resources.limits.cpu | int | `1` | (int) Limits CPU |
| deployment.resources.limits.memory | string | `"768Mi"` | (string) Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | (float) Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | (string) Request memory |
| nodeSelector | object | `{}` | (map) Node labels for pod assignment |
| podSecurityContext.fsGroup | int | `65534` | Groups of nobody |
| replicaCount | int | `1` | replicatCount |
| revision | string | `"abc"` | (string) Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision`  that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | object | `{}` | (map) User defined secret variables are implemented here. |
| securityContext | object | `{}` | (map) Security Context for containers |
| service.healthCheckPath | string | `"/health"` | Health check URI, This will be used in probes to check container status |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application.  If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). |
| serviceMonitor.interval | string | `"10s"` | Frequency at which Prometheus metrics will be collected from your service |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Maximum wait duration for Prometheus metrics response from your service |
| tolerations | list | `[]` | (list) Tolerations for pod assignment |

Use this chart to deploy an handler image to Kubernetes -- the Variant, CloudOps-approved way.

## TL;DR

Review the [Assumptions](#assumptions) and provide the [Minimum Required Inputs](#minimum-required-input-table) to get deployed using Terraform:

```bash
resource "kubernetes_namespace" "test_namespace" {
  metadata {
    name = "my-namespace"
    labels = {
      "istio-injection" : "enabled"
    }
  }
}

resource "helm_release" "test_api_release" {
  repository        = "https://variant-inc.github.io/lazy-helm-charts/"
  chart             = "variant-handler"
  version           = "2.0.0"
  name              = "test-my-handler"
  namespace         = kubernetes_namespace.test_namespace.metadata[0].name
  lint              = true
  dependency_update = true

    values = [<<EOF

deployment:
  image:
    tag: ecr.amazonaws.com/my-project/my-api:abc123

EOF
  ]
}
```

### What does it do by default

- No Infrastructure Access - Amazon services are firewall whitelisted by default, but you still need an AWS role if you need access to AWS services (SQS, SNS, RDS, etc.)
  - See [infrastructure permissions](#infrastructure-permissions)

## Before you start

1. Use a CloudOps Github CI workflow that publishes an image
   - [.NET](https://github.com/variant-inc/actions-dotnet)
   - [Node](https://github.com/variant-inc/actions-nodejs)
   - [Python](https://github.com/variant-inc/actions-python)
1. Host a health check endpoint via `GET /health` which returns a status code < 400 when healthy or >= 400 when unhealthy
1. Host a Prometheus metrics endpoint via `GET /metrics`
   - This chart configures a ServiceMonitor (see [Object Reference](#object-reference)) to collect metrics from your API
   - Middleware exists for most major API frameworks that provide a useful out of the box HTTP server metrics, and simple tools to push custom metrics for your product:
     - [.NET](https://github.com/prometheus-net/prometheus-net)
     - Node - [NestJS](https://github.com/digikare/nestjs-prom), [Express](https://github.com/joao-fontenele/express-prometheus-middleware)
     - Python - [Flask](https://github.com/rycus86/prometheus_flask_exporter), [Django](https://github.com/korfuri/django-prometheus)

## Minimum Required Inputs

### Assumptions

See [Application Configuration](#application-configuration) to override these assumptions if necessary.

1. Your API, health check endpoint, and metrics endpoint all run on the same server at port 9000
1. Your container executes without any required arguments (i.e can be executed as `docker run [image]`)
1. There are no required envrionment variables for your API to function

### Release name

- Provide the `name` [argument](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#name) argument in the `helm_release` resource
- According to the [Workload Naming Conventions](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/1665859671/Recommended+Conventions#Workload-Naming-Conventions), this name must end with `-api` such as `schedule-adherence-api` or `driver-api`
- This will be used as the base [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart

### Minimum required input table

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description |
| - | - | - |
| revision | All | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision` that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| istio.ingress.host | VirtualService | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/LibraryVariableSets-121?activeTab=variables) Octopus Variable Set  |
| deployment.image.tag | Deployment | The full URL of the image to be deployed containing the HTTP API application |

## Optional Inputs

### Infrastructure Permissions

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description |
| - | - | - |
| serviceAccount.roleArn | ServiceAccount | ARN of the IAM role to be assumed by your application. If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). |

### Application Configuration

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Default Value |
| - | - | - | - |
| service.port | Service, ServiceMonitor | Port for internal services to access your API | 80 |
| service.targetPort | Service, Deployment | Port on your container that exposes your HTTP API | 9000 |
| service.metricsPort | Service, ServiceMonitor, Deployment | Port which serves prometheus metrics endpoint at `/metrics` | service.targetPort |
| service.healthCheckPort | Service, ServiceMonitor, Deployment | - | service.targetPort |
| deployment.args | Deployment | - | [] |
| deployment.envVars | Deployment | - | [] |
| deployment.conditionalEnvVars | Deployment | - | [] |

### Resources and Scaling

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description |
| - | - | - |
| deployment.resource | Deployment | - |
| autoscaling | HorizontalPodAutoscaler | - |

### Secrets

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Default Value |
| - | - | - | - |
| secrets | ExternalSecret | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read. | [] |
| secrets[N].name | ExternalSecret | Name of the AWS Secrets Manager secret |
| secrets[N].fileName | ExternalSecret, Deployment | Desired file name which will contain all contents of the AWS secret |
| secrets[N].mountPath | Deployment | Directory (no trailing slash) where the above secrets[N].fileName will be mounted (e.g. if fileName = secret.json and mountPath = /app/secrets then secret will be available at /app/secrets/secret.json) | |

## Kubernetes Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
