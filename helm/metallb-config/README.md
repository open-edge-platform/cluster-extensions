<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

# MetalLB configuration helm chart

This Helm chart creates needed resources for MetalLB to work properly.

IPAddressPool creates pool of IP addresses which are used for ExternalIP allocation.
L2Advertisement enables new IP address advertisement via L2.
