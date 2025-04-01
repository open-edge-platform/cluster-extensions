# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.sysctls

review_pod(pod_spec) = out {
	out = {"object": {
		"kind": "Pod",
		"apiVersion": "v1",
		"metadata": {"name": "my-pod"},
		"spec": pod_spec,
	}}
}

pod_spec(sysctl) = out {
	out = {"securityContext": sysctl}
}

input_obj(review, allowedSysctls) = out {
	out = {
		"parameters": {"allowedSysctls": allowedSysctls},
		"review": review,
	}
}

test_container_has_one_disallowed_sysctl {
	allowedSysctls := ["kernel.shm_rmid_forced", "net.ipv4.ip_local_port_range"]
	input := input_obj(review_pod(pod_spec({"sysctls": [{"name": "kernel.shm_rmid_forced"}, {"name": "net.ipv4.ip_unprivileged_port_start"}]})), allowedSysctls)
	results := violation with input as input

	count(results) == 1
}

test_container_has_no_disallowed_sysctl {
	allowedSysctls := ["kernel.shm_rmid_forced", "net.ipv4.ip_local_port_range"]
	input := input_obj(review_pod(pod_spec({"sysctls": [{"name": "kernel.shm_rmid_forced"}, {"name": "net.ipv4.ip_local_port_range"}]})), allowedSysctls)
	results := violation with input as input

	count(results) == 0
}

test_container_has_several_disallowed_sysctl {
	allowedSysctls := ["kernel.shm_rmid_forced", "net.ipv4.ip_local_port_range"]
	input := input_obj(review_pod(pod_spec({"sysctls": [{"name": "net.ipv4.ip_unprivileged_port_start"}, {"name": "net.ipv4.ping_group_range"}, {"name": "net.ipv4.tcp_syncookies"}, {"name": "net.ipv4.ip_local_port_range"}]})), allowedSysctls)
	results := violation with input as input

	count(results) == 3
}

test_empty_sysctls_in_container {
	allowedSysctls := ["kernel.shm_rmid_forced", "net.ipv4.ip_local_port_range"]
	input := input_obj(review_pod(pod_spec({"sysctls": []})), allowedSysctls)
	results := violation with input as input

	count(results) == 0
}
