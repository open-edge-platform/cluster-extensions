// SPDX-FileCopyrightText: (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"testing"

	"github.com/coredns/coredns/core/dnsserver"
)

func TestAddPlugin(t *testing.T) {
	present := false
	for _, v := range dnsserver.Directives {
		if v == "rrl" {
			present = true
			break
		}
	}
	if !present {
		t.Error("rrl plugin is not present in configuration")
	}
}
