# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostnetwork

import data.rego.libs.exempt_container.is_exempt

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {"name": "my-pod"},
		"spec": pod_spec,
	}}
}

pod_spec(hostnetwork) = out {
	out = {
		"name": "container1",
		"hostNetwork": hostnetwork,
	}
}

input_obj(review) = out {
	out = {"review": review}
}

test_has_hostnetwork_as_false {
	input := input_obj(review_pod(pod_spec(false)))
	results := violation with input as input
	count(results) == 0
}

test_has_hostnetwork_as_true {
	input := input_obj(review_pod(pod_spec(true)))
	results := violation with input as input
	count(results) == 1
}
