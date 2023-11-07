{{- define "library.secretFile.tpl" }}
{{- if .Values.secretVars }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "library.chart.fullname" . }}-chart-json
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
type: Opaque
stringData:
  secrets.json: {{ .Values.secretVars | toPrettyJson | quote -}}
{{- end }}
{{- end }}
