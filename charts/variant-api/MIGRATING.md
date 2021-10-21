# Migrating to variant-api 2.0

## Definitions

- **chart source** directory - Typically in `{project_root}/helm/{project_name}`. Source code of the helm chart that you are currently deploying.
- **chart alias** - Typically `vsd`. In `{chart source}/Chart.yaml`, the value for the field `alias` under `dependencies` for `variant-api`.
- **`helm_release`** resource - Typically in `{project_root}/terraform/{project_name}/release.tf` or `{project_root}/terraform/{project_name}/helm.tf`. Terraform resource used to deploy your helm chart where you provide `set` values.

## Migration steps

1. In `{chart source}/Chart.yaml`, in `dependencices:` Update `version` to `2.0.0` for the `variant-api` chart
1. In `helm_release`, **remove** all `set` blocks with any of the following names:
   - `fullnameOverride` -> the attribute `name` which should be set as `{your project}-api` will be used for all naming so this is now deprecated
   - `replicaCount` -> See [Autoscaling](#autoscaling); autoscaling min/max replicas should be configured instead of deployment replicaCount
   - `serviceAccount.name` -> See [Serivice Account](#service-account); see note on `fullnameOverride`
   - `autoscaling.enabled` -> See [Autoscaling](#autoscaling); API autoscaling is not optional
   - `global.service.name` -> see note on `fullnameOverride`
1. In `helm_release`, **revise** all `set` blocks with any of the following names:
   - `image.url` or `image.tag` -> `{chart alias}.deployment.image.tag`
1. Set your required [Environment Variables](#environment-variables)
1. Provide any [Startup Arguments](#startup-arguments)
1. Set the correct [Ports](#ports)
1. [Secrets](#secrets)
1. Remove all of the following resources (`kind`) being created in `{chart source}/templates`
   - HorizontalPodAutoscaler (typically in `hpa.yaml`)
   - Deployment (typically in `deployment.yaml`)
   - ServiceAccount (typically in `service-account.yaml`)
   - Service (typically in `service.yaml`)
1. Clear the contents of `{chart source}/values.yaml` (unless some values are used for custom resource deployments outside of this chart)

### Service Account

- The chart creates and names the service account for your API
- Remove any terraform which creates the resource `kubernetes_service_account`
- If your service account has an AWS role annotation, provide it by creating a `set` block where `name` is `{chart alias}.serviceAccount.roleArn`

Example

```bash
  set {
    name  = "{chart alias}.serviceAccount.roleArn"
    value = aws_iam_role.role.arn
  }
```

### Autoscaling

Autoscaling is enabled by default. See the defaults in `autoscaling` section of [values.yaml](values.yaml) to override.

Example

```bash
  set {
    name  = "{chart alias}.autoscaling.minReplicas"
    value = var.autoscaling_min_replicas
  }

  set {
    name  = "{chart alias}.autoscaling.targetMemoryUtilizationPercentage"
    value = var.autoscaling_memory_target
  }
```

### Environment Variables

1. In `{chart source}/templates/deployment.yaml` collect the environment variables **names** your API requires
1. In `helm_release` determine which `set` blocks provide a `value` for the variables determined above
   - `API_BASE_PATH` and `REVISION` are automatically provided by the 2.0 chart so the `set` blocks should be removed
1. Use the example below to set your environment variables. Optionally, the rest of your `set` values can be provided in this values yaml format
1. Remove any `set` blocks from step 2 above

Example:

```bash
resource "helm_release" "test" {
  repository = "https://variant-inc.github.io/lazy-helm-charts/"
  chart      = "variant-api"
  version    = "2.0.0"
  name       = "schedule-adherence-api"
  namespace  = kubernetes_namespace.test.metadata[0].name

  values = [<<EOF
{chart alias}:
  deployment:
    envVars:
      - name: CONNECTIONSTRINGS__REDIS
        value: "${var.redis_host}:${var.redis_port}"
      - name: HERECLIENT__CACHE_DURATION_MINUTES
        value: var.here_cache_duration_minutes
      - name: EPSAGON_TOKEN
        value: ${var.epsagon_token}
      - name: EPSAGON_APP_NAME
        value: ${var.epsagon_app_name}
    conditionalEnvVars:
      - condition: ${var.condition_one}
        envVars:
        - name: false_conditional
          value: false_conditional
      - condition: ${var.condition_two}
        envVars:
        - name: true_conditional_1
          value: true_conditional_1
        - name: true_conditional_2
          value: true_conditional_2      
EOF
  ]

  /* Pre-existing `set` blocks below
    ...
  */
} 
```

### Startup Arguments

Example:

```bash
resource "helm_release" "test" {
  repository = "https://variant-inc.github.io/lazy-helm-charts/"
  chart      = "variant-api"
  version    = "2.0.0"
  name       = "schedule-adherence-api"
  namespace  = kubernetes_namespace.test.metadata[0].name

  values = [<<EOF
{chart alias}:
  deployment:
    args:
      - Variant.ScheduleAdherence.Api.dll   
EOF
  ]

  /* Pre-existing `set` blocks below
    ...
  */
} 
```

### Ports

Your API, health checks at `/health` and metrics at `/metrics` are expected to be at port 9000. Use the example below to override:

Only {chart alias}.service.targetPort is required if all on the same port.

Example:

```bash
resource "helm_release" "test" {
  repository = "https://variant-inc.github.io/lazy-helm-charts/"
  chart      = "variant-api"
  version    = "2.0.0"
  name       = "schedule-adherence-api"
  namespace  = kubernetes_namespace.test.metadata[0].name

  values = [<<EOF
{chart alias}:
  service:
    targetPort: 5000
    healthCheckPort: 5001
    metricsPort: 5002  
EOF
  ]

  /* Pre-existing `set` blocks below
    ...
  */
} 
```

### Secrets
