<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

# Cluster Extensions

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

Cluster Extensions are a collection of cloud-native applications
that facilitate the deployment of Edge Nodes in the Edge Platform.

They support both

- the baseline capability of the Edge Node as **base extensions** and
- the optional additional capability of the Edge Node as **application extensions**

The base extensions are the minimum set of applications that are required to secure the Edge Node and provide the basic
functionality of the Edge Node like observability, logging, monitoring, etc. These are listed in the
[base-extensions Deployment Package](deployment-package/base-extensions).

The application extensions are the optional set of applications that facilitate the deployment of advanced applications
on the Edge Node such as Load Balancer, GPU support, SRIOV support. These each have their own Deployment Package.

Both sets of extensions are loaded into the Edge Orchestrator
by default and are available for deployment from the Web UI.

The CI integration for this repository will publish container images, deployment packages and helm charts to the
Edge Orchestrator Release Service OCI registry upon merge to the main branch.

At installation time, the Edge Orchestrator will pull these artifacts (based on a manifest) from the registry and
install them in the [Application Catalog] and the [Tenant Controller] will ensure that the applications are available
for deployment in each multi-tenancy Project on the Edge Orchestrator.

## Get Started

See [Edge Orchestrator Application Orchestrator Developer Guide](https://docs.openedgeplatform.intel.com/edge-manage-docs/main/developer_guide/app_orch/index.html)
for more information on how these fit into the overall Application Orchestration environment.

See [Edge Orchestrator Application Orchestrator User Guide](https://docs.openedgeplatform.intel.com/edge-manage-docs/main/user_guide/package_software/extension_package.html)
for more information on how to deploy these extensions.

## Develop

### Deployment Packages

New application extensions can be added to this repository by:

- first creating a new Deployment Package folder in the `deployment-package` directory
- creating an "applications.yaml" file in this folder. This file should contain the list of applications that are part
  of this extension, and give a reference to their helm chart and the registry where it can be found.
- creating a "-values.yaml" file with overrides for the helm chart; one for each application in the
  extension - referenced from applications.yaml
- creating a "deployment-package.yaml" file to gather the applications together

### Helm charts

If any of the applications are new, then the helm chart should be created in the **helm** directory.

Open source charts should not be copied into this repository (or used as subcharts), but should be referenced from the
upstream repository from within the "application.yaml" file.

Many examples can be found in the existing Deployment Packages and helm charts.

### Containers

If there are new containers required for new applications they can also be stored in this repository in the **pkg**
directory. Include the `common.mk` file in the Makefile and use the `make` command to build the container images
and ensure that CI can push the image to the registry.

## Dependencies

This code requires the following tools to be installed on your development machine:

- [Docker](https://docs.docker.com/engine/install/) to build containers
- [Go\* programming language](https://go.dev)
- [golangci-lint](https://github.com/golangci/golangci-lint)
- [Python\* programming language version 3.10 or later](https://www.python.org/downloads)
- [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/) based cluster for end-to-end tests
- [Helm](https://helm.sh/docs/intro/install/) for install helm charts for end-to-end tests

## Build

Below are some of important make targets which developer should be aware about.

Build the component binaries as follows:

```bash
# Build go binaries
make build
```

License checks are run for each PR and user can run linter check as follows:

```bash
make license
```


Linter checks are run for each PR and user can run linter as follows:

```bash
make lint
```

Container images for the components are generated as follows:

```bash
make docker-build
```

If developer has done any helm chart changes then helm charts can be build as follows:

```bash
make helm-build
```

## Contribute

We welcome contributions from the community! To contribute, please open a pull request to have your changes reviewed
and merged into the `main` branch. We encourage you to add appropriate unit tests and end-to-end tests if
your contribution introduces a new feature. See [Contributor Guide] for information on how to contribute to the project.


## Community and Support

To learn more about the project, its community, and governance, visit the [Edge Orchestrator Community](https://github.com/open-edge-platform).
For support, start with [Troubleshooting](https://github.com/open-edge-platform) or [contact us](https://github.com/open-edge-platform).

## License

Cluster Extensions is licensed under [Apache 2.0 License](LICENSES/Apache-2.0.txt).

[Application Catalog]: https://github.com/open-edge-platform/app-orch-catalog
[Tenant Controller]: https://github.com/open-edge-platform/app-orch-tenant-controller
[Contributor Guide]: https://docs.openedgeplatform.intel.com/edge-manage-docs/main/developer_guide/contributor_guide/index.html
