// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"

	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/manager"
	_ "github.com/open-edge-platform/orch-library/go/dazl/zap"
)

func main() {
	port := flag.Int("port", 8443, "Port number for webhook service")
	certPath := flag.String("certPath", "/opt/k8s-webhook-server/serving-certs/", "TLS key path for webhook service")
	certName := flag.String("certName", "tls.crt", "TLS cert file name")
	keyName := flag.String("keyName", "tls.key", "TLS key file name")
	mutatePath := flag.String("mutatePath", "/kubevirt-helper-mutate", "Webhook mutate path")
	flag.Parse()

	cfg := manager.Config{
		Port:       *port,
		CertPath:   *certPath,
		CertName:   *certName,
		KeyName:    *keyName,
		MutatePath: *mutatePath,
	}

	ready := make(chan bool)
	mgr := manager.NewManager(cfg)
	mgr.Run()
	<-ready
}
