#!/bin/bash
set -e

hostname=$(cat ./hack/kind-values.yaml | grep externalHostname | cut -d" " -f2- | tr -d '"')

cat << EOF > kcp.kubeconfig
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://${hostname}/clusters/root
  name: kind-kcp
contexts:
- context:
    cluster: kind-kcp
    user: kind-kcp
  name: kind-kcp
current-context: kind-kcp
kind: Config
preferences: {}
users:
- name: kind-kcp
  user:
    token: admin-token
EOF


echo "Kubeconfig file created at kcp.kubeconfig"
echo ""
echo "export KUBECONFIG=kcp.kubeconfig"
echo ""
