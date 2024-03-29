{{- define "library.external-secret.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- $secrets := .Values.awsSecrets -}}
{{- range $secrets }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $fullName }}-{{ required "name is required for each secret" (.name | replace "_" "-") }}
  labels:
    {{- $labels | nindent 4 }}
spec:
  secretStoreRef:
    name: default
    kind: ClusterSecretStore
  target:
    deletionPolicy: Delete
    template:
      mergePolicy: Merge
      metadata:
        labels:
          {{- $labels | nindent 10 }}
  {{ if hasPrefix "postgres-secret-" .name }}
  dataFrom:
  - extract:
      key: {{ .name }}
    rewrite:
    - regexp:
        source: "(.*)"
        target: "DATABASE__{{ .reference }}__$1"
    - regexp:
        source: "DATABASE__{{ .reference }}__username"
        target: "DATABASE__{{ .reference }}__user"
    - regexp:
        source: "DATABASE__{{ .reference }}__dbname"
        target: "DATABASE__{{ .reference }}__name"
  {{ else }}
  dataFrom:
  - extract:
      key: {{ .name }}
  refreshInterval: 30s
{{- end -}}
{{- end -}}
{{- end }}
