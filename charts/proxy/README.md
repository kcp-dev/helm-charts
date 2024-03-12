# KCP Helm Chart - Front Proxy

This Helm chart deploys Sharded KCP.

## Dependencies

* cert-manager
* Cache server deployed by [charts/cache](../../charts/cache)
* Certificates deployed by [charts/certificates](../../charts/certificates)
* Single shard deployed by [charts/kcp-sharded](../../charts/kcp-sharded)
