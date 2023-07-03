{{- define "library.configMap.tpl" }}
{{- if .Values.configVars }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "library.chart.fullname" . }}-chart
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.configVars }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}
