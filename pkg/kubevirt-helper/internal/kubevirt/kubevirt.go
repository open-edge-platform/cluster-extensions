// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package kubevirt

import (
	"context"
	"encoding/json"
	"fmt"
	"reflect"

	"github.com/open-edge-platform/orch-library/go/pkg/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
	kubevirtapiv1 "kubevirt.io/api/core/v1"
	"kubevirt.io/client-go/kubecli"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

func NewKubevirtHandler() Handler {
	return &kubevirtHandler{}
}

//go:generate mockery --name Handler --filename kubevirt_mock.go --structname MockHandler
type Handler interface {
	GetVMsFromAdmissionRequest(ctx context.Context, r admission.Request) (*kubevirtapiv1.VirtualMachine, *kubevirtapiv1.VirtualMachine, error)
	CompareVMSpec(ctx context.Context, vmNew *kubevirtapiv1.VirtualMachine, vmOld *kubevirtapiv1.VirtualMachine) (bool, bool, error)
	RestartVM(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error
	DeleteVMInstance(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error
	DeleteDV(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error
}

type kubevirtHandler struct {
}

func (k *kubevirtHandler) GetVMsFromAdmissionRequest(ctx context.Context, r admission.Request) (*kubevirtapiv1.VirtualMachine, *kubevirtapiv1.VirtualMachine, error) {
	select {
	case <-ctx.Done():
		return nil, nil, errors.NewCanceled("context canceled when comparing VM specs")
	default:
		uVMNew := unstructured.Unstructured{}
		err := json.Unmarshal(r.Object.Raw, &uVMNew)
		if err != nil {
			return nil, nil, err
		}

		vmNew := &kubevirtapiv1.VirtualMachine{}
		err = runtime.DefaultUnstructuredConverter.FromUnstructured(uVMNew.Object, vmNew)
		if err != nil {
			return nil, nil, err
		}

		uVMOld := unstructured.Unstructured{}
		err = json.Unmarshal(r.OldObject.Raw, &uVMOld)
		if err != nil {
			return nil, nil, err
		}

		vmOld := &kubevirtapiv1.VirtualMachine{}
		err = runtime.DefaultUnstructuredConverter.FromUnstructured(uVMOld.Object, vmOld)
		if err != nil {
			return nil, nil, err
		}

		return vmNew, vmOld, nil
	}
}

func (k *kubevirtHandler) CompareVMSpec(ctx context.Context, vmNew *kubevirtapiv1.VirtualMachine, vmOld *kubevirtapiv1.VirtualMachine) (bool, bool, error) {
	// editable fields in VM templates
	// objects[0].spec.template.spec.domain.cpu.sockets
	// objects[0].spec.template.spec.domain.cpu.cores
	// objects[0].spec.template.spec.domain.cpu.threads
	// objects[0].spec.template.spec.domain.resources.requests.memory

	dvSpecUpdate := false
	vmSpecUpdate := false

	select {
	case <-ctx.Done():
		return false, false, errors.NewCanceled("context canceled when comparing VM specs")
	default:
		if !reflect.DeepEqual(vmNew.Spec.Template, vmOld.Spec.Template) {
			vmSpecUpdate = true
		}
		// This assumes that there is at most only one datavolume associated with the old and new VM specs.
		if len(vmNew.Spec.DataVolumeTemplates) == 1 && len(vmOld.Spec.DataVolumeTemplates) == 1 {
			if *vmNew.Spec.DataVolumeTemplates[0].Spec.Source.Registry.URL != *vmOld.Spec.DataVolumeTemplates[0].Spec.Source.Registry.URL {
				dvSpecUpdate = true
			}
		}
	}

	return vmSpecUpdate, dvSpecUpdate, nil
}

func (k *kubevirtHandler) RestartVM(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error {
	client, err := kubecli.GetKubevirtClientFromRESTConfig(config.GetConfigOrDie())
	if err != nil {
		return err
	}

	return client.VirtualMachine(vm.Namespace).Restart(ctx, vm.Name, &kubevirtapiv1.RestartOptions{})
}

func (k *kubevirtHandler) DeleteVMInstance(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error {
	client, err := kubecli.GetKubevirtClientFromRESTConfig(config.GetConfigOrDie())
	if err != nil {
		return err
	}

	return client.VirtualMachineInstance(vm.Namespace).Delete(ctx, vm.Name, &metav1.DeleteOptions{})
}

func (k *kubevirtHandler) DeleteDV(ctx context.Context, vm *kubevirtapiv1.VirtualMachine) error {
	dynamicClient, err := dynamic.NewForConfig(config.GetConfigOrDie())
	if err != nil {
		return fmt.Errorf("failed to get config: %w", err)
	}

	if len(vm.Spec.DataVolumeTemplates) == 0 {
		return fmt.Errorf("no DataVolumeTemplates found in the VM spec %s in namespace %s", vm.Name, vm.Namespace)
	}

	namespace := vm.Namespace
	dataVolumeName := vm.Spec.DataVolumeTemplates[0].Name

	dataVolumeGVR := schema.GroupVersionResource{
		Group:    "cdi.kubevirt.io",
		Version:  "v1beta1",
		Resource: "datavolumes",
	}

	return dynamicClient.Resource(dataVolumeGVR).Namespace(namespace).Delete(ctx, dataVolumeName, metav1.DeleteOptions{})
}
