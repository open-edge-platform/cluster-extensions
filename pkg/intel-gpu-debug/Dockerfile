# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM ubuntu:22.04

# WA for *.intel.com in hosts no_proxy; https://repositories.intel.com/ is outside Intel network and need to go through proxy
ENV no_proxy=""
ENV NO_PROXY=""

ARG APT="env DEBIAN_FRONTEND=noninteractive  apt-get"

RUN \
export no_proxy="" && export NO_PROXY="" && \
bash -o pipefail -c "export no_proxy=""; export NO_PROXY=""; echo \$no_proxy; echo \$NO_PROXY" && \
# Install generic tools
${APT} update && \
${APT} install -y wget gpg-agent && \
# Setup repositories
bash -o pipefail -c "export no_proxy=""; export NO_PROXY=""; wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg" && \
bash -o pipefail -c "export no_proxy=""; export NO_PROXY=""; echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy/production/2328 unified\" | tee /etc/apt/sources.list.d/intel-gpu-jammy.list" && \
bash -o pipefail -c "export no_proxy=""; export NO_PROXY=""; wget -qO - https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor --output /usr/share/keyrings/intel-ov.gpg" && \
bash -o pipefail -c "export no_proxy=""; export NO_PROXY=""; echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/intel-ov.gpg] https://apt.repos.intel.com/openvino/2023 ubuntu22 main\" | tee /etc/apt/sources.list.d/intel-openvino-2023.list" && \
${APT} update && \
# Install GPU tools
${APT} install -y --no-install-recommends intel-opencl-icd clinfo xpu-smi pciutils lshw  && \
# Install OpenVINO
${APT} install -y --no-install-recommends openvino  && \
# Cleanup
${APT} remove -y curl gpg-agent && ${APT} autoremove -y

#ENV http_proxy=
#ENV HTTP_PROXY=
#ENV https_proxy=
#ENV HTTPS_PROXY=
