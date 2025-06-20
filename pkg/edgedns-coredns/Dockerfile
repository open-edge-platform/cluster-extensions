# SPDX-FileCopyrightText: (C) 2024 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

FROM debian:stable-slim@sha256:ecf7312e554c5be68880b2675bcff3dfc64e12ae2f67649c3a392df398711371 AS certs
SHELL [ "/bin/sh", "-ec" ]

# hadolint ignore=DL3008,DL3015
RUN export DEBCONF_NONINTERACTIVE_SEEN=true \
           DEBIAN_FRONTEND=noninteractive \
           DEBIAN_PRIORITY=critical \
           TERM=linux ; \
    apt-get -qq update ; \
    apt-get -yyqq upgrade ; \
    apt-get -yyqq install ca-certificates ; \
    apt-get clean

FROM golang:1.24.4@sha256:10c131810f80a4802c49cab0961bbe18a16f4bb2fb99ef16deaa23e4246fc817  AS build

WORKDIR /workspace

# Download deps in separate step for caching
COPY go.mod go.sum ./
RUN go mod download

# Copy sources to the working directory
COPY . .

# Statically compile binary
RUN CGO_ENABLED=0 \
    GOARCH=amd64 \
    GOOS=linux \
    go build -trimpath -mod=readonly -gcflags="all=-spectre=all -N -l" -asmflags="all=-spectre=all" -ldflags="all=-s -w" -o build/edgedns ./cmd/edgedns-coredns

FROM scratch

ARG org_oci_version=unknown
ARG org_oci_source=unknown
ARG org_oci_revision=unknown
ARG org_oci_created=unknown

LABEL org.opencontainers.image.version=$org_oci_version \
      org.opencontainers.image.source=$org_oci_source \
      org.opencontainers.image.revision=$org_oci_revision \
      org.opencontainers.image.created=$org_oci_created

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /workspace/build/edgedns /coredns

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
