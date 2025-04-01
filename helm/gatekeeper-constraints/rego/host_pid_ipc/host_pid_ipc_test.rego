# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package hostnamespace

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {"name": "my-pod"},
		"spec": pod_spec,
	}}
}

pod_spec(hostIPC, hostPID) = out {
	out = {
		"name": "container1",
		"hostIPC": hostIPC,
		"hostPID": hostPID,
	}
}

input_obj(review) = out {
	out = {"review": review}
}

test_has_hostIPC_and_hostPID_false {
	input := input_obj(review_pod(pod_spec(false, false)))
	results := violation with input as input
	count(results) == 0
}

test_has_hostIPC_and_hostPID_true {
	input := input_obj(review_pod(pod_spec(true, true)))
	results := violation with input as input
	count(results) == 1
}

test_has_hostIPC_true_hostPID_false {
	input := input_obj(review_pod(pod_spec(true, false)))
	results := violation with input as input
	count(results) == 1
}

test_has_hostIPC_false_hostPID_true {
	input := input_obj(review_pod(pod_spec(false, true)))
	results := violation with input as input
	count(results) == 1
}
