# Variant API Helm Chart

Use this chart to deploy an API image to Kubernetes -- the Variant, CloudOps-approved way.

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
    - Documentation with some instructions on how to implement a metrics endpoint can be found [here](https://drivevariant.atlassian.net/wiki/spaces/SRE/pages/2353594376/Service+Metrics+Endpoint)

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

### Ingress Configuration

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Default Value |
| - | - | - | - |
| istio.ingress.public | VirtualService | When `false`, an internal URL will be created that will expose your application *via OpenVPN-only*. When `true`, an additional publicly accesible URL will be created. This API should be secured behind some authentication method when set to `true`. | `false` |
| istio.ingress.disableRewrite | VirtualService | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` | `false` |
| service.port | VirtualService, Service | | 80 |

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
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceMonitor](https://docs.openshift.com/container-platform/4.8/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService)
