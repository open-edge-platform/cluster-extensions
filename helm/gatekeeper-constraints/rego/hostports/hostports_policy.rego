# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostports

violation[{"msg": msg, "details": {}}] {
	c := input_containers[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	allow_hostport(c)
	msg := sprintf("The hostPort settings are not valid, container %v, pod %v. Allowed values: %v", [c.name, input.review.object.metadata.name, input.parameters])
}

allow_hostport(o) {
	not input.parameters.allowHostPort
	a := o.ports[_]
	a.hostPort
}

allow_hostport(o) {
	input.parameters.allowHostPort
	hostPort := o.ports[_].hostPort
	hostPort < input.parameters.min
}

allow_hostport(o) {
	input.parameters.allowHostPort
	hostPort := o.ports[_].hostPort
	hostPort > input.parameters.max
}

input_containers[c] {
	c := input.review.object.spec.containers[_]
	not is_exempt(c)
}

input_containers[c] {
	c := input.review.object.spec.initContainers[_]
	not is_exempt(c)
}

input_containers[c] {
	c := input.review.object.spec.ephemeralContainers[_]
	not is_exempt(c)
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
