// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package kubevirt

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	v1 "k8s.io/api/admission/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

var (
	testAdmissionReq = admission.Request{
		AdmissionRequest: v1.AdmissionRequest{
			Object: runtime.RawExtension{
				Raw: []byte(testVMNew),
			},
			OldObject: runtime.RawExtension{
				Raw: []byte(testVMOld),
			},
		},
	}

	testVMNew = "{\n    \"apiVersion\": \"kubevirt.io/v1\",\n    \"kind\": \"VirtualMachine\",\n    \"metadata\": {\n        \"annotations\": {\n            \"kubevirt.io/latest-observed-api-version\": \"v1\",\n            \"kubevirt.io/storage-observed-api-version\": \"v1\",\n            \"meta.helm.sh/release-name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"meta.helm.sh/release-namespace\": \"apps\",\n            \"objectset.rio.cattle.io/id\": \"default-b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"resource.orchestrator.apis/description\": \"this vm is for Test Execution console application\"\n        },\n        \"creationTimestamp\": \"2023-10-27T17:49:39Z\",\n        \"finalizers\": [\n            \"kubevirt.io/virtualMachineControllerFinalize\"\n        ],\n        \"generation\": 1,\n        \"labels\": {\n            \"app.kubernetes.io/instance\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"app.kubernetes.io/managed-by\": \"Helm\",\n            \"app.kubernetes.io/name\": \"tx-console-vm\",\n            \"app.kubernetes.io/version\": \"2.0.1\",\n            \"helm.sh/chart\": \"tx-console-vm-1.3.1\",\n            \"kubevirt.io/domain\": \"tx-console-vm\",\n            \"objectset.rio.cattle.io/hash\": \"15b4c262ef62b3a9fa320e227340cdef1ae6a17e\"\n        },\n        \"name\": \"tx-console-vm\",\n        \"namespace\": \"apps\",\n        \"resourceVersion\": \"8517467\",\n        \"uid\": \"160e45c1-0718-4b44-b3a1-f1f465392b0f\"\n    },\n    \"spec\": {\n        \"dataVolumeTemplates\": [\n            {\n                \"metadata\": {\n                    \"creationTimestamp\": null,\n                    \"name\": \"cd-tx-console-vm-pv\"\n                },\n                \"spec\": {\n                    \"pvc\": {\n                        \"accessModes\": [\n                            \"ReadWriteOnce\"\n                        ],\n                        \"resources\": {\n                            \"requests\": {\n                                \"storage\": \"150Gi\"\n                            }\n                        },\n                        \"storageClassName\": \"openebs-lvmpv\"\n                    },\n                    \"source\": {\n                        \"registry\": {\n                            \"certConfigMap\": \"tx-console-vm-cert\",\n                            \"secretRef\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n                            \"url\": \"docker://registry.test-public-orchestrator.edgeorch.net/apps/tx-console-vm:2.0.1\"\n                        }\n                    }\n                }\n            }\n        ],\n        \"running\": true,\n        \"template\": {\n            \"metadata\": {\n                \"annotations\": {\n                    \"resource.orchestrator.apis/description\": \"this vm is for Test Execution console application\"\n                },\n                \"creationTimestamp\": null,\n                \"labels\": {\n                    \"app\": \"tx-console-vm\",\n                    \"app.kubernetes.io/instance\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n                    \"app.kubernetes.io/name\": \"tx-console-vm\",\n                    \"name\": \"tx-console-vm\",\n                    \"resource\": \"tx-console-vm\",\n                    \"type\": \"vm\"\n                }\n            },\n            \"spec\": {\n                \"architecture\": \"amd64\",\n                \"domain\": {\n                    \"cpu\": {\n                        \"cores\": 6,\n                        \"sockets\": 1,\n                        \"threads\": 1\n                    },\n                    \"devices\": {\n                        \"clientPassthrough\": {},\n                        \"disks\": [\n                            {\n                                \"disk\": {\n                                    \"bus\": \"virtio\"\n                                },\n                                \"name\": \"containerdisk\"\n                            },\n                            {\n                                \"disk\": {\n                                    \"bus\": \"virtio\"\n                                },\n                                \"name\": \"cloudinitdisk\"\n                            }\n                        ],\n                        \"interfaces\": [\n                            {\n                                \"bridge\": {},\n                                \"name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e-default\"\n                            }\n                        ]\n                    },\n                    \"machine\": {\n                        \"type\": \"q35\"\n                    },\n                    \"resources\": {\n                        \"limits\": {\n                            \"memory\": \"4Gi\"\n                        },\n                        \"requests\": {\n                            \"memory\": \"4Gi\"\n                        }\n                    }\n                },\n                \"networks\": [\n                    {\n                        \"name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e-default\",\n                        \"pod\": {}\n                    }\n                ],\n                \"volumes\": [\n                    {\n                        \"dataVolume\": {\n                            \"name\": \"cd-tx-console-vm-pv\"\n                        },\n                        \"name\": \"containerdisk\"\n                    },\n                    {\n                        \"cloudInitNoCloud\": {\n                            \"userData\": \"#cloud-config\\nwrite_files:\\n  - path: /bin/startup.sh\\n    permissions: 0755\\n    owner: root:root\\n    content: |\\n      #!/bin/bash\\n      sudo dhclient\\n      sudo systemctl restart qemu-guest-agent\\n      sudo apt install net-tools\\nruncmd:\\n  - /bin/startup.sh\"\n                        },\n                        \"name\": \"cloudinitdisk\"\n                    }\n                ]\n            }\n        }\n    },\n    \"status\": {\n        \"conditions\": [\n            {\n                \"lastProbeTime\": null,\n                \"lastTransitionTime\": \"2023-10-27T18:40:59Z\",\n                \"status\": \"True\",\n                \"type\": \"Ready\"\n            },\n            {\n                \"lastProbeTime\": null,\n                \"lastTransitionTime\": null,\n                \"message\": \"cannot migrate VMI: PVC cd-tx-console-vm-pv is not shared, live migration requires that all PVCs must be shared (using ReadWriteMany access mode)\",\n                \"reason\": \"DisksNotLiveMigratable\",\n                \"status\": \"False\",\n                \"type\": \"LiveMigratable\"\n            }\n        ],\n        \"created\": true,\n        \"desiredGeneration\": 1,\n        \"observedGeneration\": 1,\n        \"printableStatus\": \"Running\",\n        \"ready\": true,\n        \"volumeSnapshotStatuses\": [\n            {\n                \"enabled\": false,\n                \"name\": \"containerdisk\",\n                \"reason\": \"No VolumeSnapshotClass: Volume snapshots are not configured for this StorageClass [openebs-lvmpv] [containerdisk]\"\n            },\n            {\n                \"enabled\": false,\n                \"name\": \"cloudinitdisk\",\n                \"reason\": \"Snapshot is not supported for this volumeSource type [cloudinitdisk]\"\n            }\n        ]\n    }\n}"

	testVMOld = "{\n    \"apiVersion\": \"kubevirt.io/v1\",\n    \"kind\": \"VirtualMachine\",\n    \"metadata\": {\n        \"annotations\": {\n            \"kubevirt.io/latest-observed-api-version\": \"v1\",\n            \"kubevirt.io/storage-observed-api-version\": \"v1\",\n            \"meta.helm.sh/release-name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"meta.helm.sh/release-namespace\": \"apps\",\n            \"objectset.rio.cattle.io/id\": \"default-b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"resource.orchestrator.apis/description\": \"this vm is for Test Execution console application\"\n        },\n        \"creationTimestamp\": \"2023-10-27T17:49:39Z\",\n        \"finalizers\": [\n            \"kubevirt.io/virtualMachineControllerFinalize\"\n        ],\n        \"generation\": 1,\n        \"labels\": {\n            \"app.kubernetes.io/instance\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n            \"app.kubernetes.io/managed-by\": \"Helm\",\n            \"app.kubernetes.io/name\": \"tx-console-vm\",\n            \"app.kubernetes.io/version\": \"2.0.1\",\n            \"helm.sh/chart\": \"tx-console-vm-1.3.1\",\n            \"kubevirt.io/domain\": \"tx-console-vm\",\n            \"objectset.rio.cattle.io/hash\": \"15b4c262ef62b3a9fa320e227340cdef1ae6a17e\"\n        },\n        \"name\": \"tx-console-vm\",\n        \"namespace\": \"apps\",\n        \"resourceVersion\": \"8517467\",\n        \"uid\": \"160e45c1-0718-4b44-b3a1-f1f465392b0f\"\n    },\n    \"spec\": {\n        \"dataVolumeTemplates\": [\n            {\n                \"metadata\": {\n                    \"creationTimestamp\": null,\n                    \"name\": \"cd-tx-console-vm-pv\"\n                },\n                \"spec\": {\n                    \"pvc\": {\n                        \"accessModes\": [\n                            \"ReadWriteOnce\"\n                        ],\n                        \"resources\": {\n                            \"requests\": {\n                                \"storage\": \"150Gi\"\n                            }\n                        },\n                        \"storageClassName\": \"openebs-lvmpv\"\n                    },\n                    \"source\": {\n                        \"registry\": {\n                            \"certConfigMap\": \"tx-console-vm-cert\",\n                            \"secretRef\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n                            \"url\": \"docker://registry.test-public-orchestrator.edgeorch.net/apps/tx-console-vm:2.0.1\"\n                        }\n                    }\n                }\n            }\n        ],\n        \"running\": true,\n        \"template\": {\n            \"metadata\": {\n                \"annotations\": {\n                    \"resource.orchestrator.apis/description\": \"this vm is for Test Execution console application\"\n                },\n                \"creationTimestamp\": null,\n                \"labels\": {\n                    \"app\": \"tx-console-vm\",\n                    \"app.kubernetes.io/instance\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e\",\n                    \"app.kubernetes.io/name\": \"tx-console-vm\",\n                    \"name\": \"tx-console-vm\",\n                    \"resource\": \"tx-console-vm\",\n                    \"type\": \"vm\"\n                }\n            },\n            \"spec\": {\n                \"architecture\": \"amd64\",\n                \"domain\": {\n                    \"cpu\": {\n                        \"cores\": 4,\n                        \"sockets\": 1,\n                        \"threads\": 1\n                    },\n                    \"devices\": {\n                        \"clientPassthrough\": {},\n                        \"disks\": [\n                            {\n                                \"disk\": {\n                                    \"bus\": \"virtio\"\n                                },\n                                \"name\": \"containerdisk\"\n                            },\n                            {\n                                \"disk\": {\n                                    \"bus\": \"virtio\"\n                                },\n                                \"name\": \"cloudinitdisk\"\n                            }\n                        ],\n                        \"interfaces\": [\n                            {\n                                \"bridge\": {},\n                                \"name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e-default\"\n                            }\n                        ]\n                    },\n                    \"machine\": {\n                        \"type\": \"q35\"\n                    },\n                    \"resources\": {\n                        \"limits\": {\n                            \"memory\": \"4Gi\"\n                        },\n                        \"requests\": {\n                            \"memory\": \"4Gi\"\n                        }\n                    }\n                },\n                \"networks\": [\n                    {\n                        \"name\": \"b-1fec9767-d872-58f6-bfad-913e8b9b056e-default\",\n                        \"pod\": {}\n                    }\n                ],\n                \"volumes\": [\n                    {\n                        \"dataVolume\": {\n                            \"name\": \"cd-tx-console-vm-pv\"\n                        },\n                        \"name\": \"containerdisk\"\n                    },\n                    {\n                        \"cloudInitNoCloud\": {\n                            \"userData\": \"#cloud-config\\nwrite_files:\\n  - path: /bin/startup.sh\\n    permissions: 0755\\n    owner: root:root\\n    content: |\\n      #!/bin/bash\\n      sudo dhclient\\n      sudo systemctl restart qemu-guest-agent\\n      sudo apt install net-tools\\nruncmd:\\n  - /bin/startup.sh\"\n                        },\n                        \"name\": \"cloudinitdisk\"\n                    }\n                ]\n            }\n        }\n    },\n    \"status\": {\n        \"conditions\": [\n            {\n                \"lastProbeTime\": null,\n                \"lastTransitionTime\": \"2023-10-27T18:40:59Z\",\n                \"status\": \"True\",\n                \"type\": \"Ready\"\n            },\n            {\n                \"lastProbeTime\": null,\n                \"lastTransitionTime\": null,\n                \"message\": \"cannot migrate VMI: PVC cd-tx-console-vm-pv is not shared, live migration requires that all PVCs must be shared (using ReadWriteMany access mode)\",\n                \"reason\": \"DisksNotLiveMigratable\",\n                \"status\": \"False\",\n                \"type\": \"LiveMigratable\"\n            }\n        ],\n        \"created\": true,\n        \"desiredGeneration\": 1,\n        \"observedGeneration\": 1,\n        \"printableStatus\": \"Running\",\n        \"ready\": true,\n        \"volumeSnapshotStatuses\": [\n            {\n                \"enabled\": false,\n                \"name\": \"containerdisk\",\n                \"reason\": \"No VolumeSnapshotClass: Volume snapshots are not configured for this StorageClass [openebs-lvmpv] [containerdisk]\"\n            },\n            {\n                \"enabled\": false,\n                \"name\": \"cloudinitdisk\",\n                \"reason\": \"Snapshot is not supported for this volumeSource type [cloudinitdisk]\"\n            }\n        ]\n    }\n}"
)

