#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -xeu -o pipefail

# build helm charts based on change folders

# when not running under Jenkins, use current dir as workspace
# WORKSPACE=${WORKSPACE:-./helm}

# Code Versions
VERSION=$(cat VERSION)
GIT_HASH_SHORT=$(git rev-parse --short=8 HEAD)
VERSION_DEV_SUFFIX=${GIT_HASH_SHORT}

DOCKER_REPOSITORY=edge-orch/en/
DOCKER_REGISTRY=registry-rs.edgeorchestration.intel.com/
EGDEDNS_IMAGE=${DOCKER_REGISTRY}${DOCKER_REPOSITORY}edgedns-coredns
NODE_PROVISIONER_DAEMON_IMAGE=${DOCKER_REGISTRY}${DOCKER_REPOSITORY}node-provisioner-daemon
EGDEDNS_VERSION=$(cat pkg/edgedns-coredns/VERSION)
VERSIONED_EGDEDNS_IMG=${EGDEDNS_IMAGE}:${EGDEDNS_VERSION}
VERSIONED_NODEPROVISIONER_DAEMON_IMG=${NODE_PROVISIONER_DAEMON_IMAGE}:${VERSION}

# Add an identifying suffix for `-dev` builds only.
# Release build versions are verified as unique by the CI build process.
if [[ $VERSION =~ "-dev" ]]; then
  VERSION=${VERSION}-${VERSION_DEV_SUFFIX}
fi

# Label to add Helm CI meta-data
LABEL_REVISION=$(git rev-parse HEAD)
LABEL_CREATED=$(date -u "+%Y-%m-%dT%H:%M:%SZ")

# Get the changed file name from the latest commit and then get the root folder name.
# shellcheck disable=SC1001
changed_dirs=$(git show --pretty="" --name-only | xargs dirname \$\1 | cut -d "/" -f2,3,4 | sort | uniq)

# Check if no helm files were changes
if [ -z "$changed_dirs" ]; then
  echo "# No helm charts changed or added to build. #"
  exit 0
fi

for dir in ${changed_dirs}; do
  if [ ! -f "helm/$dir/Chart.yaml" ]; then
    continue
  fi
  echo "---------$dir-------------"
  # Dependencies are commited as .tgz into repo
  # echo "--download helm dependency"
  # helm dep build "helm/$dir"
  if [[ $dir == "edgedns" || $dir == "node-provisioner" ]]; then
    echo "--add annotations"
    yq eval -i ".annotations.revision = \"${LABEL_REVISION}\"" "helm/$dir"/Chart.yaml
    yq eval -i ".annotations.created = \"${LABEL_CREATED}\"" "helm/$dir"/Chart.yaml

    echo "--add image version in values.yaml"
    if [ "$dir" == "edgedns" ]; then
      export VERSIONED_EGDEDNS_IMG
      yq e ".extensionImages.[] | select(. == \"${EGDEDNS_IMAGE}\") | document_index " ./helm/"${dir}"/values.yaml | yq e -i " .extensionImages[document_index] = env(VERSIONED_EGDEDNS_IMG)" ./helm/"${dir}"/values.yaml
    elif [ "$dir" == "node-provisioner" ]; then
      export VERSIONED_NODEPROVISIONER_DAEMON_IMG
      yq e ".extensionImages.[] | select(. == \"${NODE_PROVISIONER_DAEMON_IMAGE}\") | document_index " ./helm/"${dir}"/values.yaml | yq e -i " .extensionImages[document_index] = env(VERSIONED_NODEPROVISIONER_DAEMON_IMG)" ./helm/"${dir}"/values.yaml
    fi
  fi
  echo "--package helm"
  helm dependency build "helm/$dir"
  helm package "helm/$dir"
done

echo "# helmbuild.sh Success! - all charts have updated packaged #"
exit 0
