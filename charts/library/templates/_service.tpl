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
spec:
  type: ClusterIP
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- $selectorLabels | nindent 4 }}
{{- end }}