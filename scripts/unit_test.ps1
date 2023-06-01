try
{
  helm plugin install https://github.com/quintush/helm-unittest
}
catch
{
}

$chartDirs = (Get-ChildItem -Directory ./charts/ -Name)
foreach ( $chartDir in $chartDirs )
{
  helm dependency update "./charts/${chartDir}"
}

helm unittest --strict -f ci/unit/*.yaml ./charts/*
exit $LASTEXITCODE