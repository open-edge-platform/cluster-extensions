<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

# Helm Chart

To run this Helm Chart use following command:

`helm install --create-namespace --namespace=cdi cdi PATH_TO_HELM_CHART`

and then run following command to make sure that it got installed successfully:

```bash
kubectl wait cdi cdi --for condition=Available --timeout=5m
kubectl get all -n cdi
```
