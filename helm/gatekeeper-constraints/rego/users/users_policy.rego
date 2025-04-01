# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.users

violation[{"msg": msg}] {
	fields := ["runAsUser", "runAsGroup", "fsGroup", "supplementalGroups"]
	field := fields[_]
	c := input_containers[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	param := input.parameters[field]
	msg := get_violation(field, param, c)
}

get_violation(field, param, c) = msg {
	provided_value := get_field_value(field, c, input.review)
	not is_array(provided_value)
	not accept_value(provided_value, param.ranges)
	msg := sprintf("Container %v is attempting to run with %v set to %v.", [c.name, field, provided_value])
}

get_violation(field, param, c) = msg {
	array_value := get_field_value(field, c, input.review)
	is_array(array_value)
	provided_value := array_value[_]
	not accept_value(provided_value, param.ranges)
	msg := sprintf("Container %v is attempting to run with %v set to %v.", [c.name, field, array_value])
}

accept_value(provided_value, ranges) = res {
	res := is_in_range(provided_value, ranges)
}

is_in_range(val, ranges) = res {
	matching := {1 | val >= ranges[j].min; val <= ranges[j].max}
	res := count(matching) > 0
}

# If container level is provided, that takes precedence
get_field_value(field, c, review) = out {
	container_value := get_seccontext_field(field, c)
	out := container_value
}

# If no container level exists, use pod level
get_field_value(field, c, review) = out {
	not has_seccontext_field(field, c)
	review.object.kind == "Pod"
	pod_value := get_seccontext_field(field, review.object.spec)
	out := pod_value
}

# Helper Functions
has_seccontext_field(field, obj) {
	get_seccontext_field(field, obj)
}

has_seccontext_field(field, obj) {
	get_seccontext_field(field, obj) == false
}

get_seccontext_field(field, obj) = out {
	out = obj.securityContext[field]
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
