{{- define "library.container.envFrom.tpl" }}
{{- $fullName := (include "library.chart.fullname" .) }}
{{- $secretEnv := .Values.secretVars }}
{{- $configEnv := .Values.configVars }}
{{- $configMaps := .Values.configMaps | default list }}
{{- if or (len $secretEnv) (len $configEnv) (len $configMaps) }}
{{- if len $secretEnv }}
- secretRef:
    name: {{ $fullName }}-chart
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