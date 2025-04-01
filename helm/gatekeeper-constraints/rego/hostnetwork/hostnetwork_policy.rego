# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostnetwork

violation[{"msg": msg, "details": {}}] {
	input_share_hostnetwork(input.review.object)
	msg := sprintf("HostNetwork is not allowed, pod: %v.", [input.review.object.metadata.name])
}

input_share_hostnetwork(o) {
	o.spec.hostNetwork == true
}
