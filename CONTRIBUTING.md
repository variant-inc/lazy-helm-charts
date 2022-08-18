# Contributing Guidelines

Contributions are welcome via GitHub pull requests. This document outlines the process to help get your contribution accepted.

## How to Contribute

1. Create a branch and make your changes
1. Submit a pull request

***NOTE***: In order to make testing and merging of PRs easier, please submit changes to multiple charts in separate PRs.

### Technical Requirements

* Must follow [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/)
* Must pass CI jobs for linting and installing changed charts with the [chart-testing](https://github.com/helm/chart-testing) tool
* Any change to a chart requires a version bump following [semver](https://semver.org/) principles. See [Immutability](#immutability) and [Versioning](#versioning) below

Once changes have been merged, the release job will automatically run to package and release changed charts.

### Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version bump even if it is only changed to the documentation.

### Versioning

The chart `version` should follow [semver](https://semver.org/).

Charts should start at `1.0.0`. Any breaking (backwards incompatible) changes to a chart should:

1. Bump the MAJOR version
2. In the README, under a section called "Upgrading", describe the manual steps necessary to upgrade to the new (specified) MAJOR version

### Software Dependencies

* [Pre-Commit dependencies](https://github.com/antonbabenko/pre-commit-terraform)
  * Installation for MacOS:

  ```bash
    brew install pre-commit terraform-docs tflint tfsec checkov terrascan infracost tfupdate jq
    pre-commit autoupdate
  ```

***

## Minimum Required Inputs for Charts

### variant-api

* Release name
  <!-- markdownlint-disable-next-line MD013 -->
  * Provide the `name` [argument](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#name) argument in the `helm_release` resource
  <!-- markdownlint-disable-next-line MD013 -->
  * According to the [Workload Naming Conventions](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/1665859671/Recommended+Conventions#Workload-Naming-Conventions), this name must end with `-api` such as `schedule-adherence-api` or `driver-api`
  <!-- markdownlint-disable-next-line MD013 -->
  * This will be used as the base [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart

* Minimum required input table

| Input |
| - |
| revision |
| istio.ingress.host |
| deployment.image.tag |

* The minimum required inputs to get deployed using Terraform:

```bash
    resource "kubernetes_namespace" "test_namespace" {
    metadata {
        name = "my-namespace"
        labels = {
        "istio-injection" : "enabled"
        }
    }
    }

    resource "helm_release" "test_api_release" {
    repository        = "https://variant-inc.github.io/lazy-helm-charts/"
    chart             = "variant-api"
    version           = "2.0.0"
    name              = "test-my-api"
    namespace         = kubernetes_namespace.test_namespace.metadata[0].name
    lint              = true
    dependency_update = true

        values = [<<EOF
    revision: abc123

    istio:
    ingress:
        host: dev-drivevariant.com

    deployment:
    image:
        tag: ecr.amazonaws.com/my-project/my-api:abc123

    EOF
    ]
    }
```

***

### variant-cron

* Release name
  <!-- markdownlint-disable-next-line MD013 -->
  * Provide the `name` [argument](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#name) argument in the `helm_release` resource
  <!-- markdownlint-disable-next-line MD013 -->
  * This will be used as the base [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart

* Minimum required input table

| Input |
| - |
| revision |
| cronJob.image.tag |
| cronJob.schedule |

* The minimum required inputs to get deployed using Terraform:

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

***

### variant-handler

* Release name
  <!-- markdownlint-disable-next-line MD013 -->
  * Provide the `name` [argument](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#name) argument in the `helm_release` resource
  <!-- markdownlint-disable-next-line MD013 -->
  * According to the [Workload Naming Conventions](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/1665859671/Recommended+Conventions#Workload-Naming-Conventions), this name must end with `-handler` such as `schedule-adherence-handler` or `driver-handler`
  * This will be used as the base [object name](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) that will be assigned to all Kubernetes objects created by this chart

* Minimum required input table

| Input | [Kubernetes Object Type](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) | Description |
| - | - | - |
| revision | All | Value for a [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) named `revision` that will be applied to all objects created by a specific chart installation. Strongly encouraged that this value corresponds to 1 of: Octopus package version, short-SHA of the commit, Octopus release version |
| istio.ingress.host | VirtualService | The base domain that will be used to construct URLs that point to your API. This should almost always be the Octopus Variable named `DOMAIN` in the [AWS Access Keys](https://octopus.apps.ops-drivevariant.com/app#/Spaces-22/library/variables/LibraryVariableSets-121?activeTab=variables) Octopus Variable Set  |
| deployment.image.tag | Deployment | The full URL of the image to be deployed containing the HTTP API application |

* The minimum required inputs to get deployed using Terraform:

```bash
    resource "kubernetes_namespace" "test_namespace" {
    metadata {
        name = "my-namespace"
        labels = {
        "istio-injection" : "enabled"
        }
    }
    }

    resource "helm_release" "test_api_release" {
    repository        = "https://variant-inc.github.io/lazy-helm-charts/"
    chart             = "variant-handler"
    version           = "2.0.0"
    name              = "test-my-handler"
    namespace         = kubernetes_namespace.test_namespace.metadata[0].name
    lint              = true
    dependency_update = true

        values = [<<EOF

    deployment:
    image:
        tag: ecr.amazonaws.com/my-project/my-api:abc123

    EOF
    ]
    }
```
