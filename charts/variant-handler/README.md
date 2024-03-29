# Variant Handler Helm Chart

![Version: 1.2.8](https://img.shields.io/badge/Version-1.2.8-informational?style=flat-square) A Helm chart for kubernetes handler

## What this chart provides to you by default

- A chart to deploy a handler image to Kubernetes -- the Variant,
  CloudOps-approved way.
- A handler that is isolated from infrastructure access - Amazon services are
  firewall whitelisted by default, but you still need an AWS role if you need
  access to AWS services (SQS, SNS, RDS, etc.)
  - See [infrastructure permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn)

## Before you start

### Prerequisites

1. Use a CloudOps Github CI workflow that publishes an image
   - [.NET](https://github.com/variant-inc/actions-dotnet)
   - [Node](https://github.com/variant-inc/actions-nodejs)
   - [Python](https://github.com/variant-inc/actions-python)
1. Host a health check endpoint via `GET /health` which returns a status code < 400 when healthy or >= 400 when unhealthy
1. Host a Prometheus metrics endpoint via `GET /metrics`
   - This chart configures a ServiceMonitor (see [Application Configuration](#application-configuration)) to collect metrics from your API
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

#### [Infrastructure Permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn)

#### [Egress Configuration](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress)

(*how your service will access external resources*)

#### [Environment Variables](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables)

## Kubernetes Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)

<!-- markdownlint-disable MD034 -->

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.enabled | bool | `false` | Flag to trigger HPA, Allowed values true or false. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.maxReplicas | int | `5` | Maximum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.minReplicas | int | `2` | Minimum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | CPU Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` | Memory Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| awsSecrets | list | Example: `[{ "name": "eng-secret-in-aws", "type": "" }]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [AWS Secrets](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) for more details. |
| configVars | map | Example: `bar: foo` | User defined environment variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | IfNotPresent, Always, Never |
| deployment.image.tag | string | `"tag"` | The full URL of the image to be deployed containing the tag |
| deployment.resources.limits.cpu | int | `nil` | Limits CPU, intentionally set to null, can't be overridden |
| deployment.resources.limits.memory | string | `"768Mi"` | Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | Request memory |
| istio.egress | list | `[]` | A whitelist of external services that your application requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress) and [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress) for more details. |
| kafka | object | `{"lagThreshold":10}` | Autoscaling for Kafka |
| livenessProbe | map | `{}` | Indicates whether container is running. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes) |
| maxUnavailable | int | `1` | Minimum number of pods that should be available after an eviction See [Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) |
| podAnnotations | map | `{}` | https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podSecurityContext | map | `{"fsGroup":65534}` | Security Context for pods |
| podSecurityContext.fsGroup | int | `65534` | The files created in the container will be created with this gid `65534` is a `nobody` group |
| readinessProbe | map | `{}` | Indicates whether container is ready for requests. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes) |
| replicaCount | int | `1` | replicaCount |
| secretVars | map | Example: `foo: bar` | User defined secret variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| securityContext | map | `{"capabilities":{"drop":["ALL"]},"runAsGroup":null,"runAsUser":null}` | Security Context for containers |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.runAsGroup | int | `nil` | Runs as numeric user |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceMonitor.enabled | bool | `false` | Service Monitor Enabled |
| usxpressCACertBundle.certMountPath | string | `"/etc/ssl/certs/"` | The cert is mounted to the default path mentioned. The path can also be changed. |
| usxpressCACertBundle.enabled | bool | `true` | If set to true, volume mounts the certificate from the custom-ca-certs secret |
