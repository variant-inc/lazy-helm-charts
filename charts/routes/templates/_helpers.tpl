{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "routes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Check If string is empty of nil and adds '.' to the end if not empty
*/}}
{{- define "check-string-nil-empty" }}
{{- (and (ne . nil) (ne . "")) | ternary (printf "%s." .) "" }}
{{- end }}

{{/*
Environment with .
*/}}
{{- define "environment" }}
{{- include "check-string-nil-empty" .Values.global.environment }}
{{- end }}

{{/*
Upstream
*/}}
{{- define "upstream" }}
{{- default .Release.Name .Values.global.upstream.name }}
{{- end }}
