{{- define "domains" }}
{{- if not (len .Values.subdomains) }}
{{- fail "There should be at least 1 subdomain provided" }}
{{- end }}
{{- $environment := "" }}
{{- if .Values.environment }}
{{- $environment = printf "%s." .Values.environment }}
{{- end }}
{{- $domain := .Values.domain }}
{{- range .Values.subdomains }}
- {{ printf "%s.%s%s" . $environment $domain | quote }}
{{- end }}
{{- end }}

{{- define "domains.private" }}
{{- if .Values.public.enabled }}
{{- $environment := "" }}
{{- if .Values.environment }}
{{- $environment = printf "%s." .Values.environment }}
{{- end }}
{{- $domain := .Values.domain }}
{{- range .Values.subdomains }}
- {{ printf "%s.internal.%s%s" . $environment $domain | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "redirect.private" }}
{{- $environment := "" }}
{{- if .Values.environment }}
{{- $environment = printf "%s." .Values.environment }}
{{- end }}
{{- $domain := .Values.domain }}
{{- printf "%s.internal.%s%s" (index .Values.subdomains 0) $environment $domain | quote }}
{{- end }}
