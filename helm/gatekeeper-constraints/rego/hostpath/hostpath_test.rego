# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostpath

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {
			"name": "my-pod",
			"namespace": "default",
		},
		"spec": pod_spec,
	}}
}

review_pod2(pod_spec, namespace) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {
			"name": "my-pod",
			"namespace": namespace,
		},
		"spec": pod_spec,
	}}
}

pod_spec1 = out {
	out = {
		"containers": [{
			"name": "container1",
			"image": "image",
			"volumeMounts": [{
				"name": "vol1",
				"mountPath": "/host/test",
			}],
		}],
		"volumes": [{
			"name": "vol1",
			"hostPath": [
				{
					"path": "/data",
					"type": "Directory",
				},
				{
					"name": "test-volume",
					"emptyDir": {},
				},
			],
		}],
	}
}

pod_spec2 = out {
	out = {
		"containers": [{
			"name": "container1",
			"volumeMounts": [{
				"name": "vol2",
				"mountPath": "/host/test2",
			}],
		}],
		"volumes": [{
			"name": "test-volume",
			"emptyDir": {},
		}],
	}
}

pod_spec3 = out {
	out = {"containers": [{"name": "container1"}]}
}

pod_spec4(image) = out {
	out = {
		"containers": [{
			"name": "container1",
			"image": image,
			"volumeMounts": [{
				"name": "vol1",
				"mountPath": "/host/test",
			}],
		}],
		"volumes": [{
			"name": "vol1",
			"hostPath": [
				{
					"path": "/data",
					"type": "Directory",
				},
				{
					"name": "test-volume",
					"emptyDir": {},
				},
			],
		}],
	}
}

input_obj(review) = out {
	out = {
		"parameters": {"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"], "namespaceOnlyExemptImages": ["exemptNamespace/sample_image:v1.0.0"]},
		"review": review,
	}
}

test_pod_with_host_path_returns_violation {
	input := input_obj(review_pod(pod_spec1))
	results := violation with input as input

	count(results) == 1
}

test_pod_without_host_path_does_not_return_violation {
	input := input_obj(review_pod(pod_spec2))
	results := violation with input as input

	count(results) == 0
}

test_pod_without_volumes_does_not_return_violation {
	input := input_obj(review_pod(pod_spec3))
	results := violation with input as input

	count(results) == 0
}

test_exempt_pod_with_host_path_doesnt_return_violation {
	input := input_obj(review_pod(pod_spec4("quay.io/kubevirt/virt-launcher:v0.58.0")))
	results := violation with input as input

	count(results) == 0
}

test_exempt_pod_within_namespace_with_host_path_doesnt_return_violation {
	input := input_obj(review_pod2(pod_spec4("sample_image:v1.0.0"), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}
