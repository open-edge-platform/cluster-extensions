# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.hostpath

violation[{"msg": msg, "details": {}}] {
	c := input_containers[_]
	hpv := input_hostpath_volumes[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	has_hostpath_volume(c, hpv)
	msg := sprintf("The hostPath volume type is not allowed, pod: %v, container %v", [input.review.object.metadata.name, c.name])
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

input_hostpath_volumes[v] {
	v := input.review.object.spec.volumes[_]
	has_field(v, "hostPath")
}

has_hostpath_volume(container, volumes) {
	vmounts := container.volumeMounts[_]
	volume_name_match(vmounts, volumes)
}

volume_name_match(vmount, volume) {
	vmount.name == volume.name
}

###LIBRARY###

has_field(object, field) {
	object[field]
}

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
