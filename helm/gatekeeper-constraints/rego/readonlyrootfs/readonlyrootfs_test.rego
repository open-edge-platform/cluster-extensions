# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.readonlyrootfilesystem

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

pod_spec1(containers, containername, image, rorootfs) = out {
	out = {containers: [{
		"name": containername,
		"image": image,
		"securityContext": {"readOnlyRootFilesystem": rorootfs},
	}]}
}

pod_spec2(containers, containername, image) = out {
	out = {containers: [{
		"name": containername,
		"image": image,
	}]}
}

input_obj(review) = out {
	out = {
		"parameters": {
			"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"],
			"namespaceOnlyExemptImages": ["exemptNamespace/sample-image:v1.0.0"],
			"exemptContainerNames": ["volumecontainervolume", "volumecontainervolume-init"],
		},
		"review": review,
	}
}

test_container_with_rorootfs_true {
	input := input_obj(review_pod(pod_spec1("containers", "container1", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_container_with_rorootfs_false {
	input := input_obj(review_pod(pod_spec1("containers", "container1", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 1
}

test_container_with_rorootfs_false_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec1("containers", "volumecontainervolume", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_init_container_with_rorootfs_true {
	input := input_obj(review_pod(pod_spec1("initContainers", "container1", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_init_container_with_rorootfs_false_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec1("initContainers", "volumecontainervolume-init", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_container_with_rorootfs_true {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "container1", "sample-image:v1.0.0", true)))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_container_with_rorootfs_false {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "container1", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 1
}

test_ephemeral_container_with_rorootfs_false_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "volumecontainervolume", "sample-image:v1.0.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("containers", "container1", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 1
}

test_container_without_security_context_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec2("containers", "volumecontainervolume", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_init_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("initContainers", "container1", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 1
}

test_init_container_without_security_context_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec2("initContainers", "volumecontainervolume-init", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_init_container_without_security_context {
	input := input_obj(review_pod(pod_spec2("ephemeralContainers", "container1", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 1
}

test_ephemeral_init_container_without_security_context_and_exempt_container_names {
	input := input_obj(review_pod(pod_spec2("ephemeralContainers", "volumecontainervolume", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_container_with_rorootfs_false_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("containers", "container1", "quay.io/kubevirt/virt-launcher:v0.58.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_init_container_with_rorootfs_false_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("initContainers", "container1", "quay.io/kubevirt/virt-launcher:v0.58.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_ephemeral_container_with_rorootfs_false_and_exempt_image {
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "container1", "quay.io/kubevirt/virt-launcher:v0.58.0", false)))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_rorootfs_false {
	input := input_obj(review_pod1(pod_spec1("containers", "container1", "sample-image:v1.0.0", false), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_with_rorootfs_true {
	input := input_obj(review_pod1(pod_spec1("containers", "container1", "sample-image:v1.0.0", true), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_without_security_context {
	input := input_obj(review_pod1(pod_spec2("containers", "container1", "sample-image:v1.0.0"), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}
