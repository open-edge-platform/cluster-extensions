// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package k8swebhook

import (
	"context"
	"net/http"
	"reflect"
	"testing"

	"github.com/golang/mock/gomock"
	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/k8swebhook/mocks"
	kubevirtmocks "github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/kubevirt/mocks"
	"github.com/open-edge-platform/orch-library/go/pkg/errors"
	"github.com/stretchr/testify/assert"
	"github.com/undefinedlabs/go-mpatch"
	"k8s.io/client-go/rest"
	kubevirtapiv1 "kubevirt.io/api/core/v1"
	k8smgr "sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

func unpatchAll(list []*mpatch.Patch) error {
	for _, p := range list {
		err := p.Unpatch()
		if err != nil {
			return err
		}
	}
	return nil
}

func TestNewServer(t *testing.T) {
	s := NewServer(0, "", "", "", "")
	assert.NotNil(t, s)
}

func TestServer_Run(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	origGetKubeconfigOrDie := getKubeconfigOrDie
	defer func() {
		getKubeconfigOrDie = origGetKubeconfigOrDie
	}()
	getKubeconfigOrDie = func() *rest.Config {
		return &rest.Config{}
	}

	origNewKubernetesManager := newKubernetesManager
	defer func() {
		newKubernetesManager = origNewKubernetesManager
	}()

	newKubernetesManager = func(config *rest.Config, options k8smgr.Options) (k8smgr.Manager, error) {
		m := mocks.NewMockManager(t)
		m.On("GetWebhookServer").Return(&webhook.Server{})
		return m, nil
	}

	patch := func(ctrl *gomock.Controller) []*mpatch.Patch {
		var server *webhook.Server
		f1, err := mpatch.PatchInstanceMethodByName(reflect.TypeOf(server), "Start", func(s *webhook.Server, ctx context.Context) error {
			return nil
		})
		if err != nil {
			// Monkey patch not supported on Arm64 on MacOS - gives permission denied
			t.Errorf("patch error with gomock %s", err.Error())
		}
		f2, err := mpatch.PatchInstanceMethodByName(reflect.TypeOf(server), "Register", func(s *webhook.Server, path string, hook http.Handler) {})
		if err != nil {
			t.Errorf("patch error with gomock %s", err.Error())
		}
		return []*mpatch.Patch{f1, f2}
	}

	s := NewServer(0, "", "", "", "")
	assert.NotNil(t, s)

	pList := patch(ctrl)
	err := s.Run(context.Background())
	assert.NoError(t, err)
	err = unpatchAll(pList)
	if err != nil {
		t.Error(err)
	}
}

func TestServer_Run_Error_GetConfig(t *testing.T) {
	origGetKubeconfigOrDie := getKubeconfigOrDie
	defer func() {
		getKubeconfigOrDie = origGetKubeconfigOrDie
	}()
	getKubeconfigOrDie = func() *rest.Config {
		return &rest.Config{}
	}

	origNewKubernetesManager := newKubernetesManager
	defer func() {
		newKubernetesManager = origNewKubernetesManager
	}()

	newKubernetesManager = func(config *rest.Config, options k8smgr.Options) (k8smgr.Manager, error) {
		return nil, errors.NewInvalid("test")
	}

	s := NewServer(0, "", "", "", "")
	assert.NotNil(t, s)

	err := s.Run(context.Background())
	assert.Error(t, err)
}

func TestVMMutator_Handle(t *testing.T) {
	req := admission.Request{}
	vmNew := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	vmOld := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).
		Return(vmNew, vmOld, nil)
	h.On("CompareVMSpec", context.Background(), vmNew, vmOld).
		Return(true, false, nil)
	h.On("RestartVM", context.Background(), vmNew).
		Return(nil)

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, true, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusOK, int(resp.AdmissionResponse.Result.Code))
}

func TestVMMutator_Handle_Error_GetVmsFromAdmissionRequest(t *testing.T) {
	req := admission.Request{}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).Return(nil, nil, errors.NewNotSupported("test"))

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, false, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusForbidden, int(resp.AdmissionResponse.Result.Code))
}

func TestVMMutator_Handle_MultipleStateChangeRequests(t *testing.T) {
	req := admission.Request{}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).
		Return(&kubevirtapiv1.VirtualMachine{
			Status: kubevirtapiv1.VirtualMachineStatus{
				StateChangeRequests: []kubevirtapiv1.VirtualMachineStateChangeRequest{
					{Data: map[string]string{"1": "2"}},
					{Data: map[string]string{"3": "4"}}},
			},
		}, nil, nil)

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, true, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusOK, int(resp.AdmissionResponse.Result.Code))
}

func TestVMMutator_Handle_FailedCompareVMSpec(t *testing.T) {
	req := admission.Request{}
	vmNew := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	vmOld := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).
		Return(vmNew, vmOld, nil)
	h.On("CompareVMSpec", context.Background(), vmNew, vmOld).
		Return(true, false, errors.NewNotSupported("test"))

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, false, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusForbidden, int(resp.AdmissionResponse.Result.Code))
}

func TestVMMutator_Handle_VMSpecUnchanged(t *testing.T) {
	req := admission.Request{}
	vmNew := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	vmOld := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).
		Return(vmNew, vmOld, nil)
	h.On("CompareVMSpec", context.Background(), vmNew, vmOld).
		Return(false, false, nil)

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, true, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusOK, int(resp.AdmissionResponse.Result.Code))
}

func TestVMMutator_Handle_VMRestartFailed(t *testing.T) {
	req := admission.Request{}
	vmNew := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	vmOld := &kubevirtapiv1.VirtualMachine{
		Status: kubevirtapiv1.VirtualMachineStatus{},
	}
	h := kubevirtmocks.NewMockHandler(t)
	h.On("GetVMsFromAdmissionRequest", context.Background(), req).
		Return(vmNew, vmOld, nil)
	h.On("CompareVMSpec", context.Background(), vmNew, vmOld).
		Return(true, false, nil)
	h.On("RestartVM", context.Background(), vmNew).
		Return(errors.NewNotSupported("test"))

	m := VMMutator{
		KubeVirtHandler: h,
	}
	resp := m.Handle(context.Background(), req)
	assert.NotNil(t, resp)
	assert.Equal(t, false, resp.AdmissionResponse.Allowed)
	assert.Equal(t, http.StatusForbidden, int(resp.AdmissionResponse.Result.Code))
}
