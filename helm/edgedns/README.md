<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

# Helm Chart for EdgeDNS

This chart instantiates following components of EdgeDNS:

1. `etcd` - backend storage. It saves A-records.
2. `coredns` - coredns pod to handle actual DNS queries. It reads available A-records from etcd and returns it to client.
3. `external-dns` - reads annotation from services and creates A-records to etcd.  

To run this Helm Chart use the following command:

`helm install --create-namespace --namespace=<EdgeDNS namespace> edgedns PATH_TO_HELM_CHART`

To confirm that the Helm chart was installed successfully, run the following commands:

```sh
kubectl get all -n <EdgeDNS namespace>
```
