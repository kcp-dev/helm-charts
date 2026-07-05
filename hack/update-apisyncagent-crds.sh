#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)/..

cd charts/api-syncagent/
version="$(yq '.appVersion' Chart.yaml)"
crdFile=templates/crd-publishedresource.yaml

set -x

echo "{{- if .Values.crds.enabled }}{{\`" > "$crdFile"
# tail is used to cut header from CRD file
curl https://raw.githubusercontent.com/kcp-dev/api-syncagent/refs/tags/${version}/deploy/crd/kcp.io/syncagent.kcp.io_publishedresources.yaml -o - | tail -n +3 | yq >> "$crdFile"
echo "\`}}" >> "$crdFile"
echo "{{- end }}" >> "$crdFile"
