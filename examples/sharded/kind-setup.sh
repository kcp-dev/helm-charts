#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."

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

echo "Installing ingress…"

kubectl apply --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl label nodes "$CLUSTER_NAME-control-plane" "node-role.kubernetes.io/control-plane-"

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

# wait till now before checking nginx so that it and cert-manager can boot up in parallel
echo "Waiting for the ingress controller to become ready…"
kubectl --context "$KUBECTL_CONTEXT" --namespace ingress-nginx rollout status deployment/ingress-nginx-controller --timeout 5m

# Installing cert-manager will end with a message saying that the next step
# is to create some Issuers and/or ClusterIssuers.  That is indeed
# among the things that the kcp helm chart will do.

echo "Install reflector…"
helm repo add emberstack https://emberstack.github.io/helm-charts
helm upgrade \
  --install \
  --wait \
  --namespace reflector \
  --create-namespace \
  reflector emberstack/reflector
