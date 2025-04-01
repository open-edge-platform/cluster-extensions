# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
package rego.readonlyrootfilesystem

violation[{"msg": msg, "details": {}}] {
	c := input_containers[_]
	not is_exempt(c)
	not is_exempt_within_namespace(c)
	not is_exempt_container_name(c)
	input_read_only_root_fs(c)
	msg := sprintf("only read-only root filesystem container is allowed: %v", [c.name])
}

input_read_only_root_fs(c) {
	not has_field(c, "securityContext")
}

input_read_only_root_fs(c) {
	not c.securityContext.readOnlyRootFilesystem == true
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

# has_field returns whether an object has a field
has_field(object, field) {
	object[field]
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

is_exempt_container_name(container) {
	exempt_container_names := object.get(object.get(input, "parameters", {}), "exemptContainerNames", [])
	container_name := container.name
	exemption := exempt_container_names[_]
	container_name == exemption
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
