# Variant CronJob Helm Chart

Use this chart to deploy a CronJob image to Kubernetes -- the Variant, CloudOps-approved way.

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

A Helm chart for Istio Objects

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| CLUSTER_NAME | string | `"variant-dev"` |  |
| affinity | object | `{}` |  |
| awsSecrets | list | `[]` |  |
| configVars | list | `[]` |  |
| cronJob.args | list | `[]` |  |
| cronJob.command | list | `[]` |  |
| cronJob.image.pullPolicy | string | `"Always"` |  |
| cronJob.image.tag | string | `nil` |  |
| cronJob.podAnnotations | object | `{}` |  |
| cronJob.resources.limits.cpu | int | `1` |  |
| cronJob.resources.limits.memory | string | `"768Mi"` |  |
| cronJob.resources.requests.cpu | float | `0.1` |  |
| cronJob.resources.requests.memory | string | `"384Mi"` |  |
| cronJob.schedule | string | `nil` |  |
| imagePullSecrets | list | `[]` |  |
| instanceType | string | `nil` |  |
| istio.egress | list | `[]` |  |
| nodeScaleDownTime | int | `30` |  |
| nodeSelector | object | `{}` |  |
| podSecurityContext.fsGroup | int | `65534` |  |
| revision | string | `nil` |  |
| secretVars | list | `[]` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `1000` |  |
| serviceAccount.roleArn | string | `nil` |  |
| tolerations | list | `[]` |  |

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

resource "helm_release" "test_cron_release" {
  repository        = "https://variant-inc.github.io/lazy-helm-charts/"
  chart             = "variant-cron"
  version           = "2.0.0"
  name              = "test-my-cronjob"
  namespace         = kubernetes_namespace.test_namespace.metadata[0].name
  lint              = true
  dependency_update = true

    values = [<<EOF
revision: abc123

cronJob:
  schedule: "* * * * *"
  image:
    tag: ecr.amazonaws.com/my-project/my-job:abc123
  command:
    - "/bin/sh"
    - "-c"
    - "echo do something"

EOF
  ]
}
```

## Before you start

1. Use a CloudOps Github CI workflow that publishes an image
   - [.NET](https://github.com/variant-inc/actions-dotnet)
   - [Node](https://github.com/variant-inc/actions-nodejs)
   - [Python](https://github.com/variant-inc/actions-python)

## Minimum Required Inputs

1. revision
2. cronJob.image.tag
3. cronJob.schedule

### Release name

- Provide the `name` [argument](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#name) argument in the `helm_release` resource
- This will be used as the base [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart

### Egress Configuration

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description | Required | Default Value |
| - | - | - | - | - |
| istio.egress | ServiceEntry | A whitelist of external services that your CronJob requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. | [ ] | [] |
| istio.egress[N].name | ServiceEntry | A name for this whitelist entry | [x] | |
| istio.egress[N].hosts | ServiceEntry | A list of hostnames to be whitelisted  | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].addresses | ServiceEntry | A list of IP addresses to be whitelisted | One or both istio.egress[N].hosts and istio.egress[N].addresses must be specified | [] |
| istio.egress[N].ports | ServiceEntry | A list of ports for the corresponding `istio.egress[N].hosts` or `istio.egress[N].addresses` to be whitelisted | [x] | [] |
| istio.egress[N].ports[M].number | ServiceEntry | A port number | [x] | |
| istio.egress[N].ports[M].protocol | ServiceEntry | Any of the protocols listed [here](https://istio.io/latest/docs/reference/config/networking/gateway/#Port) | [x] | |

### Infrastructure Permissions

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description |
| - | - | - |
| serviceAccount.roleArn | ServiceAccount | ARN of the IAM role to be assumed by your application. If your CronJob requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your CronJob needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). |

## Kubernetes Object Reference

All possible objects created by this chart:

- [CronJob](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/cron-job-v1/)
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [Secret](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/secret-v1/)
- [ConfigMap](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/config-map-v1/)
