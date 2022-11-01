{{- define "library.notes.tpl" }}
{{- $fullName := (include "chart.fullname" .) -}}
{{- if .Values.configVars }}
Config vars:
{{- range $key, $value := .Values.configVars }}
{{ $key }}: {{ $value | quote }}
{{- end }}
.
{{- end }}
{{- if .Values.configMaps }}
Config maps:
{{- range .Values.configMaps }}
{{ . }}
{{- end }}
.
{{- end }}
{{- if .Values.awsSecrets }}
AWS Secrets
{{- range .Values.awsSecrets }}
{{ .reference }}: {{ .name }}
{{- end }}
======================================================
{{- end }}
Accessing the pod terminal:
Option #1
Use tool like Lens, connect to the correct env cluster and find the pod in correct namespace: {{ $.Release.Namespace }}
Click on it and in top right corner you'll have "Pod Shell" button which will allow you to enter pod's shell.
.
Option #2
Use terminal command like this:
kubectl exec -i -t -n {{ $.Release.Namespace }} <pod name> -c {{ $fullName }} -- sh -c "clear; (bash || ash || sh)"
======================================================
Checking for events and troubleshooting:
https://backstage.apps.ops-drivevariant.com/docs/default/component/dx-docs/Troubleshooting/
{{- end }}