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
