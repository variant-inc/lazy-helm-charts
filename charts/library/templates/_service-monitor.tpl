{{- define "library.service-monitor.tpl" }}
{{- $selectorLabels := (include "library.chart.selectorLabels" .) -}}
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels: {{ include "library.chart.labels" . | nindent 4 }}
  name: {{ include "library.chart.fullname" . }}
spec:
  endpoints:
    - targetPort: {{ ternary "http" "metrics" (empty .Values.service.metricsPort)}}
      interval: {{ .Values.serviceMonitor.interval }}
      {{- if .Values.serviceMonitor.scrapeTimeout }}
      scrapeTimeout: {{ .Values.serviceMonitor.scrapeTimeout }}
      {{- end }}
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
  selector: 
    matchLabels:
      {{- $selectorLabels | nindent 6 }}
{{- end }}