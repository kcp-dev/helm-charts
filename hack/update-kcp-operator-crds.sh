#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)/..

cd charts/kcp-operator/
version="$(yq '.appVersion' Chart.yaml)"
crdFile=templates/crds.yaml

set -x

echo "{{- if .Values.crds.create }}" > "$crdFile"
kubectl kustomize "https://github.com/kcp-dev/kcp-operator/config/crd?ref=$version" | yq >> "$crdFile"
echo "{{- end }}" >> "$crdFile"
