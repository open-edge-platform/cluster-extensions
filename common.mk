# common.mk - common targets for App Orchestration modules

# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Makefile Style Guide:
# - Help will be generated from ## comments at end of any target line
# - Use smooth parens $() for variables over curly brackets ${} for consistency
# - Continuation lines (after an \ on previous line) should start with spaces
#   not tabs - this will cause editor highligting to point out editing mistakes
# - When creating targets that run a lint or similar testing tool, print the
#   tool version first so that issues with versions in CI or other remote
#   environments can be caught

# Optionally include tool version checks, not used in Docker builds
ifeq ($(TOOL_VERSION_CHECK), 1)
	include ../version.mk
endif

#### Variables ####

# Shell config variable
SHELL	:= bash -eu -o pipefail

# GO variables
GOARCH	:= $(shell go env GOARCH)
GOCMD   := GOPRIVATE="github.com/intel/*,github.com/open-edge-platform/*" go

# Path variables
OUT_DIR	:= out
BIN_DIR := bin

# Docker variables
DOCKER_ENV              := DOCKER_BUILDKIT=1
DOCKER_REGISTRY         ?= 080137407410.dkr.ecr.us-west-2.amazonaws.com
DOCKER_REPOSITORY       ?= edge-orch/en
DOCKER_IMG_NAME         ?= $(error DOCKER_IMG_NAME must be defined in the Makefile)
DOCKER_VERSION          ?= $(shell git branch --show-current | sed 's/\//-/g')
DOCKER_VERSION          := $(if $(DOCKER_VERSION),$(DOCKER_VERSION),$(shell echo $$GITHUB_HEAD_REF | sed 's/\//-/g'))
DOCKER_VERSION          := $(if $(DOCKER_VERSION),$(DOCKER_VERSION),$(error Could not determine DOCKER_VERSION))
DOCKER_TAG              := $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(DOCKER_IMG_NAME):$(VERSION)
DOCKER_TAG_BRANCH	    := $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/$(DOCKER_IMG_NAME):$(DOCKER_VERSION)
# Decides if we shall push image tagged with the branch name or not.
DOCKER_TAG_BRANCH_PUSH	?= true

DOCKER_LABEL_REPO_URL   ?= $(shell git remote get-url $(shell git remote | head -n 1))
DOCKER_LABEL_VERSION    ?= $(DOCKER_VERSION)
DOCKER_LABEL_REVISION   ?= $(GIT_COMMIT)
DOCKER_LABEL_BUILD_DATE ?= $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")
DOCKER_BUILD_FLAGS      :=

HELM_REPOSITORY         ?= "app-orch/"
HELM_REGISTRY           ?= "oci://080137407410.dkr.ecr.us-west-2.amazonaws.com/"
HELM_CHART_BUILD_DIR    ?= ./build/_output/
HELM_CHART_PATH	        ?= "./deployments/${HELM_CHART_NAME}"

# Code Versions
VERSION                 := $(shell cat VERSION)
GIT_HASH_SHORT          := $(shell git rev-parse --short=8 HEAD)
VERSION_DEV_SUFFIX      := ${GIT_HASH_SHORT}
GIT_COMMIT              ?= $(shell git rev-parse HEAD)

# Security config for Go Builds - see:
#   https://readthedocs.intel.com/SecureCodingStandards/latest/compiler/golang/
# -trimpath: Remove all file system paths from the resulting executable.
# -gcflags="all=-m": Print optimizations applied by the compiler for review and verification against security requirements.
# -gcflags="all=-spectre=all" Enable all available Spectre mitigations
# -ldflags="all=-s -w" remove the symbol and debug info
# -ldflags="all=-X ..." Embed binary build stamping information
ifeq ($(GOARCH),arm64)
	# Note that arm64 (Apple, similar) does not support any spectre mititations.
  COMMON_GOEXTRAFLAGS := -trimpath -gcflags="all=-spectre= -N -l" -asmflags="all=-spectre=" -ldflags="all=-s -w -X 'main.RepoURL=$(DOCKER_LABEL_REPO_URL)' -X 'main.Version=$(DOCKER_LABEL_VERSION)' -X 'main.Revision=$(DOCKER_LABEL_REVISION)' -X 'main.BuildDate=$(DOCKER_LABEL_BUILD_DATE)'"
else
  COMMON_GOEXTRAFLAGS := -trimpath -gcflags="all=-spectre=all -N -l" -asmflags="all=-spectre=all" -ldflags="all=-s -w -X 'main.RepoURL=$(DOCKER_LABEL_REPO_URL)' -X 'main.Version=$(DOCKER_LABEL_VERSION)' -X 'main.Revision=$(DOCKER_LABEL_REVISION)' -X 'main.BuildDate=$(DOCKER_LABEL_BUILD_DATE)'"
