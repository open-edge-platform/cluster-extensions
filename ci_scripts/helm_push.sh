#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -xeu -o pipefail

# search all packages with *.tgz name and then push to remote Helm server

# when not running under Jenkins, use current dir as workspace
WORKSPACE=${WORKSPACE:-.}
# HELM_CM_NAME=${HELM_CM_NAME:-oie}
REGISTRY=080137407410.dkr.ecr.us-west-2.amazonaws.com
REGISTRY_NO_AUTH=edge-orch
REPOSITORY=en/charts
HELM_REGISTRY=oci://${REGISTRY}/${REGISTRY_NO_AUTH}/${REPOSITORY}
DOCKER_REGISTRY=${REGISTRY_NO_AUTH}/${REPOSITORY}

# Filter pakage with $name-$version.tgz, and version should be $major.$minor.$patch format
pkg_list=$(find "${WORKSPACE}" -maxdepth 1 -type f -regex ".*tgz" | (grep -E ".*[0-9]+[a-zA-Z]*[+-]*\.[0-9]+[a-zA-Z]*[+-]*\.[0-9]+[a-zA-Z]*[+-]*(-dev)?\.tgz" || echo ""))
if [ -z "$pkg_list" ]; then
  echo "# No Packages found, exit #"
  exit 0
fi

for pkg in $pkg_list; do
  echo "------$pkg------"
  # check if Helm package contains version, fail otherwise
  if [ "$(helm show chart "$pkg" | grep -c version)" -eq 0 ]; then
    echo "# Package $pkg doesn't contain version!!! #"
    exit 1
  fi
  echo $HELM_REGISTRY
  echo "helm pushing $pkg to $HELM_REGISTRY"
  chart_name=$(helm show chart "$pkg" | yq e '.name' -)
  echo chart_name: "$chart_name"
  aws ecr create-repository --region us-west-2 --repository-name $DOCKER_REGISTRY/"$chart_name" || true
  helm push "$pkg" $HELM_REGISTRY
done

echo "# helmpush.sh Success! - all charts have been pushed #"
exit 0
