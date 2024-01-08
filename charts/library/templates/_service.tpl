{{- define "library.service.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- $selectorLabels := (include "library.chart.selectorLabels" .) -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $fullName }}
  labels:
    {{- $labels | nindent 4 }}
  annotations:
    service.kubernetes.io/topology-mode: Auto
spec:
  type: ClusterIP
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
    {{- if .Values.service.metricsPort }}
    - port: {{ .Values.service.metricsPort }}
      targetPort: metrics
      protocol: TCP
      name: metrics
    {{- end }}
  selector:
    {{- $selectorLabels | nindent 4 }}
{{- end }}
