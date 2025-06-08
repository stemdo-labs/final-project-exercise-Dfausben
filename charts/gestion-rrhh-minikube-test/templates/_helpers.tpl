{{- define "gestion-rrhh.name" -}}
gestion-rrhh
{{- end -}}

{{- define "gestion-rrhh.fullname" -}}
{{ include "gestion-rrhh.name" . }}
{{- end -}}