endif

#### Path Target ####

$(OUT_DIR): ## Create out directory
	mkdir -p $(OUT_DIR)

$(BIN_DIR): ## Create bin directory
	mkdir -p $(BIN_DIR)

#### Build Target ####

vendor:
	go mod vendor

mod-update: ## Update Go modules.
	GOPRIVATE=$(GOPRIVATE) go mod tidy

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

#### Docker Targets ####

common-docker-setup-env:
ifdef DOCKER_BUILD_PLATFORM
	-docker buildx rm builder
	docker buildx create --name builder --use
endif

common-docker-build: ## Build a generic Docker image
common-docker-build: common-docker-build-generic

common-docker-build-%: ## Build Docker image
common-docker-build-%: DOCKER_BUILD_FLAGS   += $(if $(DOCKER_BUILD_PLATFORM),--load,)
common-docker-build-%: DOCKER_BUILD_FLAGS   += $(addprefix --platform ,$(DOCKER_BUILD_PLATFORM))
common-docker-build-%: DOCKER_BUILD_FLAGS   += $(addprefix --target ,$(DOCKER_BUILD_TARGET))
common-docker-build-%: common-docker-setup-env
	$(GOCMD) mod vendor
	docker buildx build \
		$(DOCKER_BUILD_FLAGS) \
		-t $(DOCKER_IMG_NAME):$(DOCKER_VERSION) \
		--build-context root=.. \
		--build-arg http_proxy="$(http_proxy)" --build-arg HTTP_PROXY="$(HTTP_PROXY)" \
		--build-arg https_proxy="$(https_proxy)" --build-arg HTTPS_PROXY="$(HTTPS_PROXY)" \
		--build-arg no_proxy="$(no_proxy)" --build-arg NO_PROXY="$(NO_PROXY)" \
		--build-arg REPO_URL="$(DOCKER_LABEL_REPO_URL)" \
		--build-arg VERSION="$(DOCKER_LABEL_VERSION)" \
		--build-arg REVISION="$(DOCKER_LABEL_REVISION)" \
		--build-arg BUILD_DATE="$(DOCKER_LABEL_BUILD_DATE)" \
		.
	@rm -rf vendor

common-docker-push: ## Tag and push Docker image
	# TODO: remove ecr create
	aws ecr create-repository --region us-west-2 --repository-name $(DOCKER_REPOSITORY)/$(DOCKER_IMG_NAME) || true
	docker tag $(DOCKER_IMG_NAME):$(DOCKER_VERSION) $(DOCKER_TAG_BRANCH)
	docker tag $(DOCKER_IMG_NAME):$(DOCKER_VERSION) $(DOCKER_TAG)
	docker push $(DOCKER_TAG)
ifeq ($(DOCKER_TAG_BRANCH_PUSH), true)
	docker push $(DOCKER_TAG_BRANCH)
endif

#### Go Targets ####

common-go-build: common-go-build-generic

common-go-build-%: $(BIN_DIR) ## Build resource manager binary
	$(GOCMD) build $(GOEXTRAFLAGS) -o $(BIN_DIR)/$* ./cmd/$*

#### Python venv Target ####

VENV_NAME	:= venv_$(PROJECT_NAME)

$(VENV_NAME): requirements.txt ## Create Python venv
	python3 -m venv $@ ;\
  set +u; . ./$@/bin/activate; set -u ;\
  python -m pip install --upgrade pip ;\
  python -m pip install -r requirements.txt

#### Maintenance Targets ####

go-tidy: ## Run go mod tidy
	$(GOCMD) mod tidy

go-lint-fix: ## Apply automated lint/formatting fixes to go files
	golangci-lint run --fix --config .golangci.yml

#### Test Targets ####

# https://github.com/koalaman/shellcheck
SH_FILES := $(shell find . -type f \( -name '*.sh' \) -print )
shellcheck: ## lint shell scripts with shellcheck
	shellcheck --version
	shellcheck -x -S style $(SH_FILES)

# https://pypi.org/project/reuse/
license: $(VENV_NAME) ## Check licensing with the reuse tool
	set +u; . ./$</bin/activate; set -u ;\
  reuse --version ;\
  reuse --root . lint

hadolint: ## Check Dockerfile with Hadolint
	hadolint Dockerfile

checksec: go-build ## Check various security properties that are available for executable,like RELRO, STACK CANARY, NX,PIE etc
	$(GOCMD) version -m $(OUT_DIR)/$(BINARY_NAME)
	checksec --output=json --file=$(OUT_DIR)/$(BINARY_NAME)
	checksec --fortify-file=$(OUT_DIR)/$(BINARY_NAME)

