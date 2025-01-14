{{- define "name" -}}{{ .Release.Name }}{{- end }}
{{- define "agentname" -}}{{ .Values.agentName | default .Release.Name }}{{- end }}

{{/* create a container image reference */}}
{{- define "image" -}}
   {{- $default := (index . 0).Values.image -}}
   {{- $this := (index . 1) -}}

   {{- $this.repository | default $default.repository -}}:
   {{- $this.tag | default $default.tag -}}
{{- end }}
