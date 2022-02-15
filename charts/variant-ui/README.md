# Variant UI Helm Chart

![Version: 1.0.3](https://img.shields.io/badge/Version-1.0.3-informational?style=flat-square)

A Helm chart for a web UI configuration

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `nil` |  |
| istio.egress | string | `nil` |  |
| istio.enabled | bool | `false` |  |
| istio.ingress.backend.service.name | string | `"test"` |  |
| istio.ingress.backend.service.port | int | `1234` |  |
| istio.ingress.hosts | list | `[]` |  |
| istio.ingress.redirects[0].prefix | string | `"/hidden"` |  |
| nameOverride | string | `nil` |  |
| serviceMonitor.enabled | bool | `false` |  |
| serviceMonitor.interval | string | `"10s"` |  |
| serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| serviceMonitor.selector | object | `{}` |  |
| serviceMonitor.targetPort | int | `9090` |  |

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
