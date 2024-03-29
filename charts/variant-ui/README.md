# Variant UI Helm Chart

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
