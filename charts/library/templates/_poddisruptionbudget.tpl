{{- define "library.poddisruptionbudget.tpl" }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "library.chart.fullname" . }}-chart
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
spec:
  {{- if eq (.Values.autoscaling.minReplicas | int) 1 }}
  maxUnavailable: 0
  {{ else }}
  maxUnavailable: {{ .Values.maxUnavailable }}
  {{ end }}
  selector:
    matchLabels:
      {{- include "library.chart.selectorLabels" . | nindent 6 }}
{{- end }}
