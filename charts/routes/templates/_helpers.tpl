{{/*
Expand the name of the chart.
*/}}
{{- define "routes.name" -}}
{{- .name | required "`name` is required" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "routes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "routes.labels" -}}
helm.sh/chart: {{ include "routes.chart" . }}
{{ include "routes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "routes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "routes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
