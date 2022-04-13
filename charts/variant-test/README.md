# Variant API Helm Chart

![Version: 2.1.5](https://img.shields.io/badge/Version-2.1.5-informational?style=flat-square)

A Helm chart for APIs to Variant clusters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | (map) Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| authentication | object | `{"enabled":false}` | (bool) selecting authentication: true when defining an api resource, Istio RBAC resources are created to require a valid JWT token before forwarding a request to your API. |
| authorization | object | `{"rules":{"to":[]}}` | (list) List of operation objects with methods and paths key values allowing certain methods and paths to be whitelisted within the cluster GET /health and Get /metrics are set by default in authorization.yaml |
| autoscaling.maxReplicas | int | `5` | (int) Maximum Number of Replicas. |
| autoscaling.minReplicas | int | `1` | (int) Minimum Number of Replicas. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | (int) CPU Utilization Percentage. |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text.  Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [secrets](#secrets) for more details. |
| configVars | object | `{}` | (map) User defined environment variables are implemented here. |
| deployment.args | list | `[]` | (list) List of arguments that can be passed in the image. |
| deployment.conditionalEnvVars | list | `[]` | (list) List of Conditional Env Vars denoted by conditional (bool) and envVars (list) |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | (string) IfNotPresent, Always, Never |
| deployment.image.tag | string | `nil` | The full URL of the image to be deployed containing the HTTP API application |
| deployment.podAnnotations | object | `{}` | (map) https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deployment.resources.limits.cpu | int | `1` | (int) Limits CPU |
| deployment.resources.limits.memory | string | `"768Mi"` | (string) Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | (float) Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | (string) Request memory |
| istio.egress | list | `[]` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed.  [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](#egress-configuration) for more details. |
| istio.ingress.disableRewrite | bool | `false` | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` |
| istio.ingress.host | string | `nil` | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the  [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/) |
| istio.ingress.public | bool | `false` | When `false`, an internal URL will be created that will expose your application *via OpenVPN-only*. When `true`, an additional publicly accesible URL will be created.  This API should be secured behind some authentication method when set to `true`. |
| istio.ingress.redirects | list | `[]` | Optional paths that will always redirect to internal/VPN endpoints |
| nodeSelector | object | `{}` | (map) Node labels for pod assignment |
| revision | string | `nil` | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision`  that will be applied to all objects created by a specific chart installation.  Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | object | `{}` | (map) User defined secret variables are implemented here. |
| securityContext.allowPrivilegeEscalation | bool | `false` | (bool) Setting it to false ensures that no child process of a container can gain more privileges than its parent |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.readOnlyRootFilesystem | bool | `false` | (bool) Requires that containers must run with a read-only root filesystem (i.e. no writable layer) |
| securityContext.runAsNonRoot | bool | `true` | Runs as non root. Must use numeric User in container |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| service.healthCheckPort | string | `nil` | Optional port which serves a health check endpoint at `/health` Defaults to value of `service.targetPort` if not defined. |
| service.metricsPort | string | `nil` | Optional port which serves prometheus metrics endpoint at `/metrics` Defaults to value of `service.targetPort` if not defined. |
| service.port | int | `80` | Port for internal services to access your API |
| service.targetPort | int | `9000` | Port on your container that exposes your HTTP API |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application.  If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). |
| serviceMonitor.interval | string | `"10s"` | Frequency at which Prometheus metrics will be collected from your service |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Maximum wait duration for Prometheus metrics response from your service |
| tolerations | list | `[]` | (list) Tolerations for pod assignment |

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
  chart             = "variant-api"
  version           = "2.0.0"
  name              = "test-my-api"
  namespace         = kubernetes_namespace.test_namespace.metadata[0].name
  lint              = true
  dependency_update = true

    values = [<<EOF
revision: abc123

istio:
  ingress:
    host: dev-drivevariant.com

deployment:
  image:
    tag: ecr.amazonaws.com/my-project/my-api:abc123

EOF
  ]
}
```

### What does it do by default

- Your API will be available on VPN at `https://api.internal.dev-drivevariant.com/my-namespace/my-api/`
- Your API will be available to other services in the cluster at `http://my-api.my-namespace.svc.cluster.local/`
- Private - the API is reachable only via [OpenVPN](https://usxtech.atlassian.net/wiki/spaces/CLOUD/pages/1332445185/How+to+configure+OpenVPN+using+Okta+SSO+to+access+USX+Variant+Resources), or by other services inside the same cluster
  - See [ingress confguration](#ingress-configuration) to make it public, and for information regarding the generated URLs
- Firewall - the API can only reach [these services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) or other services inside the same cluster by default
  - See [egress configuration](#egress-configuration) to whitelist services you need to reach outside of the cluster
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

| Input |
| - |
| revision |
| istio.ingress.host |
| deployment.image.tag |

## Optional Inputs

### Ingress Configuration

URL Formats

- Public: `api.{istio.ingress.host}/{target-namespace}/{helm-release-name}`
- Private (OpenVPN): `api.internal.{istio.ingress.host}/{target-namespace}/{helm-release-name}`

When using public ingess, the following URL prefixes are rerouted to the root URL and are essentially blocked. They must be accessed internally, or through VPN. You can add to this list in Values.istio.ingress.redirects.

- health
- docs
- redoc
- swagger
- swaggerui

### Egress Configuration

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Required | Default Value |
| - | - | - | - | - |
| istio.egress | ServiceEntry | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. | [ ] | [] |
| istio.egress[N].name | ServiceEntry | A name for this whitelist entry | [x] | |
| istio.egress[N].hosts | ServiceEntry | A list of hostnames to be whitelisted  | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].addresses | ServiceEntry | A list of IP addresses to be whitelisted | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].ports | ServiceEntry | A list of ports for the corresponding `istio.egress[N].hosts` or `istio.egress[N].addresses` to be whitelisted | [x] | [] |
| istio.egress[N].ports[M].number | ServiceEntry | A port number | [x] | |
| istio.egress[N].ports[M].protocol | ServiceEntry | Any of the protocols listed [here](https://istio.io/latest/docs/reference/config/networking/gateway/#Port) | [x] | |

### Secrets

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Default Value |
| - | - | - | - |
| secrets | ExternalSecret | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read. | [] |
| secrets[N].name | ExternalSecret | Name of the AWS Secrets Manager secret |

## Kubernetes Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService)