// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package manager

import (
	"context"
	"testing"

	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/k8swebhook"
	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/k8swebhook/mocks"
	"github.com/open-edge-platform/orch-library/go/pkg/errors"
	"github.com/stretchr/testify/assert"
)

var (
	testCfg = Config{
		Port:       80,
		CertPath:   "",
		CertName:   "",
		KeyName:    "",
		MutatePath: "",
	}
)

func TestNewManager(t *testing.T) {
	mgr := NewManager(testCfg)
	assert.NotNil(t, mgr)
}

func TestManager_Run(t *testing.T) {
	origNewK8sWebhookServer := newK8sWebhookServer
	defer func() {
		newK8sWebhookServer = origNewK8sWebhookServer
	}()
	newK8sWebhookServer = func(port int, certPath, certName, keyName, mutatePath string) k8swebhook.Server {
		s := mocks.NewMockServer(t)
		s.On("Run", context.Background()).Return(errors.NewCanceled(""))
		return s
	}

	mgr := NewManager(testCfg)
	assert.NotNil(t, mgr)

	mgr.Run()
}
