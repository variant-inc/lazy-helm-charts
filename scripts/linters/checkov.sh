#!/usr/bin/env bash

declare -a charts

# get all chart directory paths
dirs=$(find charts -type d -iname "variant-*")

# create an array of all the chart paths
set -o noglob
IFS=$'\n' charts=($dirs)
set +o noglob

# array of all checks we want to skip
skip_checks=(
    CKV_K8S_23
    CKV_K8S_35
    CKV_K8S_14
    CKV_K8S_20
    CKV_K8S_28
    CKV_K8S_15
    CKV_K8S_40
    CKV_K8S_31
    CKV_K8S_22
    CKV_K8S_37
    CKV_K8S_38
    CKV_K8S_43
    CKV_K8S_21
    )

# join the array of checks to skipchecks with a comma
printf -v skipchecks "%s," "${skip_checks[@]}"

# execute checkov
for c in "${charts[@]}"; do
    checkov -d "$c" --var-file "$c/ci/default-values.yaml" \
    --framework helm \
    --quiet \
    --skip-check $skipchecks 2> /dev/null
done;
