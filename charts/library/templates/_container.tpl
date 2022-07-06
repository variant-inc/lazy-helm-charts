{{- define "library.container.envFrom.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) }}
{{- $secretEnv := .Values.secretVars }}
{{- $configEnv := .Values.configVars }}
{{- $configMaps := .Values.configMaps | default list }}
{{- $awsSecrets := .Values.awsSecrets | default list }}
{{- if or (len $secretEnv) (len $configEnv) (len $configMaps) (len $awsSecrets)}}
{{- if len $secretEnv }}
- secretRef:
    name: {{ $fullName }}-chart
{{- end }}
{{- range $awsSecrets }}
- secretRef:
    name: {{ $fullName }}-{{ .name }}
{{- end }}
{{- if len $configEnv }}
- configMapRef:
    name: {{ $fullName }}-chart
{{- end }}
{{- range $configMaps }}
- configMapRef:
    name: {{ . }}
{{- end }}
{{- else }}
[]
{{- end }}
{{- end }}