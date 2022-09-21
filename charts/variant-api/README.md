# Variant API Helm Chart

![Version: 2.1.20-beta](https://img.shields.io/badge/Version-2.1.20-beta-informational?style=flat-square)

A Helm chart for APIs to Variant clusters

### What this chart provides to you by default

- An API that is reachable only via [OpenVPN](https://usxtech.atlassian.net/wiki/spaces/CLOUD/pages/1332445185/How+to+configure+OpenVPN+using+Okta+SSO+to+access+USX+Variant+Resources), or by other services inside the same cluster
  - See [ingress configuration](#ingress-configuration) to make it public, and for information regarding the generated URLs
- An API that can only reach [these services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) or other services inside the same cluster, **by default**
  - See [egress configuration](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress) to whitelist services you need to reach outside of the cluster
- An API that is isolated from infrastructure access - Amazon services are firewall whitelisted by default, but you still need an AWS role if you need access to AWS services (SQS, SNS, RDS, etc.)
  - See [infrastructure permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn)

### How do I access my API?

- Via VPN at `https://api.<DOMAIN>-drivevariant.com/my-namespace/my-api/`
- To other services within the same cluster at `http://my-api.my-namespace.svc.cluster.local/`

### Port Forwarding

- Using Lens:
  - Start port forwarding
    - Network > Services
    - Click on your api in the list
    - In the details panel, click the `Forward` button next to `Ports` in the
    `Connection` section of the panel.
    - Select `Open in Browser` and click `Start`
  - Stop port forwarding
    - In the same details panel, click `Stop/Remove` next to `Ports` in the
    `Connection` section of the panel.

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
1. There is no required environment variable for your API to function

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

#### Ingress Configuration

(*how resources will access your API*)

URL Formats

- Public: `api.{istio.ingress.host}/{target-namespace}/{helm-release-name}`
- Private (OpenVPN): `api.internal.{istio.ingress.host}/{target-namespace}/{helm-release-name}`

When using public ingess, the following URL prefixes are rerouted to the root URL and are essentially blocked. They must be accessed internally, or through VPN. You can add to this list in Values.istio.ingress.redirects.

- health
- swagger
- swaggerui

#### [Infrastructure Permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn)

#### [Egress Configuration](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress)
(*how your API will access external resources*)

#### [Environment Variables](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables)

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
| affinity | map | `{}` | Affinity for pod assignment. [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) |
| authentication | bool | `{"enabled":false,"jwksUri":null,"server":null}` | selecting authentication: true when defining an api resource, [Istio RBAC](https://istio.io/v1.3/docs/reference/config/authorization/istio.rbac.v1alpha1/) resources are created  to require a valid JWT token before forwarding a request to your API. [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress/) |
| authorization | list | `{"rules":{"to":[]}}` | List of operation objects with methods and paths key values allowing certain methods and paths to be whitelisted within the cluster GET /health and Get /metrics are set by default in authorization.yaml |
| autoscaling.maxReplicas | int | `5` | Maximum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling/) |
| autoscaling.minReplicas | int | `1` | Minimum Number of Replicas. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling/) |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | CPU Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling/) |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. [Autoscaling](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/autoscaling/) |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name}. See [AWS Secrets](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables/) for more details. |
| configVars | map | `{}` | User defined environment variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables/) |
| deployment.args | list | `[]` | List of arguments that can be passed in the image. |
| deployment.conditionalEnvVars | list | `[]` | List of Conditional Env Vars denoted by conditional (bool) and envVars (list) |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | IfNotPresent, Always, Never |
| deployment.image.tag | string | `nil` | The full URL of the image to be deployed containing the HTTP API application |
| deployment.podAnnotations | map | `{}` | [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| deployment.resources.limits.cpu | int | `1` | Limits CPU |
| deployment.resources.limits.memory | string | `"768Mi"` | Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | Request memory |
| istio.egress | list | `[]` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress/) and [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress/) for more details. |
| istio.ingress.disableRewrite | bool | `false` | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` |
| istio.ingress.host | string | `nil` | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/). See [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress/) for more Istio details. |
| istio.ingress.public | bool | `false` | When `false`, an internal URL will be created that will expose your application *via OpenVPN-only*. When `true`, an additional publicly accessible URL will be created. This API should be secured behind some authentication method when set to `true`. See [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress/) for more Istio details. |
| istio.ingress.redirects | list | `[]` | Optional paths that will always redirect to internal/VPN endpoints |
| livenessProbe | map | `{}` | Indicates whether container is running. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes/) |
| minAvailable | int | `1` | Minimum number of pods that should be available after an eviction See [Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) |
| nodeSelector | map | `{}` | Node labels for pod assignment. [NodeSelector](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/nodeselector/) |
| readinessProbe | map | `{}` | Indicates whether container is ready for requests. See [Probe](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/probes/) |
| revision | string | `nil` | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision` that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | map | `{}` | User defined secret variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables/) |
| securityContext.allowPrivilegeEscalation | bool | `false` | Setting it to false ensures that no child process of a container can gain more privileges than its parent |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.readOnlyRootFilesystem | bool | `false` | Requires that containers must run with a read-only root filesystem (i.e. no writable layer) |
| securityContext.runAsNonRoot | bool | `true` | Runs as non root. Must use numeric User in container |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application. If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). [RoleArn](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn/) |
| serviceMonitor.interval | string | `"10s"` | Frequency at which Prometheus metrics will be collected from your service |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Maximum wait duration for Prometheus metrics response from your service |
| tags | map | `{}` | Deployment tags |
| tolerations | list | `[]` | Tolerations for pod assignment. [Tolerations](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/tolerations/) |
