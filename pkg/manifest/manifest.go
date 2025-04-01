// SPDX-FileCopyrightText: (C) 2025 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0

package manifest

import (
	"fmt"
	"os"

	"github.com/open-edge-platform/cluster-extensions/pkg/artifact"
	"gopkg.in/yaml.v3"
)

const version = "1.0.1"

// Manifest type describes what artifacts constitutes the release
type Manifest struct {
	Metadata Metadata `yaml:"metadata"`
	LPKE     LPKE     `yaml:"lpke"`
}

// Meta type contains additional information useful for tools processing manifest file
type Metadata struct {
	SchemaVersion string `yaml:"schemaVersion"`
	Release       string `yaml:"release"`
}

type LPKE struct {
	DeploymentPackages []artifact.DeploymentPackage `yaml:"deploymentPackages"`
	DeploymentList     []artifact.DeploymentList    `yaml:"deploymentList"`
}

// Creates in-memory manifest and fills it with values from .yaml file if path is provided
func New(inputPath string) (*Manifest, error) {
	m := Manifest{}
	m.Metadata.SchemaVersion = version

	if inputPath != "" {
		data, err := os.ReadFile(inputPath)
		if err != nil {
			return nil, fmt.Errorf("file read failed: %v", err)
		}

		err = yaml.Unmarshal(data, &m)
		if err != nil {
			return nil, fmt.Errorf("deserialization failed: %v", err)
		}
	}
	return &m, nil
}

// Saves in-memory manifest to .yaml file
func (m *Manifest) Save(outputPath string) error {
	f, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("file creation failed: %v", err)
	}
	defer f.Close()

	_, err = f.WriteString("# SPDX-FileCopyrightText: (C) 2023 Intel Corporation\n")
	if err != nil {
		return fmt.Errorf("file update failed: %v", err)
	}
	_, err = f.WriteString("# SPDX" + "-License-Identifier: Apache-2.0\n")
	if err != nil {
		return fmt.Errorf("file update failed: %v", err)
	}

	enc := yaml.NewEncoder(f)
	enc.SetIndent(2)
	err = enc.Encode(m)
	if err != nil {
		return fmt.Errorf("serialization failed: %v", err)
	}

	return nil
}

// Check manifest for syntactic correctness
func (m *Manifest) Validate() error {
	return nil
}

func (m *Manifest) GetDeploymentPackages() []artifact.DeploymentPackage {
	dps := []artifact.DeploymentPackage{}

	dps = append(dps, m.LPKE.DeploymentPackages...)

	return dps
}

func (m *Manifest) GetDeploymentList() []artifact.DeploymentList {
	deps := []artifact.DeploymentList{}

	deps = append(deps, m.LPKE.DeploymentList...)

	return deps
}
