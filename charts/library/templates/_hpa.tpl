{{- define "library.hpa.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $fullName }}
  labels:
    {{- $labels | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $fullName }}
  minReplicas: {{ required "autoscaling.minReplicas is required" .Values.autoscaling.minReplicas }}
  maxReplicas: {{ required "autoscaling.maxReplicas is required" .Values.autoscaling.maxReplicas }}
  metrics:
    {{- if and (empty .Values.autoscaling.targetCPUUtilizationPercentage) (empty .Values.autoscaling.targetMemoryUtilizationPercentage) }}
      {{- fail "autoscaling.targetCPUUtilizationPercentage or autoscaling.targetMemoryUtilizationPercentage must be specified" }}
    {{- end }}
    {{- if .Values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
            type: Utilization
            averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
            type: Utilization
            averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
