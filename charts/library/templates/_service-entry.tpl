{{- define "library.service-entry.tpl" }}
{{- $egress := .Values.istio.egress -}}
{{- $fullName := (include "library.chart.fullname" .) -}}
{{- $labels := (include "library.chart.labels" .) -}}
{{- range $egress }}
{{- $name := printf "%s-%s" $fullName (required "A valid name is required for each ServiceEntry!" .name) }}
{{ $hosts := .hosts }}
{{- if and (not .hosts) .addresses }}
  {{- /*
    If only addresses are provided, the name of this ServiceEntry
    can be used as the hostname to resolve the whitelisted addresses.
  */}}
  {{- $hosts = list $name }}
{{- end }}
---
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: {{ $name }}
  labels: {{ $labels | nindent 4 }}
spec:
  {{- if $hosts }}
  hosts:
    {{- range $hosts }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- if .addresses }}
  addresses:
    {{- range .addresses }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  exportTo:
    - "."
  location: MESH_EXTERNAL
  ports:
    {{- range .ports }}
    - number: {{ .number }}
      name: {{ printf "%s-%d" .protocol ( .number | int ) | quote | lower }}
      protocol: {{ .protocol | quote | upper }}
    {{- end }}
  resolution: {{ .resolution | default "DNS" }}
{{- end -}}
{{- end }}
