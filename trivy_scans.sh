#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -euxo pipefail

BRANCH=$(git rev-parse --abbrev-ref HEAD)

mkdir -p trivy_reports
for folder in $(find ./helm -type d -print -maxdepth 1 -mindepth 1); do
    pushd "$folder" > /dev/null
    trivy conf -f json -o "conf-${folder##*/}.json" ./
    trivy scan2html generate --scan2html-flags --output "conf-${folder##*/}.html" --from "conf-${folder##*/}.json"
    rm "conf-${folder##*/}.json"
    mv "conf-${folder##*/}.html" ../../trivy_reports/
    trivy fs -f json -o "fs-${folder##*/}.json" ./
    trivy scan2html generate --scan2html-flags --output "fs-${folder##*/}.html" --from "fs-${folder##*/}.json"
    rm "fs-${folder##*/}.json"
    mv "fs-${folder##*/}.html" ../../trivy_reports/
    popd > /dev/null
done

for image in "edgedns-coredns" "kubevirt-helper" "intel-gpu-debug"; do
    trivy image -f json -o "image-${image##*/}.json" "${image}:$BRANCH"
    trivy scan2html generate --scan2html-flags --output "image-${image##*/}.html" --from "image-${image##*/}.json"
    rm "image-${image##*/}.json"
    mv "image-${image##*/}.html" trivy_reports/
done
