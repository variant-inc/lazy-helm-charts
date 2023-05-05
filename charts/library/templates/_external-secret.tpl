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
  secretStoreRef:
    name: default
    kind: ClusterSecretStore
  {{ if hasPrefix "postgres-secret-" .name }}
  data:
  - secretKey: DATABASE__{{ .reference }}__host
    remoteRef:
      key: {{ .name }}
      property: host
  - secretKey: DATABASE__{{ .reference }}__name
    remoteRef:
      key: {{ .name }}
      property: dbname
  - secretKey: DATABASE__{{ .reference }}__password
    remoteRef:
      key: {{ .name }}
      property: password
  - secretKey: DATABASE__{{ .reference }}__user
    remoteRef:
      key: {{ .name }}
      property: username
  - secretKey: data
    remoteRef:
      key: {{ .name }}
  {{ else }}
  data:
  - secretKey: {{ .reference }}
    remoteRef:
      key: {{ .name }}
{{- end -}}
{{- end -}}
{{- end }}