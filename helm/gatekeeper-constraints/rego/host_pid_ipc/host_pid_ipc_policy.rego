# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package hostnamespace

violation[{"msg": msg, "details": {}}] {
	input_share_hostnamespace(input.review.object)
	msg := sprintf("Sharing the host namespace is not allowed: %v", [input.review.object.metadata.name])
}

input_share_hostnamespace(o) {
	o.spec.hostPID
}

input_share_hostnamespace(o) {
	o.spec.hostIPC
}
