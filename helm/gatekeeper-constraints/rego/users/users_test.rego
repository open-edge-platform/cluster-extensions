# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.users

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

pod_spec1(containers, image, user, group, fsGroup, supGroups) = out {
	out = {
		"securityContext": {
			"runAsUser": user,
			"runAsGroup": group,
			"fsGroup": fsGroup,
			"supplementalGroups": supGroups,
		},
		containers: [{
			"name": "container1",
			"image": image,
			"securityContext": {"allowPrivilegeEscalation": false},
		}],
	}
}

pod_spec2(containers, image) = out {
	out = {containers: [{
		"name": "container1",
		"image": image,
	}]}
}

pod_spec3(containers, image, podUser, podGroup, fsGroup, supGroups, contUser, contGroups) = out {
	out = {
		"securityContext": {
			"runAsUser": podUser,
			"runAsGroup": podGroup,
			"fsGroup": fsGroup,
			"supplementalGroups": supGroups,
		},
		containers: [{
			"name": "container1",
			"image": image,
			"securityContext": {
				"runAsUser": contUser,
				"runAsGroup": contGroups,
			},
		}],
	}
}

pod_spec4(containers, image, user, group) = out {
	out = {containers: [{
		"name": "container1",
		"image": image,
		"securityContext": {
			"runAsUser": user,
			"runAsGroup": group,
		},
	}]}
}

pod_spec5(containers, image, podUser, podGroup, fsGroup, supGroups, contUser, contGroups) = out {
	out = {
		"securityContext": {
			"runAsUser": podUser,
			"runAsGroup": podGroup,
			"fsGroup": fsGroup,
			"supplementalGroups": supGroups,
		},
		containers: [
			{
				"name": "container1",
				"image": image,
				"securityContext": {
					"runAsUser": contUser,
					"runAsGroup": contGroups,
				},
			},
			{
				"name": "container1",
				"image": image,
			},
		],
	}
}

input_obj(review) = out {
	out = {
		"parameters": {
			"exemptImages": ["quay.io/kubevirt/virt-launcher:v0.58.0"],
			"runAsUser": {"ranges": [{"min": 100, "max": 2000}]},
			"runAsGroup": {"ranges": [{"min": 100, "max": 2000}]},
			"fsGroup": {"ranges": [{"min": 100, "max": 2000}]},
			"supplementalGroups": {"ranges": [{"min": 1000, "max": 200}, {"min": 1000, "max": 2000}]},
			"namespaceOnlyExemptImages": ["exemptNamespace/sample-image:v1.0.0"],
		},
		"review": review,
	}
}

test_no_root_users_on_pod_level {
	input := input_obj(review_pod(pod_spec1("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000])))
	results := violation with input as input

	count(results) == 0
}

test_no_root_users_on_pod_and_container_levels {
	input := input_obj(review_pod(pod_spec3("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000], 1000, 1000)))
	results := violation with input as input

	count(results) == 0
}

test_no_root_users_on_container_on_container_level {
	input := input_obj(review_pod(pod_spec4("containers", "sample-image:v1.0.0", 1000, 1000)))
	results := violation with input as input

	count(results) == 0
}

test_no_security_context_on_pod_container_level {
	input := input_obj(review_pod(pod_spec2("containers", "sample-image:v1.0.0")))
	results := violation with input as input

	count(results) == 0
}

test_root_user_on_container_level {
	input := input_obj(review_pod(pod_spec4("containers", "sample-image:v1.0.0", 0, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_group_on_container_level {
	input := input_obj(review_pod(pod_spec4("containers", "sample-image:v1.0.0", 1000, 0)))
	results := violation with input as input

	count(results) == 1
}

test_root_user_on_pod_level {
	input := input_obj(review_pod(pod_spec1("containers", "sample-image:v1.0.0", 0, 1000, 1000, [1000, 2000])))
	results := violation with input as input

	count(results) == 1
}

test_root_group_on_pod_level_no_root_users_on_container_level {
	input := input_obj(review_pod(pod_spec3("containers", "sample-image:v1.0.0", 1000, 0, 1000, [1000, 2000], 1000, 1000)))
	results := violation with input as input

	count(results) == 0
}

test_root_fsgroup_on_pod_level_no_root_users_on_container_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 0, [1000, 2000], 1000, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_supgroup_on_pod_level_no_root_users_on_container_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [0, 2000], 1000, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_supgroup_on_pod_level_no_root_users_on_container_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [200, 2001], 1000, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_supgroup_on_pod_level_no_root_users_on_container_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [200, 2001], 1000, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_user_on_container_level_no_root_users_on_pod_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000], 0, 1000)))
	results := violation with input as input

	count(results) == 1
}

test_root_group_on_container_level_no_root_users_on_pod_level {
	input := input_obj(review_pod(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000], 1000, 0)))
	results := violation with input as input

	count(results) == 1
}

test_exempt_image_within_namespace_no_root_users_on_pod_level {
	input := input_obj(review_pod1(pod_spec1("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000]), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_root_group_on_container_level_no_root_users_on_pod_level {
	input := input_obj(review_pod1(pod_spec5("containers", "sample-image:v1.0.0", 1000, 1000, 1000, [1000, 2000], 1000, 0), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_root_user_on_container_level {
	input := input_obj(review_pod1(pod_spec4("containers", "sample-image:v1.0.0", 0, 1000), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}

test_exempt_image_within_namespace_root_group_on_container_level {
	input := input_obj(review_pod1(pod_spec4("containers", "sample-image:v1.0.0", 1000, 0), "exemptNamespace"))
	results := violation with input as input

	count(results) == 0
}
