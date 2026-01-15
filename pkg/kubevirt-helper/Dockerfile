# SPDX-FileCopyrightText: (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.25.5@sha256:6cc2338c038bc20f96ab32848da2b5c0641bb9bb5363f2c33e9b7c8838f9a208  AS build
ENV APP_ROOT=$GOPATH/src/github.com/open-edge-platform/cluster-extensions/pkg/kubevirt-helper
ENV CGO_ENABLED=0
ENV GO111MODULE=on


RUN mkdir -p $APP_ROOT/

COPY ./cmd /$APP_ROOT/cmd
COPY ./internal /$APP_ROOT/internal
COPY ./vendor /$APP_ROOT/vendor
COPY ./go.mod /$APP_ROOT/go.mod
COPY ./go.sum /$APP_ROOT/go.sum

WORKDIR $APP_ROOT
RUN GOARCH=amd64 \
    GOOS=linux \
    go build \
      -trimpath -mod=vendor -gcflags="all=-spectre=all -N -l" -asmflags="all=-spectre=all" -ldflags="all=-s -w" \
      -o /go/bin/kubevirt-helper ./cmd/kubevirt-helper

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot@sha256:c0f429e16b13e583da7e5a6ec20dd656d325d88e6819cafe0adb0828976529dc
USER nonroot

ARG org_oci_version=unknown
ARG org_oci_source=unknown
ARG org_oci_revision=unknown
ARG org_oci_created=unknown

LABEL org.opencontainers.image.version=$org_oci_version \
      org.opencontainers.image.source=$org_oci_source \
      org.opencontainers.image.revision=$org_oci_revision \
      org.opencontainers.image.created=$org_oci_created

WORKDIR /

COPY --from=build --chown=65532:65532 /go/bin/kubevirt-helper /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/kubevirt-helper"]
