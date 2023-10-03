{{- define "library.external-secretfile.tpl" }}
{{- $fullName := (include "chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- $secrets := .Values.awsSecrets -}}
{{- if len $secrets }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $fullName }}-external-json
  labels:
    {{- $labels | nindent 4 }}
spec:
  secretStoreRef:
    name: default
    kind: ClusterSecretStore
  target:
    deletionPolicy: Delete
    template:
      metadata:
        labels:
          {{- $labels | nindent 10 }}
      engineVersion: v2
      data:
        external_secrets.json: |
          {{`{{- $values := dict }}
          {{- range $k, $v := . }}
          {{- $values = merge $values ($v | fromJson) }}
          {{- end }}
          {{- $values | toPrettyJson }}`}}
  data:
{{- range $secrets }}
  - secretKey: {{ .name }}
    remoteRef:
      key: {{ .name }}
  refreshInterval: 30s
{{- end }}
{{- end }}
{{- end }}
