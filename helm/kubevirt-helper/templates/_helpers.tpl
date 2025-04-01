# SPDX-FileCopyrightText: (C) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

{{/*
Expand the name of the chart.
*/}}
{{- define "kubevirt-helper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubevirt-helper.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubevirt-helper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubevirt-helper.labels" -}}
helm.sh/chart: {{ include "kubevirt-helper.chart" . }}
{{ include "kubevirt-helper.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubevirt-helper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt-helper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ template "kubevirt-helper.name" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubevirt-helper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubevirt-helper.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
kubevirt-helper image name
*/}}
{{- define "kubevirt-helper.imagename" -}}
{{- $registry := .Values.global.registry -}}
{{- if .Values.image.registry -}}
{{- $registry = .Values.image.registry -}}
{{- end -}}
{{- if hasKey $registry "name" -}}
{{- printf "%s/" $registry.name -}}
{{- end -}}
{{- printf "%s:" .Values.image.repository -}}
{{- if .Values.global.image.tag -}}
{{- .Values.global.image.tag -}}
{{- else if .Values.image.tag -}}
{{- tpl .Values.image.tag . -}}
{{- else -}}
{{- .Chart.AppVersion }}
{{- end -}}
{{- end -}}