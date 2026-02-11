{{- define "name" -}}{{ .Release.Name }}{{- end }}
{{- define "agentname" -}}{{ .Values.agentName | default .Release.Name }}{{- end }}

{{- define "imagePullSecrets" -}}
{{- range .Values.imagePullSecrets }}
{{- if eq (typeOf .) "map[string]interface {}" }}
- {{ toYaml . | trim }}
{{- else }}
- name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}
