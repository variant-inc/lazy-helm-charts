# Variant Handler Helm Chart

![Version: 1.1.6](https://img.shields.io/badge/Version-1.1.6-informational?style=flat-square)

A Helm chart for kubernetes handler

### What this chart provides to you by default

- A chart to deploy a handler image to Kubernetes -- the Variant,
  CloudOps-approved way.
- An handler that is isolated from infrastructure access - Amazon services are
  firewall whitelisted by default, but you still need an AWS role if you need
  access to AWS services (SQS, SNS, RDS, etc.)
  - See [infrastructure permissions](#infrastructure-permissions)

## Before you start

### Prerequisites

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

### Assumptions

*See [Application Configuration](#application-configuration) to override these assumptions if necessary.*

1. Your API, health check endpoint, and metrics endpoint all run on the same server at port 9000
1. Your container executes without any required arguments (i.e can be executed as `docker run [image]`)
1. There are no required envrionment variables for your API to function

***

# Create Your Chart
**Follow This Quick Example:** [Using a lazy-helm-chart as a Subchart](../../README.md)

***

### *OPTIONAL* Configuration Inputs

#### Application Configuration

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Default Value |
| - | - | - | - |
| service.port | Service, ServiceMonitor | Port for internal services to access your API | 80 |
| service.targetPort | Service, Deployment | Port on your container that exposes your HTTP API | 9000 |
| service.metricsPort | Service, ServiceMonitor, Deployment | Port which serves prometheus metrics endpoint at `/metrics` | service.targetPort |
| service.healthCheckPort | Service, ServiceMonitor, Deployment | - | service.targetPort |
| deployment.args | Deployment | List of arguments that can be passed in the image. | [] |
| deployment.envVars | Deployment | List variables defined in a Pod configuration that overrides any environment variables specified in the container image. | [] |
| deployment.conditionalEnvVars | Deployment | List of Conditional Env Vars denoted by conditional (bool) | [] |

#### [Infrastructure Permissions](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/rolearn.md)

#### [Egress Configuration](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/egress.md) (*how your service will access external resources*)

#### [Secrets Configuration](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/secrets.md)

## Kubernetes Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | (map) Affinity for pod assignment [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) |
| autoscaling.enabled | bool | `false` | Flag to trigger HPA, Allowed values true or false. [Autoscaling](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/autoscaling.md) |
| autoscaling.maxReplicas | int | `5` | (int) Maximum Number of Replicas. [Autoscaling](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/autoscaling.md) |
| autoscaling.minReplicas | int | `1` | (int) Minimum Number of Replicas. [Autoscaling](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/autoscaling.md) |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | (int) CPU Utilization Percentage. [Autoscaling](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/autoscaling.md) |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. [Autoscaling](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/autoscaling.md) |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read. See [AWS Secrets](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/secrets.md) for more details. |
| configVars | object | `{}` | (map) User defined environment variables are implemented here. [More Information](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/secrets.md) |
| deployment.args | list | `[]` | (list) List of arguments that can be passed in the image. |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | (string) IfNotPresent, Always, Never |
| deployment.image.tag | string | `"tag"` | (string) The full URL of the image to be deployed containing the tag |
| deployment.podAnnotations | object | `{}` | (map) https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deployment.resources.limits.cpu | int | `1` | (int) Limits CPU |
| deployment.resources.limits.memory | string | `"768Mi"` | (string) Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | (float) Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | (string) Request memory |
| istio.egress | list | `[]` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/egress.md) and [Istio](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/istio.md) for more details. |
| livenessProbe | object | `{}` | (map) Indicates whether container is running. See [Probe](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/probes.md) |
| nodeSelector | object | `{}` | (map) Node labels for pod assignment [NodeSelector](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/nodeselector.md) |
| podSecurityContext.fsGroup | int | `65534` | Groups of nobody |
| readinessProbe | object | `{}` | (map) Indicates whether container is ready for requests. See [Probe](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/probes.md) |
| replicaCount | int | `1` | replicaCount |
| revision | string | `"abc"` | (string) Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision` that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | object | `{}` | (map) User defined secret variables are implemented here. [More Information](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/secrets.md) |
| securityContext | object | `{}` | (map) Security Context for containers |
| service.healthCheckPath | string | `"/health"` | Health check URI, This will be used in probes to check container status |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application.  If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). [RoleArn](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/rolearn.md) |
| serviceMonitor.interval | string | `"10s"` | Frequency at which Prometheus metrics will be collected from your service |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Maximum wait duration for Prometheus metrics response from your service |
| tags | object | `{}` | (map) Deployment tags |
| tolerations | list | `[]` | (list) Tolerations for pod assignment [Tolerations](https://github.com/variant-inc/terragrunt-variant-apps/tree/master/docs/tolerations.md) |
