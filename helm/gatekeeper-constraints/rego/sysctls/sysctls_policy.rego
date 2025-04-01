# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.sysctls

violation[{"msg": msg, "details": {}}] {
	sysctl := input.review.object.spec.securityContext.sysctls[_].name
	not allowed_sysctl(sysctl)
	msg := sprintf("The sysctl %v is not allowed, pod: %v. Allowed sysctls: %v", [sysctl, input.review.object.metadata.name, input.parameters.allowedSysctls])
}

# * may be used to allow all sysctls
allowed_sysctl(sysctl) {
	input.parameters.allowedSysctls[_] == "*"
}

allowed_sysctl(sysctl) {
	input.parameters.allowedSysctls[_] == sysctl
}

allowed_sysctl(sysctl) {
	allowed := input.parameters.allowedSysctls[_]
	endswith(allowed, "*")
	startswith(sysctl, trim_suffix(allowed, "*"))
}
