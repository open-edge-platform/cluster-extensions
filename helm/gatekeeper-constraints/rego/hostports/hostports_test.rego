# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostports

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {"name": "my-pod"},
		"spec": pod_spec,
	}}
}

review_pod1(pod_spec, namespace) = out {
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

pod_spec(containers, image, hostPort) = out {
	out = {containers: [{
		"name": "container1",
		"image": image,
		"ports": [{
			"containerPort": "8080",
			"hostPort": hostPort,
			"hostIP": "192.168.1.10",
		}],
	}]}
}

input_obj(review, allow, min, max) = out {
	out = {
		"parameters": {"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"], "allowHostPort": allow, "min": min, "max": max, "namespaceOnlyExemptImages": ["exemptNamespace/sample-image:v1.0.0"]},
		"review": review,
	}
}

test_allowed_host_ports_with_ports_within_range {
	input := input_obj(review_pod(pod_spec("containers", "sample-image:v1.0.0", 8080)), true, 8000, 9000)
	results := violation with input as input

	count(results) == 0
}

test_disallowed_host_ports {
	input := input_obj(review_pod(pod_spec("containers", "sample-image:v1.0.0", 8080)), false, 8000, 9000)
	results := violation with input as input

	count(results) == 1
}

test_allowed_host_ports_with_ports_below_min {
	input := input_obj(review_pod(pod_spec("containers", "sample-image:v1.0.0", 8080)), true, 9000, 10000)
	results := violation with input as input

	count(results) == 1
}

test_allowed_host_ports_with_ports_above_max {
	input := input_obj(review_pod(pod_spec("containers", "sample-image:v1.0.0", 9080)), true, 8000, 9000)
	results := violation with input as input

	count(results) == 1
}

test_disallowed_host_ports_with_exempt_image {
	input := input_obj(review_pod(pod_spec("containers", "quay.io/kubevirt/virt-launcher:v0.58.0", 9001)), false, 8000, 9000)
	results := violation with input as input

	count(results) == 0
}

test_allowed_host_ports_with_ports_within_range_for_initContainer {
	input := input_obj(review_pod(pod_spec("initContainers", "sample-image:v1.0.0", 8080)), true, 8000, 9000)
	results := violation with input as input

	count(results) == 0
}

test_disallowed_host_ports_for_initContainer {
	input := input_obj(review_pod(pod_spec("initContainers", "sample-image:v1.0.0", 8080)), false, 8000, 9000)
	results := violation with input as input

	count(results) == 1
}

test_allowed_host_ports_with_ports_within_range_for_ephemeralContainer {
	input := input_obj(review_pod(pod_spec("ephemeralContainers", "sample-image:v1.0.0", 8080)), true, 8000, 9000)
	results := violation with input as input

	count(results) == 0
}

test_disallowed_host_ports_for_ephemeralContainer {
	input := input_obj(review_pod(pod_spec("ephemeralContainers", "sample-image:v1.0.0", 8080)), false, 8000, 9000)
	results := violation with input as input

	count(results) == 1
}

test_exempt_image_within_namespace_disallowed_host_ports {
	input := input_obj(review_pod1(pod_spec("containers", "sample-image:v1.0.0", 8080), "exemptNamespace"), false, 8080, 9000)
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_ports_above_max {
	input := input_obj(review_pod1(pod_spec("containers", "sample-image:v1.0.0", 9080), "exemptNamespace"), true, 8080, 9000)
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_ports_below_min {
	input := input_obj(review_pod1(pod_spec("containers", "sample-image:v1.0.0", 8000), "exemptNamespace"), true, 8080, 9000)
	results := violation with input as input

	count(results) == 0
}

test_unexempt_image_within_namespace_disallowed_host_ports {
	input := input_obj(review_pod1(pod_spec("containers", "unexempt-image:v1.0.0", 8080), "exemptNamespace"), false, 8080, 9000)
	results := violation with input as input

	count(results) == 1
}
