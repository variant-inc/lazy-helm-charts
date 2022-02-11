# Testing

## Prerequisites

- Install [Helm](https://helm.sh/docs/intro/install/)
- Install [plugin](https://github.com/quintush/helm-unittest#install) for Helm
- Install [chart-testing](https://github.com/helm/chart-testing#installation)
- Configure `kubectl` for the `devops-playground` cluster

## Concepts

- Values in `values.yaml` next to `Chart.yaml` in the chart directory are meant to be defaults, not examples
- Defaults are overriden, so if something is required for every installation, build it into the chart instead of `values.yaml`
- Values required by the chart user should be omitted from or null (empty) in `values.yaml` and be set appropriately in unit and integration tests

## Unit Tests

`helm unittest -3 --strict -f ci/unit/*.yaml ./charts/*`

- Live in `./charts/{chart}/ci/unit`; [example](./charts/variant-api/ci/unit/defaults.yaml)
- [Testing YAML specification](https://github.com/quintush/helm-unittest/blob/master/DOCUMENT.md#testing-document)

## Integration tests

`ct install --charts ./charts/{chart} --namespace lazy-helm-charts`

Deployed via [Octopus](https://octopus.apps.ops-drivevariant.com/app#/Spaces-2/projects/lazy-helm-charts/deployments)

- Live in `./charts/{chart}/ci`
- Must be named `*-values.yaml`; [example](./charts/variant-api/ci/default-values.yaml)
- Each `*-values.yaml` runs through multiple helm steps:
  1. The chart is installed/upgraded using the values
  1. [Helm hook tests](https://helm.sh/docs/helm/helm_test/)
  1. The release is destroyed
