#!/bin/bash


if [ ! -f "/usr/local/bin/kind" ]; then
 echo "Installing KIND"
 curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
 chmod +x ./kind
 sudo mv ./kind /usr/local/bin/kind
else
    echo "KIND already installed"
fi

CLUSTER_NAME=kcp

if ! kind get clusters | grep -w -q "${CLUSTER_NAME}"; then
kind create cluster --name kcp \
     --kubeconfig .kcp/admin.kubeconfig \
     --config ./hack/kind-config.yaml
else
    echo "Cluster already exists"
fi

export KUBECONFIG=.kcp/admin.kubeconfig

echo "Installing ingress"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Installing cert-manager"

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.9.1

