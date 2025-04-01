<!---
  SPDX-FileCopyrightText: (C) 2025 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->
# Helm Chart

To run this Helm Chart use following command:

`helm install -n gatekeeper-system gatekeeper-constraints PATH_TO_HELM_CHART`

and then run the following command to make sure all constraints were deployed successfully:

```console
kubectl get constraints
```

The following is the sample output:

```console
NAME                                                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
hostnetwork.constraints.gatekeeper.sh/host-network                        0

NAME                                                                      ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
readonlyrootfilesystem.constraints.gatekeeper.sh/readonlyrootfilesystem                        0

NAME                                                       ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
allowedsysctls.constraints.gatekeeper.sh/allowed-sysctls                        0

NAME                                                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
volumetypes.constraints.gatekeeper.sh/volume-types                        0

NAME                                                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
hostnamespace.constraints.gatekeeper.sh/host-namespace                        0

NAME                                             ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
hostports.constraints.gatekeeper.sh/host-ports                        0

NAME                                                                                    ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
privilegeescalationcontainer.constraints.gatekeeper.sh/privilege-escalation-container                        0

NAME                                                                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
privilegedcontainer.constraints.gatekeeper.sh/privileged-container                        0

NAME                                                  ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
capabilities.constraints.gatekeeper.sh/capabilities                        0

NAME                                                              ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
forbiddenrootuser.constraints.gatekeeper.sh/forbidden-root-user                        0
```
