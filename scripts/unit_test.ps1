$plugins = helm plugin list
if ( ($plugins | Where-Object {$_.Contains("unittest")}).Length -gt 1 )
{
    Write-Output "Plugin already installed"
}
else
{
    helm plugin install https://github.com/quintush/helm-unittest
}

$chartDirs = (Get-ChildItem -Directory ./charts/ -Name)
foreach ( $chartDir in $chartDirs )
{
    helm dependency update "./charts/${chartDir}"
}

helm unittest -3 --strict -f ci/unit/*.yaml ./charts/*
exit $LASTEXITCODE