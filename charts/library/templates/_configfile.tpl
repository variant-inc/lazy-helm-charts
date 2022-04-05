{{- define "library.configFile.tpl" }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "library.chart.fullname" . }}-chart-json
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
data:
  config.json: {{ .Values.configVars | toPrettyJson | quote -}}
{{- end }}
