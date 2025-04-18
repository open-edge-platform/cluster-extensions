// SPDX-FileCopyrightText: (C) 2025 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"bytes"
	"errors"
	"flag"
	"os"
	"slices"
	"strings"

	"github.com/open-edge-platform/cluster-extensions/pkg/manifest"
	"github.com/sirupsen/logrus"
	"gopkg.in/yaml.v3"
)

var (
	manifestFilePath      = flag.String("manifest", "", "Path to the manifest file")
	deploymentPackagePath = flag.String("deployment-packages", "", "Path to the deployment packages")
	helmDirectoryPath     = flag.String("helm-directory", "", "Path to the helm directory")
	packageDirectoryPath  = flag.String("package-directory", "", "Path to the package directory")
	versionFilePath       = flag.String("version-file", "", "Path to the version file")

	errVersionMismatch = errors.New("version mismatch")
)

type DeploymentPackage struct {
	SpecSchema                 string                         `yaml:"specSchema"`
	SchemaVersion              string                         `yaml:"schemaVersion"`
	Schema                     string                         `yaml:"$schema"`
	Name                       string                         `yaml:"name"`
	Description                string                         `yaml:"description,omitempty"`
	Version                    string                         `yaml:"version"`
	ForbidsMultipleDeployments bool                           `yaml:"forbidsMultipleDeployments"`
	Kind                       string                         `yaml:"kind"`
	Applications               []DeploymentPackageApplication `yaml:"applications"`
	// ApplicationDependencies  []ApplicationDependency `yaml:"applicationDependencies"`
	DefaultNamespaces map[string]string `yaml:"defaultNamespaces"`
	// DeploymentProfiles       []DeploymentProfile    `yaml:"deploymentProfiles"`
}

type DeploymentPackageApplication struct {
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

type Application struct {
	SpecSchema    string               `yaml:"specSchema"`
	SchemaVersion string               `yaml:"schemaVersion"`
	Schema        string               `yaml:"$schema"`
	Name          string               `yaml:"name"`
	Version       string               `yaml:"version"`
	Description   string               `yaml:"description,omitempty"`
	Kind          string               `yaml:"kind"`
	HelmRegistry  string               `yaml:"helmRegistry"`
	ChartName     string               `yaml:"chartName"`
	ChartVersion  string               `yaml:"chartVersion"`
	Profiles      []ApplicationProfile `yaml:"profiles"`
}

type ApplicationProfile struct {
	Name           string `yaml:"name"`
	DisplayName    string `yaml:"displayName"`
	ValuesFileName string `yaml:"valuesFileName"`
}

type HelmChart struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	Version     string `yaml:"version"`
	APIVersion  string `yaml:"apiVersion"`
	Icon        string `yaml:"icon"`
	Home        string `yaml:"home"`
}

