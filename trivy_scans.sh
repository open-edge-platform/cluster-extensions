#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -euxo pipefail

mkdir -p trivy_reports
for folder in $(find ./helm -type d -print -maxdepth 1 -mindepth 1); do
    pushd "$folder" > /dev/null
    trivy conf -f json -o "${folder##*/}.json" ./
    trivy scan2html generate --scan2html-flags --output "${folder##*/}.html" --from "${folder##*/}.json"
    rm "${folder##*/}.json"
    mv "${folder##*/}.html" ../../trivy_reports/
    popd > /dev/null
done
