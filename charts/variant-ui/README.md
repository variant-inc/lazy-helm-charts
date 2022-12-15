# Variant UI Helm Chart

![Version: 1.4.19](https://img.shields.io/badge/Version-1.4.19-informational?style=flat-square)

A Helm chart for a web UI configuration

### How do I access my UI?

- Via VPN at `https://api.<DOMAIN>-drivevariant.com/my-namespace/my-ui/`

## Before you start

### Prerequisites

1. Use a CloudOps Github CI workflow that publishes an image
   - [.NET](https://github.com/variant-inc/actions-dotnet)
   - [Node](https://github.com/variant-inc/actions-nodejs)
   - [Python](https://github.com/variant-inc/actions-python)
1. Host a health check endpoint via `GET /health` which returns a status code < 400 when healthy or >= 400 when unhealthy
1. Host a Prometheus metrics collection endpoint via `GET /metrics`
   - This chart configures a ServiceMonitor (see [Application Configuration](#application-configuration)) to collect metrics from your API
   - Middleware exists for most major API frameworks that provide a useful out-of-the box HTTP server metrics, and simple tools to push custom metrics for your product:
     - [.NET](https://github.com/prometheus-net/prometheus-net)
     - Node - [NestJS](https://github.com/digikare/nestjs-prom), [Express](https://github.com/joao-fontenele/express-prometheus-middleware)
     - Python - [Flask](https://github.com/rycus86/prometheus_flask_exporter), [Django](https://github.com/korfuri/django-prometheus)

### Assumptions

*See [Application Configuration](#application-configuration) to override these assumptions if necessary.*

1. Your API, health check endpoint, and metrics endpoint all run on the same server at port 9000
1. Your container executes without any required arguments (i.e can be executed as `docker run [image]`)
1. There is no required environment variable for your UI to function

***

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

#### Ingress Configuration

(*how resources will access your service*)

URL Formats

- Public: `api.{istio.ingress.host}/{target-namespace}/{helm-release-name}`
- Private (OpenVPN): `api.internal.{istio.ingress.host}/{target-namespace}/{helm-release-name}`

When using public ingess, the following URL prefixes are rerouted to the root URL and are essentially blocked. They must be accessed internally, or through VPN. You can add to this list in Values.istio.ingress.redirects.

- health
- swagger
- swaggerui

#### [Infrastructure Permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn)

#### [Egress Configuration](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress)

(*how your service will access external resources*)

#### [Environment Variables](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables)

#### Special Considerations

##### Custom Hosts

When using custom hosts, ie

```yaml
istio:
  enabled: true
  ingress:
    # hosts:
      - url: "internal.apps.drive-variant.com" ##Included
      - url: "awesomeapp.drive-variant.com" ##Custom
```

The host must be setup as a SAN on the certificate of the cluster. Please create a [support request](http://cloudops.ops-drivevariant.com/support) to include your host name in our cluster's certificate.

## Kubernetes Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | map | `{}` | Affinity for pod assignment [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) |
| autoscaling.maxReplicas | int | `5` | Maximum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.minReplicas | int | `1` | Minimum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | CPU Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling) |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [AWS Secrets](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) for more details. |
| configMountPath | string | `"/app/config"` | Mount path for configVars JSON file. Default /app/config. Config file full path would be /app/config/config.json |
| configVars | map | `{}` | User defined environment variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| deployment.args | list | `[]` | List of arguments that can be passed in the image. |
| deployment.conditionalEnvVars | list | `[]` | List of Conditional Env Vars denoted by conditional (bool) and envVars (list) |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | IfNotPresent, Always, Never |
| deployment.image.tag | string | `nil` | The full URL of the image to be deployed containing the UI web application |
| deployment.podAnnotations | map | `{}` | https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deployment.resources.limits.cpu | int | `nil` | Limits CPU, intentionally set to null, can't be overridden |
| deployment.resources.limits.memory | string | `"768Mi"` | Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | Request memory |
| fullnameOverride | string | `nil` | fullnameOverride completely replaces the generated name. |
| istio.egress | string | `nil` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress) for more Istio details. |
| istio.ingress.disableRewrite | bool | `false` | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` |
| istio.ingress.host | string | `nil` | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/) See [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress) for more Istio details. |
| istio.ingress.public | bool | `false` | When `false`, an internal URL will be created that will expose your application *via OpenVPN-only*. When `true`, an additional publicly accessible URL will be created. This API should be secured behind some authentication method when set to `true`. |
| istio.ingress.redirects | list | `[]` | Optional paths that will always redirect to internal/VPN endpoints |
| livenessProbe | map | `{}` | Indicates whether container is running. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes) |
| minAvailable | int | `1` | Minimum number of pods that should be available after an eviction See [Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) |
| nameOverride | string | `nil` | nameOverride replaces the name of the chart in the Chart.yaml file |
| nodeSelector | map | `{}` | Node labels for pod assignment [NodeSelector](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/nodeselector) |
| readinessProbe | map | `{}` | Indicates whether container is ready for requests. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes) |
| revision | string | `nil` | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision` that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | map | `{}` | User defined secret variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| securityContext.allowPrivilegeEscalation | bool | `false` | Setting it to false ensures that no child process of a container can gain more privileges than its parent |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.readOnlyRootFilesystem | bool | `false` | Requires that containers must run with a read-only root filesystem (i.e. no writable layer) |
| securityContext.runAsNonRoot | bool | `true` | Runs as non root. Must use numeric User in container |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application. If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). [RoleArn](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn) |
| serviceMonitor.enabled | bool | `false` | Service Monitor Enabled |
| serviceMonitor.interval | string | `"10s"` | Query Interval |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Scrape Timeout |
| serviceMonitor.selector | map | `{}` | Any label selector |
| serviceMonitor.targetPort | int | `9090` | Service Monitor Target Port |
| tags | map | `{}` | Deployment tags |
| tolerations | list | `[]` | Tolerations for pod assignment [Tolerations](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/tolerations) |
| usxpressCACertBundle.certMountPath | string | `"/etc/ssl/certs/"` | The cert is mounted to the default path mentioned. The path can also be changed. |
| usxpressCACertBundle.enabled | bool | `true` | If set to true, volume mounts the certificate from the custom-ca-certs secret |
