# Metrics Server Deployment Package

## Overview

This deployment package provides the Kubernetes Metrics Server, which is a cluster-wide aggregator of resource usage data. It's essential for Horizontal Pod Autoscaling (HPA) and provides metrics for `kubectl top` commands.

## What it does

The Metrics Server:
- Collects resource metrics from Kubelets and exposes them in the Kubernetes API server
- Enables Horizontal Pod Autoscaling (HPA) and Vertical Pod Autoscaling (VPA)
- Provides metrics for `kubectl top nodes` and `kubectl top pods` commands
- Is required for proper functioning of cluster autoscaling features

## Files

- `deployment-package.yaml` - Main deployment package specification
- `applications.yaml` - Application specification with Helm chart details
- `values-metrics-server-default.yaml` - Default configuration values
- `../common/registry-metrics-server.yaml` - Helm registry configuration

## Original Deployment Command

This package replaces the manual deployment command that was used:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Configuration

The default configuration includes:
- Deployment to `kube-system` namespace
- Resource limits and requests for optimal performance
- Security context with non-root user
- Priority class `system-cluster-critical`
- Rolling update strategy for zero-downtime updates

## Dependencies

- Kubernetes cluster with RBAC enabled
- Access to the kubernetes-sigs/metrics-server Helm repository

## Version

- Application Version: v0.8.0
- Helm Chart Version: 3.12.1
- Package Version: 0.1.0
