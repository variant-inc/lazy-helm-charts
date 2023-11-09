{{- define "sub-domains" }}
{{- if not (len .Values.subdomains) }}
{{- fail "There should be at least 1 subdomain provided" }}
{{- end }}
{{- $subdomains := list -}}
{{- range .Values.subdomains }}
{{- $product := include "check-string-nil-empty" .product }}
{{- $app := include "check-string-nil-empty" .app }}
{{- $type := include "check-string-nil-empty" (.type | default $.Values.global.type) }}
{{- $subdomains = printf "%s%s%s" $type $product $app | append $subdomains -}}
{{- end }}
{{- join "," $subdomains }}
{{- end }}


{{- define "domains" }}
{{- $domain := .Values.global.domain }}
{{- range (include "sub-domains" $ | split ",") }}
- {{ printf "%s%s%s" . (include "environment" $) $domain }}
{{- end }}
{{- end }}

{{- define "domains.private" }}
{{- if .Values.public.enabled }}
{{- $domain := .Values.global.domain }}
{{- range (include "sub-domains" $ | split ",") }}
- {{ printf "%sinternal.%s%s" . (include "environment" $) $domain }}
{{- end }}
{{- end }}
{{- end }}

{{- define "redirect.private" }}
{{- $domain := .Values.global.domain }}
{{- printf "%sinternal.%s%s" (include "sub-domains" . | split ",")._0 (include "environment" .) $domain | quote }}
{{- end }}
