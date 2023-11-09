---
# yamllint disable rule:line-length
assembly-file-versioning-format: '{NuGetVersionV2}.{env:GITHUB_RUN_NUMBER ?? 9999}'
assembly-versioning-format: '{NuGetVersionV2}.{env:GITHUB_RUN_NUMBER ?? 9999}'
# Conventional Commits https://www.conventionalcommits.org/en/v1.0.0/
# https://regex101.com/r/Ms7Vx6/2
major-version-bump-message: '(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z]+\))?(!: .+|: (.+\n\n)+BREAKING CHANGE: .+)'
# https://regex101.com/r/Oqhi2m/1
minor-version-bump-message: '(feat)(\([a-z]+\))?: .+'
# https://regex101.com/r/f5C4fP/1
patch-version-bump-message: '(build|chore|ci|docs|fix|perf|refactor|revert|style|test)(\([a-z]+\))?: .+'
# Match nothing
no-bump-message: ^\b$
next-version: ${version}

mode: ContinuousDeployment
continuous-delivery-fallback-tag: ''
branches:
  development:
    increment: None
    # Everything except main and master
    regex: ^(?!(main|master|beta)$)
    track-merge-target: true
    source-branches: []
    tag: alpha
  beta:
    increment: None
    # Everything except main and master
    regex: ^beta$
    track-merge-target: true
    source-branches: [development]
    tag: beta
  feature:
    # Match nothing
    regex: ^\b$
  develop:
    # Match nothing
    regex: ^\b$
  main:
    source-branches: []
  release:
    # Match nothing
    regex: ^\b$
  pull-request:
    # Match nothing
    regex: ^\b$
  hotfix:
    # Match nothing
    regex: ^\b$
  support:
    # Match nothing
    regex: ^\b$
