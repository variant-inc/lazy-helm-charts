# Variant CronJob Helm Chart

Use this chart to deploy a CronJob image to Kubernetes -- the Variant, CloudOps-approved way.

![Version: 1.2.5](https://img.shields.io/badge/Version-1.2.5-informational?style=flat-square)

A Helm chart for Istio Objects

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| CLUSTER_NAME | string | `"variant-dev"` | For securityGroupSelector in provisioner.yaml |
| affinity | object | `{}` | Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| awsSecrets | list | `[]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text.  Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [secrets](#secrets) for more details. |
| configVars | object | `{}` | (map) User defined environment variables are implemented here. |
| cronJob.command | list | `nil` | full path to the job script to execute. https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/ |
| cronJob.image.pullPolicy | string | `"Always"` | (string) IfNotPresent, Always, Never |
| cronJob.image.tag | string | `nil` | The full URL of the image to be deployed containing the HTTP API application |
| cronJob.podAnnotations | object | `{}` | (map) https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| cronJob.resources.limits.cpu | int | `1` | (int) Limits CPU |
| cronJob.resources.limits.memory | string | `"768Mi"` | (string) Limits Memory |
| cronJob.resources.requests.cpu | float | `0.1` | (float) Requests CPU |
| cronJob.resources.requests.memory | string | `"384Mi"` | (string) Request memory |
| cronJob.schedule | string | `nil` | Cron Style Schedule. For help check https://crontab.guru/ |
| cronJob.suspend | bool | `false` | (bool) https://kubernetes.io/blog/2021/04/12/introducing-suspended-jobs/ |
| imagePullSecrets | list | `[]` | (list) https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod |
| istio.egress | list | `[]` | A whitelist of external services that your API requires connection to. The whitelist applies to the entire namespace in which this chart is installed.  [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](#egress-configuration) for more details. |
| node.create | bool | `false` | Flag to determine whether or not custom nodes will be provisioned. |
| node.instanceType | string | `"r5.xlarge"` | The EC2 Instance Type for your custom nodes. |
| node.ttlSecondsAfterEmpty | int | `3600` | Number of seconds before custom nodes will be removed if nothing is running on them. |
| node.ttlSecondsUntilExpired | string | `nil` | If nil, the feature is disabled, nodes will never expire |
| nodeSelector | object | `{}` | Node labels for pod assignment ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| podSecurityContext.fsGroup | int | `65534` | Groups of nobody |
| restartPolicy | string | `"Never"` | Use Never by default for jobs so new pod is created on failure instead of restarting containers |
| revision | string | `nil` | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision`  that will be applied to all objects created by a specific chart installation.  Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| secretVars | object | `{}` | (map) User defined secret variables are implemented here. |
| securityContext.allowPrivilegeEscalation | bool | `false` | (bool) Setting it to false ensures that no child process of a container can gain more privileges than its parent |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.readOnlyRootFilesystem | bool | `false` | (bool) Requires that containers must run with a read-only root filesystem (i.e. no writable layer) |
| securityContext.runAsNonRoot | bool | `true` | Runs as non root. Must use numeric User in container |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| serviceAccount.roleArn | string | `nil` | Optional ARN of the IAM role to be assumed by your application.  If your API requires access to any AWS services, a role should be created in AWS IAM. This role should have an inline policy that describes the permissions your API needs (connect to RDS, publish to an SNS topic, read from an SQS queue, etc.). |
| tags | string | `nil` | Tags to be applied to custom node provisioner |
| tolerations | list | `[]` | Tolerations for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |

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

### Custom Node Configuration

To create custom nodes for your Cron Job add the following configurations to your values.yaml
```yaml
node:
  # Set to true to create custom nodes. Default is false
  create: true
  # EC2 Instance type for your cusom node. Default is r5.xlarge
  instanceType: r5.xlarge
  # If nil, the feature is disabled, nodes will never expire
  ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
  # If nil, the feature is disabled, nodes will never scale down due to low utilization. Default 30 minutes
  ttlSecondsAfterEmpty: 1800
```

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
