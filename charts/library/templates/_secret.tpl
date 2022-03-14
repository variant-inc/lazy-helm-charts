{{- define "library.secret.tpl" }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "library.chart.fullname" . }}-chart
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
type: Opaque
stringData:
  {{- range $key, $value := .Values.secretVars }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}