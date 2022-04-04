# Variant UI Helm Chart

![Version: 1.4.0-beta](https://img.shields.io/badge/Version-1.4.0--beta-informational?style=flat-square)

A Helm chart for a web UI configuration

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | (map) Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| autoscaling.maxReplicas | int | `5` | (int) Maximum Number of Replicas. |
| autoscaling.minReplicas | int | `1` | (int) Minimum Number of Replicas. |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | (int) CPU Utilization Percentage. |
| autoscaling.targetMemoryUtilizationPercentage | int | `nil` | Memory Utilization Percentage. |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text.  Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [secrets](#secrets) for more details. |
| configVars | object | `{}` | (map) User defined environment variables are implemented here. |
| deployment.args | list | `[]` | (list) List of arguments that can be passed in the image. |
| deployment.conditionalEnvVars | list | `[]` | (list) List of Conditional Env Vars denoted by conditional (bool) and envVars (list) |
| deployment.image.pullPolicy | string | `"IfNotPresent"` | (string) IfNotPresent, Always, Never |
| deployment.image.tag | string | `nil` | The full URL of the image to be deployed containing the UI web application |
| deployment.podAnnotations | object | `{}` | (map) https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deployment.resources.limits.cpu | int | `1` | (int) Limits CPU |
| deployment.resources.limits.memory | string | `"768Mi"` | (string) Limits Memory |
| deployment.resources.requests.cpu | float | `0.1` | (float) Requests CPU |
| deployment.resources.requests.memory | string | `"384Mi"` | (string) Request memory |
| fullnameOverride | string | `nil` | fullnameOverride completely replaces the generated name. |
| istio.egress | string | `nil` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed.  [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](#egress-configuration) for more details. |
| istio.ingress.disableRewrite | bool | `false` | When `true`, the path `/{target-namespace}/{helm-release-name}` will be preserved in requests to your application, else rewritten to `/` when `false` |
| istio.ingress.host | string | `nil` | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the  [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/) |
| istio.ingress.public | bool | `false` | When `false`, an internal URL will be created that will expose your application *via OpenVPN-only*. When `true`, an additional publicly accesible URL will be created.  This API should be secured behind some authentication method when set to `true`. |
| istio.ingress.redirects | list | `[]` | Optional paths that will always redirect to internal/VPN endpoints |
| livenessProbe | string | `nil` | See [Probe](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Probe) docs |
| nameOverride | string | `nil` | nameOverride replaces the name of the chart in the Chart.yaml file |
| nodeSelector | object | `{}` | (map) Node labels for pod assignment |
| readinessProbe | string | `nil` | See [Probe](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Probe) docs |
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
| serviceMonitor.enabled | bool | `false` | Service Monitor Enabled |
| serviceMonitor.interval | string | `"10s"` | Query Interval |
| serviceMonitor.scrapeTimeout | string | `"10s"` | Scrape Timeout |
| serviceMonitor.selector | object | `{}` | (map) Any label selector |
| serviceMonitor.targetPort | int | `9090` | Service Monitor Target Port |
| tolerations | list | `[]` | (list) Tolerations for pod assignment |

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
