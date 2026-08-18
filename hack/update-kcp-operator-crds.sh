#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)/..

cd charts/kcp-operator/
version="$(yq '.appVersion' Chart.yaml)"
crdFileCore=templates/crds.yaml
crdFileCompiled=templates/crds-compiled.yaml

set -x

echo "{{- if .Values.crds.create }}" > "$crdFileCore"
kubectl kustomize "https://github.com/kcp-dev/kcp-operator/config/crd?ref=$version" | yq >> "$crdFileCore"
echo "{{- end }}" >> "$crdFileCore"

echo "{{- if .Values.crds.create }}" > "$crdFileCompiled"
kubectl kustomize "https://github.com/kcp-dev/kcp-operator/config/crd/deploy?ref=$version" | yq >> "$crdFileCompiled"
echo "{{- end }}" >> "$crdFileCompiled"
