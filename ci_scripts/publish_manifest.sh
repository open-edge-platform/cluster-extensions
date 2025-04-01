#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -xeu -o pipefail

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

REGISTRY=080137407410.dkr.ecr.us-west-2.amazonaws.com
REGISTRY_NO_AUTH=edge-orch
REPOSITORY=en

# check if manifest file is changed
changed_files=$(git show --pretty="" --name-only | grep "manifest/manifest.yaml" || true)
echo "changed_files: $changed_files"

if [ -n "$changed_files" ]; then
    manifest_version=$(yq eval '.metadata.release' "manifest/manifest.yaml")
    # git show HEAD~1:"manifest/manifest.yaml" > previous-manifest.yaml
    # previous_manifest_version=$(yq eval '.metadata.release' previous-manifest.yaml)
    # rm previous-manifest.yaml

    # # check if release version is updated
    # if [[ "$manifest_version" == "$previous_manifest_version" && "$manifest_version" != *"-dev"* ]]; then
    #     echo "Manifest version is not changed. Please ensure to upadate the release version"
    #     exit 1
    # fi

    # create a temporary version file
    version="$manifest_version"
    echo "version: $version"
    echo "$version" > tmp-version

    # publish
    echo "publishing manifest"
    BRANCH_NAME=$current_branch ./ci/scripts/push_oci_packages.sh -r $REGISTRY -f "manifest" -v tmp-version -s $REGISTRY_NO_AUTH/$REPOSITORY -o "cluster-extension-manifest"
    rm tmp-version
fi
