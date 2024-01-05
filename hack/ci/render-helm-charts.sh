#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

if ! [ -x "$(command -v helm)" ]; then
    echo "missing helm command in PATH"
    exit 1
fi

if ! [ -x "$(command -v kubeconform)" ]; then
    echo "missing kubeconform command in PATH"
    exit 1
fi

helm template \
  --debug \
  --set=externalHostname=ci.kcp.io \
  kcp charts/kcp/ | tee kcp-templated.yaml

echo "---"

# run kubeconform on template output to validate Kubernetes resources.
# the external schema-location allows us to validate resources for
# common CRDs (e.g. cert-manager resources).
kubeconform \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -strict \
  -summary \
  kcp-templated.yaml
