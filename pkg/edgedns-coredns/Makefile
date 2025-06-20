# SPDX-FileCopyrightText: (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

export GO111MODULE=on

.PHONY: go-build run test docker-build docker-push lint
BUILD_DIR ?=dist

DOCKER_IMG_NAME      ?= edgedns-coredns

# Add an identifying suffix for `-dev` builds only.
# Release build versions are verified as unique by the CI build process.
ifeq ($(findstring -dev,$(VERSION)), -dev)
	VERSION := $(VERSION)-$(VERSION_DEV_SUFFIX)
endif

# Include shared makefile
include ../../common.mk

go-build: fmt vet common-go-build-edgedns-coredns

run: fmt vet ## Run a controller from your host.
	go run cmd/edgedns-coredns/main.go

test:
	go test -v ./...

docker-build: common-docker-build-edgedns-coredns

docker-push: common-docker-push

LINT_DIRS := ./...

lint: go-lint
