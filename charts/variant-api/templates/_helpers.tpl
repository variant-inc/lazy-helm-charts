{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "chart.ingressHostname" -}}
{{- required "istio.ingress.host is required" .Values.istio.ingress.host }}
{{- end }}

{{- define "chart.podAnnotations" -}}
{{- if len .Values.configVars }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- if len .Values.awsSecrets }}
checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end }}
checksum/serviceaccount: {{ include (print $.Template.BasePath "/serviceaccount.yaml") . | sha256sum }}
{{- range .Values.configMaps }}
checksum/{{ . | trunc 53 | trimSuffix "-" }}: {{ print (lookup "v1" "ConfigMap" $.Release.Namespace . ) | sha256sum }}
{{- end }}
{{- with .Values.deployment.podAnnotations }}
{{ toYaml . }}
{{- end }}
reloader.stakater.com/auto: "true"
{{- end }}
