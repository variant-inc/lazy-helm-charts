{{- define "library.hpa.http.tpl" }}
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
  minReplicas: {{ .Values.autoscaling.minReplicas | default 2 }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    - type: Object
      object:
        metric:
          name: istio_requests_per_second
        describedObject:
          apiVersion: v1
          kind: Service
          name: {{ $fullName }}
        target:
          type: AverageValue
          averageValue: {{ .Values.autoscaling.httpRequestsPerSecond | default 10 | quote }}
{{- end }}
