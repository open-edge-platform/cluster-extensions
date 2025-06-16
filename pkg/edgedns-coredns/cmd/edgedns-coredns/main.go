// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"github.com/coredns/coredns/core/dnsserver"
	_ "github.com/coredns/coredns/core/plugin"
	"github.com/coredns/coredns/coremain"

	_ "github.com/coredns/rrl/plugins/rrl"
)

// test
func init() {
	dnsserver.Directives = append([]string{"rrl"}, dnsserver.Directives...)
}

func main() {
	coremain.Run()
}
