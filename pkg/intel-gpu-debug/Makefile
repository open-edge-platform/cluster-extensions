# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

DOCKER_IMG_NAME      ?= intel-gpu-debug

# Add an identifying suffix for `-dev` builds only.
# Release build versions are verified as unique by the CI build process.
ifeq ($(findstring -dev,$(VERSION)), -dev)
	VERSION := $(VERSION)-$(VERSION_DEV_SUFFIX)
endif

# Include shared makefile
include ../../common.mk

.PHONY: docker-build docker-push lint

docker-build: common-docker-build-intel-gpu-debug

docker-push: common-docker-push

lint:
