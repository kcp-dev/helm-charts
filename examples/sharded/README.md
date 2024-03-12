
# Sharded example

In this example, we use helm charts to deploy a sharded version of KCP.

The final result from this example is a KCP cluster with 2 shards in 2 different
namespaces, 1 frontend proxy and 1 cache server.

### Prerequisites

- Cert-manager installed in the cluster
- Helm 3
- reflector emberstack helm repository added for secret replication

Namespace structure:
```text
kcp-certs - namespace for PKI infrastructure & certificates
kcp-alpha - namespace for shard 1
kcp-beta - namespace for shard 2
kcp-proxy - namespace for frontend proxy
kcp-cache - namespace for cache server
```

Having shards in different clusters is out of scope for this example. You need to
create cross-cluster communication between shards yourself if you want to do that.
You can use service mesh for that, or projects like [Submariner](https://submariner.io/),
[Skupper](https://skupper.io/).

To generate certificates for KCP you need to create certificates in phases.
Assuming you have a cluster with cert-manager installed, and you want to create
certificates for 2 shards, you need to do the following:

1. Deploy PKI infrastructure first:

```bash
helm upgrade --install --values ./kind-values-phase1.yaml --namespace kcp-certs --create-namespace kcp-certs ../../charts/certificates
```

In this example, we extend the `certificates` chart and enable the `secretTemplate`
to replicate secrets into the `kcp-alpha` and `kcp-beta` and other namespaces
where our shards and other components will be located

2. Deploy certificates for shards:

```bash
helm upgrade --install --values ./kind-values-phase2-alpha.yaml --namespace kcp-certs --create-namespace kcp-alpha ../../charts/certificates
helm upgrade --install --values ./kind-values-phase2-beta.yaml --namespace kcp-certs --create-namespace kcp-beta ../../charts/certificates
helm upgrade --install --values ./kind-values-phase2-proxy.yaml --namespace kcp-certs --create-namespace kcp-proxy ../../charts/certificates
helm upgrade --install --values ./kind-values-phase2-cache.yaml --namespace kcp-certs --create-namespace kcp-cache ../../charts/certificates
```

1. Deploy Cache server:

```bash
helm upgrade --install --values ./kind-values-phase3-cache.yaml --namespace kcp-cache --create-namespace kcp-cache ../../charts/cache
```

2. Deploy alpha root shard:

```bash
helm upgrade --install --values ./kind-values-phase3-alpha.yaml --namespace kcp-alpha --create-namespace kcp-alpha ../../charts/kcp-sharded
```

3. Deploy frontend proxy:

```bash
helm upgrade --install --values ./kind-values-phase3-proxy.yaml --namespace kcp-proxy --create-namespace kcp-proxy ../../charts/proxy
```

4. Deploy beta beta shard:

```bash
helm upgrade --install --values ./kind-values-phase3-beta.yaml --namespace kcp-beta --create-namespace kcp-beta ../../charts/kcp-sharded
```
