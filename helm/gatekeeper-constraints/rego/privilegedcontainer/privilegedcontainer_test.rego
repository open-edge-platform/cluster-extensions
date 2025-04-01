# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.privilegedcontainer

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {"name": "my-pod"},
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

pod_spec1(containers, image, privileged) = out {
	out = {containers: [{
		"name": "container1",
		"image": image,
		"securityContext": {"privileged": privileged},
	}]}
}

pod_spec2(containers, image) = out {
	out = {containers: [{
		"name": "container1",
		"image": image,
	}]}
}

input_obj(review) = out {
	out = {
		"parameters": {"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"], "namespaceOnlyExemptImages": ["exemptNamespace/sample-image:v1.0.0"]},
		"review": review,
	}
}

test_container_with_privileged_false {
	input := input_obj(review_pod(pod_spec1("containers", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_container_with_privileged_true {
	input := input_obj(review_pod(pod_spec1("containers", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 1
}

test_init_container_with_privileged_true {
	input := input_obj(review_pod(pod_spec1("initContainers", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 1
}

test_ephemeral_container_with_privileged_true {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 1
}

test_init_container_with_privileged_false {
	input := input_obj(review_pod(pod_spec1("initContainers", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_init_container_with_privileged_false {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("containers", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_init_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("initcontainers", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_init_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("ephemeralcontainers", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_container_with_privileged_true_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("containers", "quay.io/kubevirt/virt-launcher:v0.58.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_init_container_with_privileged_true_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("initContainers", "quay.io/kubevirt/virt-launcher:v0.58.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_container_with_privileged_true_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "quay.io/kubevirt/virt-launcher:v0.58.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_privileged_true {
	input := input_obj(review_pod2(pod_spec1("containers", "sample-image:v1.0.0", true), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_privileged_false {
	input := input_obj(review_pod2(pod_spec1("containers", "sample-image:v1.0.0", false), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_without_security_context {
	input := input_obj(review_pod2(pod_spec2("containers", "sample-image:v1.0.0"), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}
