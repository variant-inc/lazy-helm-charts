{{- define "library.poddisruptionbudget.tpl" }}
---
{{- if gt (.Values.autoscaling.minReplicas | int) 1 }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "library.chart.fullname" . }}-chart
  labels:
    {{- include "library.chart.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.minAvailable | default 1 }}
  selector:
    matchLabels:
      {{- include "library.chart.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end }}