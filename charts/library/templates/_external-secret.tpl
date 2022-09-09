{{- define "library.external-secret.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- $secrets := .Values.awsSecrets -}}
{{- range $secrets }}
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: {{ $fullName }}-{{ required "name is required for each secret" .name }}
  labels:
    {{- $labels | nindent 4 }}
spec:
  {{ if hasPrefix "postgres-secret-" .name }}
  backendType: secretsManager
  data:
    - key: {{ .name }}
      name: data
  template:
    stringData:
      DATABASE__{{ .name | trimPrefix "postgres-secret-" }}__host: "<%= JSON.parse(data.data).host %>"
      DATABASE__{{ .name | trimPrefix "postgres-secret-" }}__name: "<%= JSON.parse(data.data).dbname %>"
      DATABASE__{{ .name | trimPrefix "postgres-secret-" }}__user: "<%= JSON.parse(data.data).username %>"
      DATABASE__{{ .name | trimPrefix "postgres-secret-" }}__password: "<%= JSON.parse(data.data).password %>"
      # DATABASE__{{ .name | trimPrefix "postgres-secret-" }}__engine: "<%= JSON.parse(data.data).engine %>"
  {{ else }}
  template:
  backendType: secretsManager
  dataFrom:
    - {{ .name }}
{{- end -}}
{{- end -}}
{{- end }}