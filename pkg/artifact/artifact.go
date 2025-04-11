// SPDX-FileCopyrightText: (C) 2025 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0

package artifact

import "fmt"

type KeyProvider interface {
	comparable
	Key() string
}

type DeploymentPackage struct {
	Description       string `yaml:"description,omitempty"`
	Registry          string `yaml:"registry"`
	Version           string `yaml:"version"`
	DeploymentPackage string `yaml:"dpkg"`
}

type AllAppTargetCluster struct {
	Key string `yaml:"key"`
	Val string `yaml:"val"`
}
type DeploymentList struct {
	DPName               string                 `yaml:"dpName"`
	DPProfileName        string                 `yaml:"dpProfileName"`
	DPVersion            string                 `yaml:"dpVersion"`
	DisplayName          string                 `yaml:"displayName"`
	AllAppTargetClusters []*AllAppTargetCluster `yaml:"allAppTargetClusters"`
}

func (a DeploymentPackage) Key() string {
	return fmt.Sprintf("%s#%s:%s", a.Registry, a.DeploymentPackage, a.Version)
}
func (a DeploymentList) Key() string {
	return fmt.Sprintf("%s#%s:%s", a.DPName, a.DPProfileName, a.DPVersion)
}
