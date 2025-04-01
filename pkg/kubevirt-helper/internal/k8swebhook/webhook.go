// SPDX-FileCopyrightText: (C) 2023 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package k8swebhook

import (
	"context"
	"crypto/tls"
	"fmt"
	"net/http"

	apierrors "k8s.io/apimachinery/pkg/api/errors"

	"github.com/open-edge-platform/cluster-extensions/kubevirt-helper/internal/kubevirt"
	"github.com/open-edge-platform/orch-library/go/dazl"
	admissionv1 "k8s.io/api/admission/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
	k8smgr "sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

var log = dazl.GetPackageLogger()

var newKubevirtHandler = kubevirt.NewKubevirtHandler
var newKubernetesManager = k8smgr.New
var getKubeconfigOrDie = config.GetConfigOrDie

func NewServer(port int, certPath, certName, keyName, mutatePath string) Server {
	return &server{
		port:       port,
		certPath:   certPath,
		certName:   certName,
		keyName:    keyName,
		mutatePath: mutatePath,
	}
}

//go:generate mockery --name Server --filename k8swebhookserver_mock.go --structname MockServer
//go:generate mockery --name Manager --filename k8s_manager_mock.go --structname MockManager --srcpkg=sigs.k8s.io/controller-runtime/pkg/manager
type Server interface {
	Run(ctx context.Context) error
}

type server struct {
	port       int
	certPath   string
	certName   string
	keyName    string
	mutatePath string
}

func (s *server) Run(ctx context.Context) error {
	log.Info("Webhook server is running")
	mgr, err := newKubernetesManager(getKubeconfigOrDie(), k8smgr.Options{})
	if err != nil {
		return err
	}

	ws := mgr.GetWebhookServer()
	ws.TLSMinVersion = "1.3"
	ws.TLSOpts = []func(*tls.Config){
		func(cfg *tls.Config) {
			cfg.CipherSuites = []uint16{
				tls.TLS_AES_128_GCM_SHA256,
				tls.TLS_AES_256_GCM_SHA384,
				tls.TLS_CHACHA20_POLY1305_SHA256,
			}
			cfg.MinVersion = tls.VersionTLS13
		},
	}
	ws.Port = s.port
	ws.CertDir = s.certPath
	ws.CertName = s.certName
	ws.KeyName = s.keyName

	mgr.GetWebhookServer().Register(s.mutatePath, &webhook.Admission{
		Handler: &VMMutator{
			KubeVirtHandler: newKubevirtHandler(),
		},
		RecoverPanic:    true,
		WithContextFunc: nil,
	})

	return mgr.GetWebhookServer().Start(ctx)
}

type VMMutator struct {
	KubeVirtHandler kubevirt.Handler
}

func (v *VMMutator) Handle(ctx context.Context, request admission.Request) admission.Response {
	vmNew, vmOld, err := v.KubeVirtHandler.GetVMsFromAdmissionRequest(ctx, request)
	if err != nil {
		return admission.Response{
			AdmissionResponse: admissionv1.AdmissionResponse{
				Allowed: false,
				Result: &metav1.Status{
					Message: fmt.Sprintf("failed to get old and new VM specs; err - %s", err.Error()),
					Code:    http.StatusForbidden,
				},
			},
		}
	}

	// if vm object status has "statusChangeRequests", it is duplicated event captured
	if len(vmNew.Status.StateChangeRequests) > 0 {
		log.Debugf("status change requests for VM %s in namespace %s: %+v", vmNew.Name, vmNew.Name, vmNew.Status.StateChangeRequests)
		log.Debugf("Duplicated VM %s spec update event in namespace %s is captured but already processed- ignoring", vmNew.Name, vmNew.Namespace)
		return admission.Response{
			Patches: nil,
			AdmissionResponse: admissionv1.AdmissionResponse{
				Allowed: true,
				Result: &metav1.Status{
					Code: http.StatusOK,
				},
			},
		}
	}

	log.Infof("VM %s spec update event in namespace %s is captured", vmNew.Name, vmNew.Namespace)
	log.Debugf("VM Spec New %+v", string(request.Object.Raw))
	log.Debugf("VMI Spec Old %+v", string(request.OldObject.Raw))

	vmSpecUpdate, dvSpecUpdate, err := v.KubeVirtHandler.CompareVMSpec(ctx, vmNew, vmOld)
	if err != nil {
		return admission.Response{
			AdmissionResponse: admissionv1.AdmissionResponse{
				Allowed: false,
				Result: &metav1.Status{
					Message: fmt.Sprintf("failed to compare VM spec; err - %s", err.Error()),
					Code:    http.StatusForbidden,
				},
			},
		}
	}

	if !vmSpecUpdate && !dvSpecUpdate {
		log.Infof("VM %s spec update event in namespace %s does not need to be restarted - no editable spec changed", vmNew.Name, vmNew.Namespace)
		return admission.Response{
			Patches: nil,
			AdmissionResponse: admissionv1.AdmissionResponse{
				Allowed: true,
				Result: &metav1.Status{
					Code: http.StatusOK,
				},
			},
		}
	}

	if dvSpecUpdate {
		// If the datavolume spec changes, then the datavolume and VM need to be re-created.
		log.Infof("DV %s spec update event for VM %s spec in namespace %s needs DV and VM to be re-created", vmNew.Spec.DataVolumeTemplates[0].Name, vmNew.Name, vmNew.Namespace)
		err = v.KubeVirtHandler.DeleteDV(ctx, vmNew)
		if err != nil && !apierrors.IsNotFound(err) {
			log.Infof("failed to delete datavolume in VM %s in namespace %s: %w", vmNew.Name, vmNew.Namespace, err)
			return admission.Response{
				AdmissionResponse: admissionv1.AdmissionResponse{
					Allowed: false,
					Result: &metav1.Status{
						Message: fmt.Sprintf("failed to delete DV in VM; err - %s", err.Error()),
						Code:    http.StatusForbidden,
					},
				},
			}
		}

		err = v.KubeVirtHandler.DeleteVMInstance(ctx, vmNew)
		if err != nil && !apierrors.IsNotFound(err) {
			log.Infof("failed to delete VM Instance for VM %s in namespace %s: %w", vmNew.Name, vmNew.Namespace, err)
			return admission.Response{
				AdmissionResponse: admissionv1.AdmissionResponse{
					Allowed: false,
					Result: &metav1.Status{
						Message: fmt.Sprintf("failed to delete VMI; err - %s", err.Error()),
						Code:    http.StatusForbidden,
					},
				},
			}
		}
	} else if vmSpecUpdate {
		// If just the VM spec has changed without any change in the datavolume spec,
		// then a VM restart is sufficient.
		log.Infof("VM %s spec update event in namespace %s needs VM restart; triggering VM restart", vmNew.Name, vmNew.Namespace)
		err = v.KubeVirtHandler.RestartVM(ctx, vmNew)
		if err != nil {
			log.Infof("failed to restart VM %s in namespace %s: %w", vmNew.Name, vmNew.Namespace, err)
			return admission.Response{
				AdmissionResponse: admissionv1.AdmissionResponse{
					Allowed: false,
					Result: &metav1.Status{
						Message: fmt.Sprintf("failed to restart VM; err - %s", err.Error()),
						Code:    http.StatusForbidden,
					},
				},
			}
		}
	}

	log.Infof("VM %s in namespace %s restart is triggered successfully", vmNew.Name, vmNew.Namespace)
	return admission.Response{
		Patches: nil,
		AdmissionResponse: admissionv1.AdmissionResponse{
			Allowed: true,
			Result: &metav1.Status{
				Code: http.StatusOK,
			},
		},
	}
}
