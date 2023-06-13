# Variant CronJob Helm Chart

![Version: 1.2.26](https://img.shields.io/badge/Version-1.2.26-informational?style=flat-square) A Helm chart for Istio Objects

## What this chart provides to you by default

- A CronJob image deployed to Kubernetes -- the Variant, CloudOps-approved way.

## Before you start

### Prerequisites

1. Use a CloudOps Github CI workflow that publishes an image
   - [.NET](https://github.com/variant-inc/actions-dotnet)
   - [Node](https://github.com/variant-inc/actions-nodejs)
   - [Python](https://github.com/variant-inc/actions-python)
2. Make sure curl utility is available in the image as it is used to check the status of the sidecar container. If not available, Based on the image you use add below commands in the Dockerfile.
   - Ubuntu / Debian OS

     ```bash
     RUN apt-get install curl
     ```

   - RHEL / CentOS / Fedora OS

     ```bash
     RUN yum install curl
     ```

   - Alpine OS

     ```bash
     RUN apk --no-cache add curl
     ```

***

### *OPTIONAL* Configuration Inputs

#### Custom Node Configuration

- To create custom nodes for your Cron Job add the following configurations to your values.yaml

```yaml
  node:
    # Set to true to create custom nodes. Default is false
    create: true
    # EC2 Instance type for your custom node if you want to specify it.
    instanceType: r6a.xlarge
    # If nil, the feature is disabled, nodes will never expire
    ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
    # If nil, the feature is disabled, nodes will never scale down due to low utilization. Default 30 minutes
    ttlSecondsAfterEmpty: 1800
```

#### [Infrastructure Permissions](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/rolearn/)

#### [Egress Configuration](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress/)

(*how your Cron Job will access external resources*)

#### [Environment Variables](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables/)

## Kubernetes Object Reference

All possible objects created by this chart:

- [CronJob](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/cron-job-v1/)
- [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [Secret](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/secret-v1/)
- [ConfigMap](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/config-map-v1/)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| awsSecrets | list | Example: `[{ "name": "eng-secret-in-aws", "type": "" }]` | A list of secrets to configure to make available to your API. Create your secret in AWS Secrets Manager as plain text. Full contents of this secret will be mounted as a file your application can read to /app/secrets/{name} See [AWS Secrets](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) for more details. |
| configVars | map | Example: `bar: foo` | User defined environment variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| cronJob.command | list | `nil` | full path to the job script to execute. https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/ |
| cronJob.concurrencyPolicy | string | `"Replace"` | https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#concurrency-policy |
| cronJob.image.pullPolicy | string | `"IfNotPresent"` | IfNotPresent, Always, Never |
| cronJob.image.tag | string | `nil` | The full URL of the image to be deployed containing the HTTP API application |
| cronJob.podAnnotations | map | `{}` | https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| cronJob.resources.limits.cpu | int | `nil` | Limits CPU, intentionally set to null, can't be overridden |
| cronJob.resources.limits.memory | string | `"768Mi"` | Limits Memory |
| cronJob.resources.requests.cpu | float | `0.1` | Requests CPU |
| cronJob.resources.requests.memory | string | `"384Mi"` | Request memory |
| cronJob.schedule | string | `nil` | Cron Style Schedule. For help check https://crontab.guru/ |
| cronJob.suspend | bool | `false` | https://kubernetes.io/blog/2021/04/12/introducing-suspended-jobs/ |
| istio.egress | list | `[]` | A whitelist of external services that your application requires connection to. The whitelist applies to the entire namespace in which this chart is installed. [These services](https://github.com/variant-inc/iaac-eks/blob/master/scripts/istio/service-entries.eps#L8) are globally whitelisted and do not require declaration. See [egress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/egress). See [Ingress](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/ingress) for more Istio details. |
| node.create | bool | `false` | Flag to determine whether or not custom nodes will be provisioned. |
| node.instanceType | string | `nil` | The EC2 Instance Type for your custom nodes. |
| node.ttlSecondsAfterEmpty | int | `3600` | Number of seconds before custom nodes will be removed if nothing is running on them. |
| node.ttlSecondsUntilExpired | string | `nil` | If nil, the feature is disabled, nodes will never expire |
| podSecurityContext | map | `{"fsGroup":65534}` | Security Context for pods |
| podSecurityContext.fsGroup | int | `65534` | The files created in the container will be created with this gid `65534` is a `nobody` group |
| restartPolicy | string | `"Never"` | Use Never by default for jobs so new pod is created on failure instead of restarting containers |
| secretVars | map | Example: `foo: bar` | User defined secret variables are implemented here. [More Information](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Apps/Common/environment_variables) |
| securityContext | map | `{"capabilities":{"drop":["ALL"]},"runAsGroup":null,"runAsUser":null}` | Security Context for containers |
| securityContext.capabilities | object | `{"drop":["ALL"]}` | Drop All capabilities |
| securityContext.runAsGroup | int | `nil` | Runs as numeric user |
| securityContext.runAsUser | int | `nil` | Runs as numeric user |
| usxpressCACertBundle.certMountPath | string | `"/etc/ssl/certs/"` | The cert is mounted to the default path mentioned. The path can also be changed. |
| usxpressCACertBundle.enabled | bool | `true` | If set to true, volume mounts the certificate from the custom-ca-certs secret |
