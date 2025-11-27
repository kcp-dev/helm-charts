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

repeat() {
  local end=$1
  local str="${2:-=}"

  for i in $(seq 1 $end); do
    echo -n "${str}"
  done
}

heading() {
  local title="$@"
  echo "$title"
  repeat ${#title} "="
  echo
  echo
}

for dir in ./charts/*/; do
  dir="${dir%*/}"
  chart="${dir##*/}"

  for testfile in "$dir"/tests/*.yaml; do
    heading "$chart: $(basename $testfile)"

    tmpFile="$chart-templated.yaml"
    helm template \
      --debug \
      --values "$testfile" \
      "$chart" "$dir" | tee "$tmpFile"

    echo "---"

    # run kubeconform on template output to validate Kubernetes resources.
    # the external schema-location allows us to validate resources for
    # common CRDs (e.g. cert-manager resources).
    kubeconform \
      -schema-location default \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
      -schema-location "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json" \
      -strict \
      -summary \
      "$tmpFile"

    echo
    echo

    rm "$tmpFile"
  done
done
