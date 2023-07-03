{{- define "library.serviceaccount.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $fullName }}
  labels:
    {{- $labels | nindent 4 }}
  {{- if .Values.serviceAccount.roleArn }}
  annotations:
    "eks.amazonaws.com/role-arn": "{{ .Values.serviceAccount.roleArn }}"
  {{- end }}
{{- end }}
