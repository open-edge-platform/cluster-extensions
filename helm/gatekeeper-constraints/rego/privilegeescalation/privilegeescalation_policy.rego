# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.privilegeescalation

violation[{"msg": msg, "details": {}}] {
	c := input_containers[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	disallow_privilege_escalation(c)
	msg := sprintf("Privilege escalation container is not allowed: %v", [c.name])
}

disallow_privilege_escalation(c) {
	c.securityContext.allowPrivilegeEscalation == true
}

input_containers[c] {
	c := input.review.object.spec.containers[_]
}

input_containers[c] {
	c := input.review.object.spec.initContainers[_]
}

input_containers[c] {
	c := input.review.object.spec.ephemeralContainers[_]
}

###LIBRARY###

is_exempt(container) {
	exempt_images := object.get(object.get(input, "parameters", {}), "exemptImages", [])
	img := container.image
	exemption := exempt_images[_]
	_matches_exemption(img, exemption)
}

is_exempt_within_namespace(container) {
	exemptions := object.get(object.get(input, "parameters", {}), "namespaceOnlyExemptImages", [])
	nsimg := concat("/", [input.review.object.metadata.namespace, container.image])
	exemption := exemptions[_]
	_matches_exemption(nsimg, exemption)
}

_matches_exemption(img, exemption) {
	not endswith(exemption, "*")
	exemption == img
}

_matches_exemption(img, exemption) {
	endswith(exemption, "*")
	prefix := trim_suffix(exemption, "*")
	startswith(img, prefix)
}
