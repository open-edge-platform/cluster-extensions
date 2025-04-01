#!/usr/bin/env bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -xeu -o pipefail

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

REGISTRY=080137407410.dkr.ecr.us-west-2.amazonaws.com
REGISTRY_NO_AUTH=edge-orch
REPOSITORY=en

# search all deployment-package directories for file changes
changed_dirs=$(git show --pretty="" --name-only | xargs dirname \$1 | cut -d "/" -f2 | sort | uniq)
echo "changed_dirs: $changed_dirs"
# Check if the deployment-package directory is valid
for dir in ${changed_dirs}; do
  package_path="deployment-package/${dir}/"
  if [ ! -f "${package_path}/deployment-package.yaml" ]; then
    continue
  fi
  echo "---------$dir-------------"
  if [ ! -f "${package_path}/application.yaml" ]; then
    # Create a temporary directory for combined applications.yaml and values files
    mkdir -p tmp/deployment-package
    temp_dir="tmp/deployment-package"
    combined_applications_file="${temp_dir}/application.yaml"
    # Combine applications.yaml files
    find "${package_path}" -name "applications.yaml" -exec cat {} + >>"${combined_applications_file}"
    # Combine registry-*.yaml files
    find deployment-package/common -name "registry-*.yaml" -exec cat {} + >>tmp/deployment-package/registries.yaml
    # Copy values-*.yaml files to the temporary directory
    find "${package_path}" -name "values-*.yaml" -exec cp {} "${temp_dir}" \;
    cp "${package_path}/deployment-package.yaml" "${temp_dir}"
  else
    temp_dir=$package_path
  fi
  # create a temporary version file
  version=$(yq eval '.version' "deployment-package/$dir/deployment-package.yaml")
  echo "version: $version"
  echo "$version" > tmp-version
  # publish
  echo "publishing $dir"
  BRANCH_NAME=$current_branch ./ci/scripts/push_oci_packages.sh -r $REGISTRY -f "$temp_dir" -v tmp-version -s $REGISTRY_NO_AUTH/$REPOSITORY -o "$dir"
  rm -rf tmp/deployment-package tmp-version
done
