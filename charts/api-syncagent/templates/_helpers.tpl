{{- define "name" -}}{{ .Release.Name }}{{- end }}
{{- define "agentname" -}}{{ .Values.agentName | default .Release.Name }}{{- end }}
