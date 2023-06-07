param (
    [String] $PackagePath
)

aws eks update-kubeconfig `
    --name $OctopusParameters["CLUSTER_NAME"] `
    --region $OctopusParameters["CLUSTER_REGION"]
helm dependency update $PackagePath
ct install `
    --charts $PackagePath `
    --namespace lazy-helm-charts