yamllint: $(VENV_NAME) ## Lint YAML files
	. ./$</bin/activate; set -u ;\
  yamllint --version ;\
  yamllint -d '{extends: default, rules: {line-length: {max: 99}}, ignore: [$(YAML_IGNORE)]}' -s $(YAML_FILES)

mdlint: ## Link MD files
	markdownlint --version ;\
	markdownlint "**/*.md" -c ../.markdownlint.yml

helmlint: ## Lint Helm charts.
	helm lint ${CHART_PATH}

go-lint: $(OUT_DIR) ## Run go lint
	golangci-lint --version
	golangci-lint run $(LINT_DIRS) --timeout 10m --config .golangci.yml

go-test: $(OUT_DIR) $(GO_TEST_DEPS) ## Run go test and calculate code coverage
	KUBEBUILDER_ASSETS=$(ASSETS) \
	$(GOCMD) test -race -v -p 1 \
	-coverpkg=$(TEST_PKG) -run $(TEST_TARGET) \
	-coverprofile=$(OUT_DIR)/coverage.out \
	-covermode $(TEST_COVER) $(if $(TEST_ARGS),-args $(TEST_ARGS)) \
	| tee >(go-junit-report -set-exit-code > $(OUT_DIR)/report.xml)
	gocover-cobertura $(if $(TEST_IGNORE_FILES),-ignore-files $(TEST_IGNORE_FILES)) < $(OUT_DIR)/coverage.out > $(OUT_DIR)/coverage.xml
	$(GOCMD) tool cover -html=$(OUT_DIR)/coverage.out -o $(OUT_DIR)/coverage.html
	$(GOCMD) tool cover -func=$(OUT_DIR)/coverage.out -o $(OUT_DIR)/function_coverage.log

common-go-fuzz-test: ## GO fuzz tests
	for func in $(FUZZ_FUNCS); do \
		$(GOCMD) test $(FUZZ_FUNC_PATH) -fuzz $$func -fuzztime=${FUZZ_SECONDS}s -v; \
	done

#### Buf protobuf code generation tooling ###

common-buf-update: $(VENV_NAME) ## Update buf modules
	set +u; . ./$</bin/activate; set -u ;\
  buf --version ;\
  pushd api; buf dep update; popd ;\
  buf build

common-buf-lint: $(VENV_NAME) ## Lint and format protobuf files
	buf --version
	buf format -d --exit-code
	buf lint

#### Helm Targets ####

common-helm-package-clean:
	rm -rf ${HELM_CHART_BUILD_DIR}
	yq eval -i 'del(.annotations.revision)' ${HELM_CHART_PATH}/Chart.yaml
	yq eval -i 'del(.annotations.created)' ${HELM_CHART_PATH}/Chart.yaml

common-helm-package: ## Package helm charts.
	rm -rf ${HELM_CHART_BUILD_DIR}${HELM_CHART_NAME}*.tgz
	yq eval -i '.version = "${CHART_VERSION}"' ${HELM_CHART_PATH}/Chart.yaml
	yq eval -i '.appVersion = "${VERSION}"' ${HELM_CHART_PATH}/Chart.yaml
	yq eval -i '.annotations.revision = "${LABEL_REVISION}"' ${HELM_CHART_PATH}/Chart.yaml
	yq eval -i '.annotations.created = "${LABEL_CREATED}"' ${HELM_CHART_PATH}/Chart.yaml
	helm package \
		--version=${CHART_VERSION} \
		--app-version=${VERSION} \
		--dependency-update \
		--destination ${HELM_CHART_BUILD_DIR} \
		${HELM_CHART_PATH}

common-helm-push: ## Push helm charts.
	helm push ${HELM_CHART_BUILD_DIR}${HELM_CHART_NAME}*.tgz $(HELM_REGISTRY)${HELM_REPOSITORY}


#### Clean Targets ###

common-clean: ## Delete build and vendor directories
	rm -rf $(OUT_DIR) vendor

clean-venv: ## Delete Python venv
	rm -rf "$(VENV_NAME)"

clean-all: clean clean-venv ## Delete all built artifacts and downloaded tools

#### Help Target ####

help: ## Print help for each target
	@echo $(PROJECT_NAME) make targets
	@echo "Target               Makefile:Line    Description"
	@echo "-------------------- ---------------- -----------------------------------------"
	@grep -H -n '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort -t ":" -k 3 \
    | awk 'BEGIN  {FS=":"}; {sub(".* ## ", "", $$4)}; {printf "%-20s %-16s %s\n", $$3, $$1 ":" $$2, $$4};'
