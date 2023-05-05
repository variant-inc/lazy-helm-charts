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
  - secretKey: {{ .name }}
    remoteRef:
      key: DATABASE__{{ .reference }}__host
      property: host
  - secretKey: {{ .name }}
    remoteRef:
      key: DATABASE__{{ .reference }}__name
      property: dbname
  {{ else }}
  data:
  - secretKey: {{ .reference }}
    remoteRef:
      key: {{ .name }}
{{- end -}}
{{- end -}}
{{- end }}