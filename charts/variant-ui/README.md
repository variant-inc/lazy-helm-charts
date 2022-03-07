# Variant UI Helm Chart

![Version: 1.0.4](https://img.shields.io/badge/Version-1.0.4-informational?style=flat-square)

A Helm chart for a web UI configuration

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `nil` | fullnameOverride completely replaces the generated name. |
| istio.egress | string | `nil` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed.  [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](#egress-configuration) for more details. |
| istio.enabled | bool | `false` | Enabled  |
| istio.ingress.backend.service.name | string | `"test"` | (string) Service Name |
| istio.ingress.backend.service.port | int | `1234` | (int) port should be number |
| istio.ingress.hosts | list | `[]` | (string) The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the  [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/) |
| istio.ingress.redirects | list | `[{"prefix":"/hidden"}]` | Optional paths that will always redirect to internal/VPN endpoints |
| nameOverride | string | `nil` | nameOverride replaces the name of the chart in the Chart.yaml file |
| serviceMonitor.enabled | bool | `false` | Service Monitor Enabled |
| serviceMonitor.interval | string | `"10s"` | Query Interval |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Scrape Timeout |
| serviceMonitor.selector | object | `{}` | (map) Any label selector |
| serviceMonitor.targetPort | int | `9090` | Service Monitor Target Port |

## Install

To install the chart,
first add the repo

`helm repo add variant-inc-helm-charts https://variant-inc.github.io/lazy-helm-charts/ --password <token>`

and then install the chart using

`helm upgrade --install devops-services variant-inc-helm-charts/variant-ui -n sample-ns -f values.yaml`

## Considerations

### Custom Hosts

When using custom hosts, ie

```yaml
istio:
  enabled: true
  ingress:
    # hosts:
      - url: "internal.apps.drive-variant.com" ##Included
      - url: "awesomeapp.drive-variant.com" ##Custom
```

the host must be setup us a SAN on the certificate of the cluster. Please create a [support request](http://cloudops.ops-drivevariant.com/support) to include your host name in our clusters' certificate.
