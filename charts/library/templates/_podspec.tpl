{{- define "library.podspec.tpl" }}
{{- $fullName := (include "chart.fullname" .) -}}
{{- $secrets := .Values.awsSecrets -}}
spec:
  serviceAccountName: {{ $fullName }}
  automountServiceAccountToken: true
  {{- if len .Values.nodeSelector }}
  nodeSelector:
    {{- range $key, $value := .Values.nodeSelector }}
    {{ $key }}: {{ $value }}
    {{- end }}
  {{- end }}
  affinity:
  {{- if len .Values.affinity }}
  {{- range $key, $value := .Values.affinity }}
    {{ $key }}: {{ toYaml $value | nindent 8 }}
  {{- end }}
  {{- else }}
    {{- include "library.chart.podAntiAffinity" . | nindent 8 }}
  {{- end }}
  {{- if len .Values.tolerations }}
  tolerations:
  {{- range .Values.tolerations }}
    - key: {{ required "Key is required for tolerations" .key | quote }}
      operator: {{ .operator | default "Exists" | quote }}
      {{- if hasKey . "value"  }}
      value: {{ .value | quote }}
      {{- end }}
      effect: {{ .effect | default "NoSchedule" | quote }}
  {{- end }}
  {{- end }}
    ### Behold! Long explanation for why securityContext is set here:
    #
    # When the "eks.amazonaws.com/role-arn" annotation is applied to the ServiceAccount used by this Deployment,
    # some new volume is mounted which contains the AWS secrets for authentication. By default, the owner will
    # be root, but the AWS SDK in our applications need access to this volume at runtime and our applications
    # should _not_ run as root.
    #
    # fsGroup determines group ownership of volumes mounted in this dynamic manner.
    #
    # Assumptions:
    # 1) The application process runs on an Alpine based platform -- the "nobody" group is defined as ID 65534 in Alpine
    # 2) The application is running as a non-root user (u better be)
    # 3) The non-root user _does not_ belong to any groups (i.e, "nobody")
    #
    # Let's not run as root
    # Chown all the things that you own
    # Groups of nobody
    ###
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 6 }}
  {{- if or (len $secrets) (eq .Chart.Name "variant-ui") (.Values.usxpressCACertBundle.enabled)}}
  volumes:
  {{- range $secrets }}
    - name: {{ $fullName}}-{{ .name }}
      secret:
        secretName: {{ $fullName}}-{{ .name }}
  {{- end }}
  {{- if eq .Chart.Name "variant-ui" }}
  {{- if .Values.configVars }}
    - name: config-file
      configMap:
        name: {{ $fullName }}-chart-json
  {{- end }}
  {{- if .Values.secretVars }}
    - name: secret-file
      secret:
        secretName: {{ $fullName }}-chart-json
  {{- end }}
  {{- if len .Values.awsSecrets }}
    - name: external-secret-file
      secret:
        secretName: {{ $fullName }}-external-json
  {{- end }}
  {{- end }}
  {{- if .Values.usxpressCACertBundle.enabled }}
    - name: custom-ca-certs
      secret:
        secretName: custom-ca-certs
  {{- end }}
  {{- end }}
  containers:
    - name: {{ $fullName }}
      image: {{ required "deployment.image.tag is required" .Values.deployment.image.tag }}
      imagePullPolicy: {{ .Values.deployment.image.pullPolicy }}
      {{- if len .Values.deployment.args }}
      args:
      {{- range .Values.deployment.args }}
        - {{ . }}
      {{- end }}
      {{- end }}
      ports:
        - name: http
          containerPort: {{ required "Target Port is required" .Values.service.targetPort }}
          protocol: TCP
      {{- if .Values.service.metricsPort }}
        - name: metrics
          containerPort: {{ .Values.service.metricsPort }}
          protocol: TCP
      {{- end }}
      {{- if .Values.service.healthCheckPort }}
        - name: health
          containerPort: {{ .Values.service.healthCheckPort }}
          protocol: TCP
      {{- end }}
      {{ $failureThresholdDefault := 15 }}
      {{ $periodSecondsDefault := 30 }}
      {{- if .Values.livenessProbe }}
      livenessProbe: {{ .Values.livenessProbe | toYaml | nindent 12 -}}
            {{- if not .Values.livenessProbe.failureThreshold }}
            failureThreshold: {{ $failureThresholdDefault }}
            {{- end }}
            {{- if not .Values.livenessProbe.periodSeconds }}
            periodSeconds: 30
            {{- end }}
      {{- else -}}
      {{ $port := ternary "http" "health" (empty .Values.service.healthCheckPort) }}
      livenessProbe:
        httpGet:
          path: /health
          port: {{ $port }}
        initialDelaySeconds: 10
        periodSeconds: {{ $periodSecondsDefault }}
        failureThreshold: {{ $failureThresholdDefault }}
      {{- end }}
      {{- if .Values.readinessProbe }}
      readinessProbe: {{ .Values.readinessProbe | toYaml | nindent 12 -}}
            {{- if not .Values.readinessProbe.failureThreshold }}
            failureThreshold: {{ $failureThresholdDefault }}
            {{- end }}
            {{- if not .Values.readinessProbe.periodSeconds }}
            periodSeconds: {{ $periodSecondsDefault }}
            {{- end }}
      {{- else -}}
      {{ $port := ternary "http" "health" (empty .Values.service.healthCheckPort) }}
      readinessProbe:
        httpGet:
          path: /health
          port: {{ $port }}
        initialDelaySeconds: 10
        periodSeconds: {{ $periodSecondsDefault }}
        failureThreshold: {{ $failureThresholdDefault }}
      {{- end }}
      resources:
        limits:
          memory: {{ .Values.deployment.resources.limits.memory }}
        requests:
          {{- toYaml .Values.deployment.resources.requests | nindent 12 }}
      env:
        - name: REVISION
          value: {{ required "revision is required" .Values.revision | quote }}
        - name: API_BASE_PATH
          value: /{{ .Release.Namespace }}/{{ .Release.Name }}
        {{- range .Values.deployment.envVars }}
        - name: {{ required ".name is required for all envVars" .name }}
          value: {{ required ".value is required for all envVars" .value | quote }}
        {{- end }}
        {{- if len .Values.deployment.conditionalEnvVars }}
        {{- range .Values.deployment.conditionalEnvVars }}
        {{- if .condition }}
        {{- range .envVars }}
        - name: {{ required ".name is required for all envVars" .name }}
          value: {{ required ".value is required for all envVars" .value | quote }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
      {{- if or (len $secrets) (eq .Chart.Name "variant-ui") (.Values.usxpressCACertBundle.enabled)}}
      volumeMounts:
      {{- range $secrets }}
        - name: {{ $fullName }}-{{ .name }}
          readOnly: true
          mountPath: /app/secrets/{{ $fullName }}-{{ .name }}
          subPath: {{ $fullName }}-{{ .name }}
      {{- end }}
      {{- if eq .Chart.Name "variant-ui" }}
      {{- if .Values.configVars }}
        - name: config-file
          readOnly: true
          mountPath: {{ .Values.configMountPath }}/config.json
          subPath: config.json
      {{- end }}
      {{- if .Values.secretVars }}
        - name: secret-file
          readOnly: true
          mountPath: {{ .Values.configMountPath }}
      {{- end }}
      {{- if len .Values.awsSecrets }}
        - name: external-secret-file
          readOnly: true
          mountPath: {{ .Values.configMountPath }}/external_secrets.json
          subPath: external_secrets.json
      {{- end }}
      {{- end }}
      {{- if .Values.usxpressCACertBundle.enabled }}
        - name: custom-ca-certs
          readOnly: true
          mountPath: {{ .Values.usxpressCACertBundle.certMountPath }}
      {{- end }}
      {{- end }}
      envFrom: {{ include "library.container.envFrom.tpl" . | nindent 12 }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 12 }}
{{- end }}
