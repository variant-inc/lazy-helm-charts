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
app.kubernetes.io/version: {{ default .Values.revision .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.tags }}
cloudops.io.{{ $key }}: {{ $value | replace " " "-"| quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "library.chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Chart.Name }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "library.chart.podLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/version: {{ default .Values.revision .Chart.AppVersion | quote }}
app: {{ .Release.Name }}
{{- range $key, $value := .Values.tags }}
cloudops.io.{{ $key }}: {{ $value | replace " " "-"| quote }}
{{- end }}
cloudops.io/logging_enabled: 'true'
{{- end }}
