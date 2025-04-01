# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.capabilities

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

pod_spec1(container, image, capabilities) = out {
	out = {container: [{
		"name": "container1",
		"image": image,
		"securityContext": {"capabilities": {"add": capabilities}},
	}]}
}

pod_spec2(container, image) = out {
	out = {container: [{
		"name": "container1",
		"image": image,
	}]}
}

input_obj(review, allowedCaps) = out {
	out = {
		"parameters": {"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"], "allowedCapabilities": allowedCaps, "namespaceOnlyExemptImages": ["exemptNamespace/sample_image:v1.0.0"]},
		"review": review,
	}
}

test_container_has_one_disallowed_capability {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["SYS_TIME"]
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input

	count(results) == 1
}

test_container_has_list_of_disallowed_and_allowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "NET_BIND_SERVICE", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 1
}

test_container_has_list_of_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 1
}

test_container_has_no_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["NET_BIND_SERVICE"]
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_empty_capability_list_in_container {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := []
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_all_capabilities_allowed {
	allowedCaps := ["*"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod(pod_spec1("containers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_exempt_container_has_list_of_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod(pod_spec1("containers", "quay.io/kubevirt/virt-launcher:v0.58.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_exempt_image_within_namespace_has_list_of_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod2(pod_spec1("containers", "sample_image:v1.0.0", cap_list), "exemptNamespace"), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_unexempt_image_within_namespace_has_list_of_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod2(pod_spec1("containers", "unexempt_image:v1.0.0", cap_list), "exemptNamespace"), allowedCaps)
	results := violation with input as input
	count(results) == 1
}

test_exempt_image_outside_namespace_has_list_of_dissallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT"]
	input := input_obj(review_pod2(pod_spec1("containers", "sample_image:v1.0.0", cap_list), "unexemptNamespace"), allowedCaps)
	results := violation with input as input
	count(results) == 1
}

test_container_has_no_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["NET_BIND_SERVICE"]
	input := input_obj(review_pod(pod_spec1("initContainers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_container_has_no_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	cap_list := ["NET_BIND_SERVICE"]
	input := input_obj(review_pod(pod_spec1("ephemeralContainers", "sample_image:v1.0.0", cap_list)), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_container_has_no_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	input := input_obj(review_pod(pod_spec2("containers", "sample_image:v1.0.0")), allowedCaps)
	results := violation with input as input
	count(results) == 0
}

test_container_has_no_disallowed_capabilities {
	allowedCaps := ["NET_BIND_SERVICE"]
	input := input_obj(review_pod(pod_spec2("containers", "sample_image:v1.0.0")), allowedCaps)
	results := violation with input as input
	count(results) == 0
}
