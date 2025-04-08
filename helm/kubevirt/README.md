<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

# Installing Kubevirt

## Helm Chart

To run this Helm Chart use following command:

`helm install --create-namespace --namespace=kubevirt kubevirt PATH_TO_HELM_CHART`

and then run following command to make sure that it got installed successfully:

```bash
kubectl -n kubevirt wait kv kubevirt --for condition=Available --timeout=5m
kubectl get all -n kubevirt
```
