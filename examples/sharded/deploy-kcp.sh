#!/bin/bash

echo "Deploy KCP certificates…"

helm upgrade --install --values kind-values-phase1.yaml --namespace kcp-certs --create-namespace kcp-certs ../../charts/certificates
helm upgrade --install --values kind-values-phase2-alpha.yaml --namespace kcp-certs --create-namespace kcp-alpha ../../charts/certificates
helm upgrade --install --values kind-values-phase2-beta.yaml --namespace kcp-certs --create-namespace kcp-beta ../../charts/certificates
helm upgrade --install --values kind-values-phase2-proxy.yaml --namespace kcp-certs --create-namespace kcp-proxy ../../charts/certificates
helm upgrade --install --values kind-values-phase2-cache.yaml --namespace kcp-certs --create-namespace kcp-cache ../../charts/certificates

echo "Deploy Cache server"
helm upgrade --install --values kind-values-phase3-cache.yaml --namespace kcp-cache --create-namespace kcp-cache ../../charts/cache

echo "Deploy alpha root shard"
helm upgrade --install --values kind-values-phase3-alpha.yaml --namespace kcp-alpha --create-namespace kcp-alpha ../../charts/shard

echo "Deploy frontend proxy"
helm upgrade --install --values kind-values-phase3-proxy.yaml --namespace kcp-proxy --create-namespace kcp-proxy ../../charts/proxy


echo "Deploy beta shard"
helm upgrade --install --values kind-values-phase3-beta.yaml --namespace kcp-beta --create-namespace kcp-beta ../../charts/shard
