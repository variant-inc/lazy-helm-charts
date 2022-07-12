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
      {{.name}}-host: "<%= JSON.parse(data.data).host %>"
      {{.name}}-dbname: "<%= JSON.parse(data.data).dbname %>"
      {{.name}}-username: "<%= JSON.parse(data.data).username %>"
      {{.name}}-password: "<%= JSON.parse(data.data).password %>"
      {{.name}}-engine: "<%= JSON.parse(data.data).engine %>"
  {{ else }}
  backendType: secretsManager
  dataFrom:
    - {{ .name }}
{{- end -}}
{{- end -}}
{{- end }}