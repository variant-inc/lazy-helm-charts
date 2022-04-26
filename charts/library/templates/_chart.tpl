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
revision: {{ required "revision is required" .Values.revision | quote }}
app: {{ .Release.Name }}
revision: {{ required "revision is required" .Values.revision | quote }}
cloudops.io/octopus-project: {{ .Values.tags.octopus/project | quote }}
cloudops.io/octopus-space:  {{ .Values.tags.octopus/space | quote }}
cloudops.io/octopus-environment: {{ .Values.tags.octopus/environment | quote }}
cloudops.io/octopus-project-group: {{ .Values.tags.octopus/project_group | quote }}
cloudops.io/octopus-release-channel: {{ .Values.tags.octopus/release_channel | quote }}
cloudops.io/user-team: {{ .Values.tags.team | quote }}
cloudops.io/user-purpose: {{ .Values.tags.purpose | quote }}
cloudops.io/user-owner: {{ .Values.tags.owner | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "library.chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}