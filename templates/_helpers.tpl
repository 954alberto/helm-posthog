{{/*
Expand the name of the chart.
*/}}
{{- define "posthog.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "posthog.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "posthog.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "posthog.labels" -}}
helm.sh/chart: {{ include "posthog.chart" . }}
{{ include "posthog.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "posthog.selectorLabels" -}}
app.kubernetes.io/name: {{ include "posthog.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels helper - call with dict "root" . "component" "name"
*/}}
{{- define "posthog.componentLabels" -}}
{{ include "posthog.labels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component selector labels - call with dict "root" . "component" "name"
*/}}
{{- define "posthog.componentSelectorLabels" -}}
{{ include "posthog.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "posthog.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "posthog.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Secret name - either user-provided existing secret or chart-managed secret
*/}}
{{- define "posthog.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- include "posthog.fullname" . }}-secrets
{{- end }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "posthog.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- toYaml .Values.global.imagePullSecrets | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Pod security context - merges component-level override with global default.
Call with dict "root" . "component" <values-key>
where <values-key> is the values key that has .podSecurityContext (e.g. "web", "postgresql")
*/}}
{{- define "posthog.podSecurityContext" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $componentCtx := $componentValues.podSecurityContext | default dict -}}
{{- $globalCtx := .root.Values.global.podSecurityContext | default dict -}}
{{- $merged := merge $componentCtx $globalCtx -}}
{{- if $merged }}
securityContext:
  {{- toYaml $merged | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Container security context - merges component-level override with global default.
Call with dict "root" . "component" <values-key>
*/}}
{{- define "posthog.containerSecurityContext" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $componentCtx := $componentValues.containerSecurityContext | default dict -}}
{{- $globalCtx := .root.Values.global.containerSecurityContext | default dict -}}
{{- $merged := merge $componentCtx $globalCtx -}}
{{- if $merged }}
securityContext:
  {{- toYaml $merged | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Node selector - merges component-level with global.
Call with dict "root" . "component" <values-key>
*/}}
{{- define "posthog.nodeSelector" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $componentNS := $componentValues.nodeSelector | default dict -}}
{{- $globalNS := .root.Values.global.nodeSelector | default dict -}}
{{- $merged := merge $componentNS $globalNS -}}
{{- if $merged }}
nodeSelector:
  {{- toYaml $merged | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Tolerations - component-level overrides global (not merged, replaced).
Call with dict "root" . "component" <values-key>
*/}}
{{- define "posthog.tolerations" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $tols := $componentValues.tolerations | default .root.Values.global.tolerations -}}
{{- if $tols }}
tolerations:
  {{- toYaml $tols | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Affinity - component-level overrides global (not merged, replaced).
Call with dict "root" . "component" <values-key>
*/}}
{{- define "posthog.affinity" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $aff := $componentValues.affinity | default .root.Values.global.affinity -}}
{{- if $aff }}
affinity:
  {{- toYaml $aff | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Pod annotations - merges component-level with global.
Call with dict "root" . "component" <values-key>
*/}}
{{- define "posthog.podAnnotations" -}}
{{- $componentValues := index .root.Values .component -}}
{{- $componentAnn := $componentValues.podAnnotations | default dict -}}
{{- $globalAnn := .root.Values.global.podAnnotations | default dict -}}
{{- $merged := merge $componentAnn $globalAnn -}}
{{- if $merged }}
{{- toYaml $merged }}
{{- end }}
{{- end }}

{{/*
Common environment variables shared across PostHog application services
*/}}
{{- define "posthog.commonEnv" -}}
- name: POSTHOG_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: posthog-secret
- name: ENCRYPTION_SALT_KEYS
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: encryption-salt-keys
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: database-url
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: redis-url
- name: CLICKHOUSE_HOST
  value: {{ .Values.externalClickhouse.host | default (printf "%s-clickhouse" (include "posthog.fullname" .)) | quote }}
- name: CLICKHOUSE_DATABASE
  value: {{ .Values.clickhouse.database | default "posthog" | quote }}
- name: CLICKHOUSE_SECURE
  value: {{ .Values.clickhouse.secure | default "false" | quote }}
- name: CLICKHOUSE_VERIFY
  value: {{ .Values.clickhouse.verify | default "false" | quote }}
- name: CLICKHOUSE_API_USER
  value: {{ .Values.clickhouse.apiUser | default "api" | quote }}
- name: CLICKHOUSE_API_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: clickhouse-api-password
- name: CLICKHOUSE_APP_USER
  value: {{ .Values.clickhouse.appUser | default "app" | quote }}
- name: CLICKHOUSE_APP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: clickhouse-app-password
- name: KAFKA_HOSTS
  value: {{ .Values.externalKafka.brokers | default (printf "%s-kafka:9092" (include "posthog.fullname" .)) | quote }}
- name: SITE_URL
  value: {{ printf "https://%s" .Values.ingress.hostname | quote }}
- name: DEPLOYMENT
  value: "helm"
- name: IS_BEHIND_PROXY
  value: "true"
- name: DISABLE_SECURE_SSL_REDIRECT
  value: "true"
- name: OTEL_SDK_DISABLED
  value: "true"
- name: OPT_OUT_CAPTURE
  value: {{ .Values.posthog.optOutCapture | default "false" | quote }}
- name: OBJECT_STORAGE_ENABLED
  value: {{ .Values.objectStorage.enabled | default "true" | quote }}
- name: OBJECT_STORAGE_ENDPOINT
  value: {{ .Values.externalObjectStorage.endpoint | default (printf "http://%s-minio:9000" (include "posthog.fullname" .)) | quote }}
- name: OBJECT_STORAGE_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: object-storage-access-key
- name: OBJECT_STORAGE_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: object-storage-secret-key
- name: OBJECT_STORAGE_PUBLIC_ENDPOINT
  value: {{ printf "https://%s" .Values.ingress.hostname | quote }}
- name: SESSION_RECORDING_V2_S3_ENDPOINT
  value: {{ .Values.externalSeaweedfs.endpoint | default (printf "http://%s-seaweedfs:8333" (include "posthog.fullname" .)) | quote }}
- name: SESSION_RECORDING_V2_S3_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: seaweedfs-access-key
- name: SESSION_RECORDING_V2_S3_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: seaweedfs-secret-key
- name: TEMPORAL_HOST
  value: {{ .Values.externalTemporal.host | default (printf "%s-temporal" (include "posthog.fullname" .)) | quote }}
- name: CYCLOTRON_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: database-url
- name: PERSONS_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "posthog.secretName" . }}
      key: database-url
- name: CDP_API_URL
  value: {{ printf "http://%s-plugins:6738" (include "posthog.fullname" .) | quote }}
- name: RECORDING_API_URL
  value: {{ printf "http://%s-plugins:6738" (include "posthog.fullname" .) | quote }}
- name: LIVESTREAM_HOST
  value: {{ printf "https://%s/livestream" .Values.ingress.hostname | quote }}
- name: FLAGS_REDIS_ENABLED
  value: "false"
{{- with .Values.global.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
PostgreSQL connection URL builder
*/}}
{{- define "posthog.databaseUrl" -}}
{{- if .Values.externalPostgresql.url -}}
{{- .Values.externalPostgresql.url -}}
{{- else -}}
{{- printf "postgres://%s:%s@%s-postgresql:5432/%s" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "posthog.fullname" .) .Values.postgresql.auth.database -}}
{{- end -}}
{{- end }}

{{/*
Redis URL builder
*/}}
{{- define "posthog.redisUrl" -}}
{{- if .Values.externalRedis.url -}}
{{- .Values.externalRedis.url -}}
{{- else -}}
{{- printf "redis://%s-redis:6379/" (include "posthog.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
Topology spread constraints for HA - preferred spread across zones and nodes.
Call with dict "root" . "component" "name" where name is the component label value.
*/}}
{{- define "posthog.topologySpreadConstraints" -}}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- include "posthog.componentSelectorLabels" (dict "root" .root "component" .component) | nindent 8 }}
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- include "posthog.componentSelectorLabels" (dict "root" .root "component" .component) | nindent 8 }}
{{- end }}
