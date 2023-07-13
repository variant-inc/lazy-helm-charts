{{- define "library.configFile.tpl" }}
{{- if .Values.configVars }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "library.chart.fullname" . }}-chart-json
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
data:
  config.json: {{ deepCopy .Values.configVars | merge .Values.configVarsFile | toPrettyJson | quote -}}
{{- end }}
{{- end }}
