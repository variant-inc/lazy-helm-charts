{{- define "library.external-secret.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- $secrets := .Values.awsSecrets -}}
{{- range $secrets }}
---
apiVersion: 'external-secrets.io/v1beta1'
kind: ExternalSecret
metadata:
  name: {{ $fullName }}-{{ required "name is required for each secret" .name }}
  labels:
    {{- $labels | nindent 4 }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: default
    kind: ClusterSecretStore
  {{ if hasPrefix "postgres-secret-" .name }}
  backendType: secretsManager
  data:
    - key: {{ .name }}
      name: data
  template:
    stringData:
      DATABASE__{{ .reference }}__host: "<%= JSON.parse(data.data).host %>"
      DATABASE__{{ .reference }}__name: "<%= JSON.parse(data.data).dbname %>"
      DATABASE__{{ .reference }}__user: "<%= JSON.parse(data.data).username %>"
      DATABASE__{{ .reference }}__password: "<%= JSON.parse(data.data).password %>"
      # DATABASE__{{ .reference }}__engine: "<%= JSON.parse(data.data).engine %>"
  {{ else }}
  data:
  - secretKey: {{ .reference }}
    remoteRef:
      key: {{ .name }}
{{- end -}}
{{- end -}}
{{- end }}