func doCheck() error {
	// Load the version file
	versionFile, err := os.ReadFile(*versionFilePath)
	if err != nil {
		logrus.Errorf("Failed to read version file: %v", err)
		return err
	}
	logrus.Infof("Version file: %s", string(versionFile))
	version := strings.TrimSpace(string(versionFile))

	// Load the manifest file
	mf, err := manifest.New(*manifestFilePath)
	if err != nil {
		logrus.Errorf("Failed to load manifest: %v", err)
		return err
	}
	logrus.Infof("Checking manifest: %v", mf.Metadata.Release)
	if strings.HasSuffix(version, "-dev") {
		logrus.Warnf("Skipping manifest version check, -dev version detected: %s", version)
	} else if mf.Metadata.Release != version {
		logrus.Errorf("Version mismatch for manifest: expected %s, got %s", version, mf.Metadata.Release)
		return errVersionMismatch
	}

	for _, dp := range mf.LPKE.DeploymentPackages {
		dpName := strings.TrimPrefix(dp.DeploymentPackage, "edge-orch/en/file/")
		logrus.Info("Checking deployment package: ", dpName)
		b, err := os.ReadFile(*deploymentPackagePath + "/" + dpName + "/" + "deployment-package.yaml")
		if err != nil {
			logrus.Errorf("Failed to read deployment package file: %v", err)
			return err
		}
		dpp := DeploymentPackage{}
		err = yaml.Unmarshal(b, &dpp)
		if err != nil {
			logrus.Errorf("Failed to unmarshal deployment package file: %v", err)
			return err
		}
		if dpp.Name != dpName {
			logrus.Errorf("Name mismatch for deployment package %s: expected %s, got %s", dp.DeploymentPackage, dp.DeploymentPackage, dpp.Name)
			return errVersionMismatch
		}
		if dpp.Version != dp.Version {
			logrus.Errorf("Version mismatch for deployment package %s: expected %s, got %s", dp.DeploymentPackage, dp.Version, dpp.Version)
			return errVersionMismatch
		}

		if dpp.Name == "base-extensions" {
			logrus.Warnf("Skipping applications check for base-extensions deployment package")
			continue
		}

		appPath := *deploymentPackagePath + "/" + dpName + "/" + "applications.yaml"
		appPathAlt := *deploymentPackagePath + "/" + dpName + "/" + "application.yaml"

		// Parse and validate the applications for a given DP.
		apps, err := loadApplications(appPath)
		if err != nil {
			apps, err = loadApplications(appPathAlt) // Try singular.
			if err != nil {
				logrus.Errorf("Failed to load applications file: %v", err)
				return err
			}
		}
		for _, dpApp := range dpp.Applications {
			logrus.Infof("Checking application: %v %v", dpApp.Name, dpApp.Version)
			var a Application
			verified := slices.ContainsFunc(apps, func(app Application) bool {
				if app.Name != dpApp.Name {
					return false
				}
				if app.Version != dpApp.Version {
					logrus.Errorf("Version mismatch for application %s: expected %s, got %s", dpApp.Name, dpApp.Version, app.Version)
					return false
				}
				a = app
				return true
			})
			if !verified {
				return errVersionMismatch
			}
			if dpp.Name == "trusted-compute" { // Not hosted in this repo.
				continue
			}
			if a.HelmRegistry == "intel-rs-helm" {
				shortChartName := strings.TrimPrefix(a.ChartName, "edge-orch/en/charts/")
				helmPath := *helmDirectoryPath + "/" + shortChartName
				chartFile, err := os.ReadFile(helmPath + "/" + "Chart.yaml")
				if err != nil {
					return err
				}
				chart := HelmChart{}
				err = yaml.Unmarshal(chartFile, &chart)
				if err != nil {
					return err
				}
				logrus.Infof("Checking helm chart: %v %v", chart.Name, chart.Version)
				if chart.Name != shortChartName {
					logrus.Errorf("Name mismatch for helm chart %s: expected %s, got %s", a.ChartName, a.ChartName, chart.Name)
					return errVersionMismatch
				}
				if chart.Version != a.ChartVersion {
					logrus.Errorf("Version mismatch for helm chart %s: expected %s, got %s", a.ChartName, a.ChartVersion, chart.Version)
					return errVersionMismatch
				}
				if chart.Name == "kubevirt-helper" || chart.Name == "edgedns" {
					packagePath := *packageDirectoryPath + "/" + chart.Name
					if chart.Name == "edgedns" {
						packagePath = *packageDirectoryPath + "/" + "edgedns-coredns"
					}
					versionFile, err := os.ReadFile(packagePath + "/" + "VERSION")
					if err != nil {
						return err
					}
					packageVersion := strings.TrimSpace(string(versionFile))
					logrus.Infof("Checking docker image: %v %v", chart.Name, packageVersion)
					if packageVersion != chart.Version {
						logrus.Errorf("Version mismatch for package %s: expected %s, got %s", shortChartName, chart.Version, packageVersion)
						return errVersionMismatch
					}
				}
			}
		}
	}

	for _, dl := range mf.LPKE.DeploymentList {
		logrus.Warnf("Skipping deployment list: %v - %v", dl.DPName, dl.DPProfileName)
	}

	return nil
}

func main() {
	flag.Parse()
	logrus.SetLevel(logrus.DebugLevel)
	if *manifestFilePath == "" {
		flag.Usage()
		logrus.Fatal("Manifest file path is required")
	}
	if *deploymentPackagePath == "" {
		flag.Usage()
		logrus.Fatal("Deployment packages path is required")
	}
	if *helmDirectoryPath == "" {
		flag.Usage()
		logrus.Fatal("Helm directory path is required")
	}
	if *packageDirectoryPath == "" {
		flag.Usage()
		logrus.Fatal("Package directory path is required")
	}
	if *versionFilePath == "" {
		flag.Usage()
		logrus.Fatal("Version file path is required")
	}
	err := doCheck()
	if err != nil {
		logrus.Fatalf("Error during check: %v", err)
	}
}

// loadApplications takes a path to a application yaml file, parses all
// documents within it, and returns them as a slice of Application structs.
func loadApplications(path string) ([]Application, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var applications []Application
	dec := yaml.NewDecoder(bytes.NewReader(data))
	var doc Application
	for dec.Decode(&doc) == nil {
		applications = append(applications, doc)
	}

	return applications, nil
}
