param (
    [String] $PackagePath
)

aws eks update-kubeconfig `
    --name $OctopusParameters["CLUSTER_NAME"] `
    --region $OctopusParameters["CLUSTER_REGION"]
ct install `
    --charts $PackagePath `
    --namespace lazy-helm-charts
