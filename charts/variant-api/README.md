# Variant Service Deployments Helm Chart

## Install

To install the chart,
first add the repo

`helm repo add variant-inc-helm-charts https://variant-inc.github.io/lazy-helm-charts/ --password <token>`

and then install the chart using

`helm upgrade --install devops-services variant-inc-helm-charts/variant-api -n sample-ns -f values.yaml`

## Considerations

### Standard URL Prefix

When using Istio ingress, the standard url schema {HOST}/{NAMESPACE}/{RELEASE_NAME}.
This is a departure from the previous version that did not include a specific match url prefix.
This also may be a breaking change where your application may not know to redirect requests with the prefix of the url schema. See documentation about running your app/server running behind a proxy to allow proper function of your backend.

### Public vs Private Ingress

When not using public ingress, you can only access your Service via [VPN](https://usxtech.atlassian.net/wiki/spaces/CLOUD/pages/1332445185/How+to+configure+OpenVPN+using+Okta+SSO+to+access+USX+Variant+Resources).

When using public ingess, the following URL prefixes are rerouted to the root URL and are essentially blocked. They must be accessed internally, or through VPN. You can add to this list in Values.istio.ingress.redirects.

- health
- docs
- redoc
- swagger
- swaggerui

## API Requirements

Before deploying, your API should:

- Host a health check endpoint via `GET /health` which returns a status code < 400 when healthy or >= 400 when unhealthy
- Host a Prometheus metrics endpoint via `GET /metrics`

## Object Reference

All possible objects created by this chart:

- [Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v1/)
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceMonitor]()
- [Service](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/#VirtualService)

## Inputs

Default values for all optional inputs can be seen in [values.yaml](values.yaml)

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Required | Default Value |
| - | - | - | - | - |
| fullnameOverride | All | The root [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart | [x] | |
| revision | All | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) `revision` that will be applied to all objects created by a specific chart installation | [x] | |
| istio.ingress.public | VirtualService | When `false`, an internal URL will be created with the format `api.internal.{istio.ingress.host}/{target-namespace}/{helm-release-name}` that will expose your application via OpenVPN-only. When `true`, an additional public URL will be created with the format `api.{istio.ingress.host}/{target-namespace}/{helm-release-name}` that will expose your application publicly. This API should be secured behind some authentication method when set to `true`.  | [ ] | `false` |
| istio.ingress.host | VirtualService | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/LibraryVariableSets-121?activeTab=variables) Octopus Variable Set  | [ ] | ops-drivevariant.com |
| istio.ingress.disableRewrite | VirtualService | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` | [ ] | `false` |
| istio.egress | ServiceEntry | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. | [ ] | [] |
| istio.egress[N].name | ServiceEntry | A name for this whitelist entry | [x] | |
| istio.egress[N].hosts | ServiceEntry | A list of hostnames to be whitelisted  | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].addresses | ServiceEntry | A list of IP addresses to be whitelisted | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].ports | ServiceEntry | A list of ports for the corresponding `istio.egress[N].hosts` or `istio.egress[N].addresses` to be whitelisted | [x] | [] |
| istio.egress[N].ports[M].number | ServiceEntry | A port number | [x] | |
| istio.egress[N].ports[M].protocol | ServiceEntry | Any of the protocols listed [here](https://istio.io/latest/docs/reference/config/networking/gateway/#Port) | [x] | |