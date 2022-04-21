{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "library.chart.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "library.chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "library.chart.labels" -}}
helm.sh/chart: {{ include "library.chart.chart" . }}
{{ include "library.chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ .Release.Name }}
revision: {{ required "revision is required" .Values.revision | quote }}
cloudops.io/octopus-project: {{ required "project is required" .Values.tags.octopus_project | replace " " "-" | quote }}
cloudops.io/octopus-space:  {{ required "space is required" .Values.tags.octopus_space | replace " " "-" | quote }}
cloudops/octopus-environment: {{ required "environment is required" .Values.tags.octopus_environment | replace " " "-" | quote }}
cloudops/octopus-project-group: {{ required "project group is required" .Values.tags.octopus_project_group | replace " " "-" | quote }}
cloudops/octopus-release-channel: {{ required "release channel is required" .Values.tags.octopus_release_channel | replace " " "-" | quote }}
cloudops/user-team: {{ required "user team is required" .Values.tags.team | replace " " "-" | quote }}
cloudops/user-purpose: {{ required "user purpose is required" .Values.tags.purpose | replace " " "-" | quote }}
cloudops/user-owner: {{ required "user owner is required" .Values.tags.owner | replace " " "-" | | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "library.chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}