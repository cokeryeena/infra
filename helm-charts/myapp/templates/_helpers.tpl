{{/*
Generate a name for the chart
*/}}
{{- define "myapp.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{/*
Generate a full name for resources
*/}}
{{- define "myapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

