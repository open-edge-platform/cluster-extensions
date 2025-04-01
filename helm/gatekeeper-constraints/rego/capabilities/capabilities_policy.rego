# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.capabilities

violation[{"msg": msg}] {
	c := input_containers[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	has_disallowed_capabilities(c)
	msg := sprintf("c <%v> has a disallowed capability. Allowed capabilities are %v", [c.name, get_default(input.parameters, "allowedCapabilities", "NONE")])
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

has_disallowed_capabilities(container) {
	allowed := {cap | cap := lower(input.parameters.allowedCapabilities[_])}
	not allowed["*"]
	capabilities := {cap | cap := lower(container.securityContext.capabilities.add[_])}

	count(capabilities - allowed) > 0
}

get_default(obj, param, _default) = out {
	out = obj[param]
}

get_default(obj, param, _default) = out {
	not obj[param]
	not obj[param] == false
	out = _default
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
