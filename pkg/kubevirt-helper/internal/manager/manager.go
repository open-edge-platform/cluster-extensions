// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package manager

import (
	"context"

	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/k8swebhook"
	"github.com/open-edge-platform/orch-library/go/dazl"
)

var log = dazl.GetPackageLogger()

var newK8sWebhookServer = k8swebhook.NewServer

type Config struct {
	Port       int
	CertPath   string
	CertName   string
	KeyName    string
	MutatePath string
}

func NewManager(config Config) Manager {
	return &manager{
		config:        config,
		webhookServer: newK8sWebhookServer(config.Port, config.CertPath, config.CertName, config.KeyName, config.MutatePath),
	}
}

type Manager interface {
	Run()
}

type manager struct {
	config        Config
	webhookServer k8swebhook.Server
}

func (m *manager) Run() {
	log.Info("Starting KubeVirt Helper")

	ctx := context.Background()

	err := m.runWebhookServer(ctx)
	if err != nil {
		log.Fatal(err)
	}
}

func (m *manager) runWebhookServer(ctx context.Context) error {
	log.Infof("Starting Webhook Server on the port %d", m.config.Port)

	return m.webhookServer.Run(ctx)
}
