# SPDX-FileCopyrightText: (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

export GO111MODULE=on

.PHONY: go-build run test docker-build docker-push lint
BUILD_DIR ?=dist

DOCKER_IMG_NAME      ?= kubevirt-helper
KUBEVIRT_NAMESPACE   ?= edge-node

FUZZ_SECONDS ?= 60

# Include shared makefile
include ../../common.mk

.PHONY: build all test coverage list help mod-update

all: build lint test
	@# Help: Runs build, lint, test stages

go-build: fmt vet common-go-build-kubevirt-helper

docker-build: common-docker-build-kubevirt-helper

docker-push: common-docker-push

TEST_COVER=atomic ./cmd/... ./internal/...
test: go-test

go-fuzz: FUZZ_FUNCS ?= FuzzGetVMsFromAdmissionRequest FuzzCompareVMSpec
go-fuzz: FUZZ_FUNC_PATH := ./internal/kubevirt/fuzztests
go-fuzz: common-go-fuzz-test ## Run go fuzz tests

generate-mocks:
	go install github.com/vektra/mockery/v2@v2.20.0
	go generate ./internal/...

coder-rebuild:
	@# Help: Rebuild images and load into Coder KinD cluster
	echo ${DOCKER_VERSION}
	make docker-build
	kind load docker-image -n $(KUBEVIRT_NAMESPACE) $(DOCKER_REGISTRY)/$(DOCKER_REPOSITORY)/${KUBEVIRT_HELPER_IMAGE_NAME}:${DOCKER_VERSION}

coder-redeploy:
	@$(eval DEPLOYMENT_NAME=$(shell kubectl -n $(KUBEVIRT_NAMESPACE) get deployments.apps --no-headers -o custom-columns=":metadata.name" | grep "kubevirt-helper$$"))
	@if [ -z "$(DEPLOYMENT_NAME)" ]; then \
		echo "No 'kubevirt-helper' deployment found in namespace $(KUBEVIRT_NAMESPACE)."; \
		exit 1; \
	fi
	kubectl -n $(KUBEVIRT_NAMESPACE) set image deployment/$(DEPLOYMENT_NAME) $(KUBEVIRT_HELPER_CONTAINER_NAME)=${DOCKER_REGISTRY}${DOCKER_REPOSITORY}/$(KUBEVIRT_HELPER_IMAGE_NAME):${DOCKER_VERSION}
	@echo "Deployment $(DEPLOYMENT_NAME) in namespace $(KUBEVIRT_NAMESPACE) updated to $(KUBEVIRT_HELPER_IMAGE_NAME):${DOCKER_VERSION}"

LINT_DIRS := cmd/kubevirt-helper internal/...

lint: go-lint hadolint