func TestNewKubevirtHandler(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)
}

func TestKubevirtHandler_GetVMsFromAdmissionRequest(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)

	r := testAdmissionReq

	vmNew, vmOld, err := h.GetVMsFromAdmissionRequest(context.Background(), r)
	assert.NotNil(t, vmNew)
	assert.NotNil(t, vmOld)
	assert.NoError(t, err)
}

func TestKubevirtHandler_GetVMsFromAdmissionRequest_FailNewUnmarshal(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)

	r := testAdmissionReq
	r.Object.Raw = []byte{}

	_, _, err := h.GetVMsFromAdmissionRequest(context.Background(), r)
	assert.Error(t, err)
}

func TestKubevirtHandler_GetVMsFromAdmissionRequest_FailOldUnmarshal(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)

	r := testAdmissionReq
	r.OldObject.Raw = []byte{}

	_, _, err := h.GetVMsFromAdmissionRequest(context.Background(), r)
	assert.Error(t, err)
}

func TestKubevirtHandler_CompareVMSpec_Diff(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)

	r := testAdmissionReq

	vmNew, vmOld, err := h.GetVMsFromAdmissionRequest(context.Background(), r)
	assert.NoError(t, err)

	vmSpecUpdate, dvSpecUpdate, err := h.CompareVMSpec(context.Background(), vmNew, vmOld)
	assert.Equal(t, true, vmSpecUpdate)
	assert.Equal(t, false, dvSpecUpdate)
	assert.NoError(t, err)
}

func TestKubevirtHandler_CompareVMSpec_Same(t *testing.T) {
	h := NewKubevirtHandler()
	assert.NotNil(t, h)

	r := testAdmissionReq
	r.OldObject.Raw = r.Object.Raw

	vmNew, vmOld, err := h.GetVMsFromAdmissionRequest(context.Background(), r)
	assert.NoError(t, err)

	vmSpecUpdate, dvSpecUpdate, err := h.CompareVMSpec(context.Background(), vmNew, vmOld)
	assert.Equal(t, false, vmSpecUpdate)
	assert.Equal(t, false, dvSpecUpdate)
	assert.NoError(t, err)
}
