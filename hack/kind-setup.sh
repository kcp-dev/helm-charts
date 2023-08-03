#!/bin/bash
set -e

if [ ! -f "/usr/local/bin/kind" ]; then
 echo "Installing KIND"
 curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
 chmod +x ./kind
 sudo mv ./kind /usr/local/bin/kind
else
    echo "KIND already installed"
fi

CLUSTER_NAME=${CLUSTER_NAME:-kcp}

if ! kind get clusters | grep -w -q "${CLUSTER_NAME}"; then
kind create cluster --name ${CLUSTER_NAME} \
     --kubeconfig ./${CLUSTER_NAME}.kubeconfig \
     --config ./hack/kind/config.yaml
else
    echo "Cluster already exists"
fi

export KUBECONFIG=./${CLUSTER_NAME}.kubeconfig

echo "Installing ingress"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl label nodes ${CLUSTER_NAME}-control-plane node-role.kubernetes.io/control-plane-

echo "Waiting for the ingress controller to become ready..."
# https://github.com/kubernetes/kubernetes/issues/83242
until kubectl --context "${KUBECTL_CONTEXT}" -n ingress-nginx get pod -l app.kubernetes.io/component=controller -o go-template='{{.items | len}}' | grep -qxF 1; do
    echo "Waiting for pod"
    sleep 1
done
kubectl --context "${KUBECTL_CONTEXT}" -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=5m

echo "Installing cert-manager"

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
helm install \
  --wait \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.9.1

# Installing cert-manager will end with a message saying that the next step
# is to create some Issuers and/or ClusterIssuers.  That is indeed
# among the things that the kcp helm chart will do.

echo "Install KCP"

mkdir -p ./dev

helm upgrade -i kcp ./charts/kcp \
     --values ./hack/kind-values.yaml \
     --namespace kcp \
     --create-namespace

echo "Generate KCP admin kubeconfig"
./hack/generate-admin-kubeconfig.sh

echo "Check /etc/hosts for kcp.dev.local"
if ! grep -q kcp.dev.local /etc/hosts; then
    echo "127.0.0.1 kcp.dev.local" | sudo tee -a /etc/hosts
else
    echo "kcp.dev.local already exists in /etc/hosts"
fi
