#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

kind=kind
if ! [ -x "$(command -v kind)" ]; then
  mkdir -p .kind

  kind=.kind/kind
  if [ ! -f $kind ]; then
    echo "Downloading kind…"
    curl -Lo $kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x $kind
  fi
fi

CLUSTER_NAME="${CLUSTER_NAME:-kcp}"
export KUBECONFIG="$CLUSTER_NAME-kind.kubeconfig"
export KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"

if ! $kind get clusters | grep -w -q "$CLUSTER_NAME"; then
  $kind create cluster \
    --name "$CLUSTER_NAME" \
    --config hack/kind/config.yaml
else
  echo "Cluster $CLUSTER_NAME already exists."
fi

echo "Installing cert-manager…"

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
helm upgrade \
  --install \
  --wait \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  cert-manager jetstack/cert-manager

# Installing cert-manager will end with a message saying that the next step
# is to create some Issuers and/or ClusterIssuers.  That is indeed
# among the things that the kcp helm chart will do.

echo "Installing KCP…"

helm upgrade \
  --install \
  --values ./hack/kind-values.yaml \
  --namespace kcp \
  --create-namespace \
  kcp ./charts/kcp

echo "Generating KCP admin kubeconfig…"
./hack/generate-admin-kubeconfig.sh

hostname="$(yq '.externalHostname' hack/kind-values.yaml)"

echo "Checking /etc/hosts for ${hostname}…"
if ! grep -q "$hostname" /etc/hosts; then
  echo "127.0.0.1 $hostname" | sudo tee -a /etc/hosts
else
  echo "$hostname already exists in /etc/hosts."
fi
