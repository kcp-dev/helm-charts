# KCP Helm Chart

This Helm chart deploys KCP, including the following components:

* KCP pod, including virtual workspace container
* Etcd
* Front proxy

## Dependencies

* cert-manager
* Openshift route (optional)
* Ingress Controller (optional)
* Prometheus Operator (optional, see [Monitoring](#monitoring))

## Options

Currently configurable options:

* Etcd image and tag
* Etcd memory/cpu limit
* Etcd volume size
* KCP image and tag
* KCP memory/cpu limit
* KCP logging verbosity
* Virtual workspace memory/cpu limit
* Virtual workspace logging verbosity
* Audit logging
* OIDC
* Github user access to project
* External hostname

### Monitoring

Each component (etcd, kcp-front-proxy and kcp-server) has a `.monitoring` key that allows configuring monitoring for those components. At the moment, only Prometheus Operator is supported and is required as a pre-requisite on the cluster.

For all three, a `ServiceMonitor` resource can be created by setting `.[component].monitoring.serviceMonitor.enabled` to true. Monitoring for all components would therefore look like this:

```yaml
# enable ServiceMonitor for kcp-server.
kcp:
  monitoring:
    serviceMonitor:
      enabled: true

# enable ServiceMonitor for kcp-front-proxy.
kcpFrontProxy:
  monitoring:
    serviceMonitor:
      enabled: true

# enable ServiceMonitor for etcd.
etcd:
  monitoring:
    serviceMonitor:
      enabled: true
```

To collect metrics from these targets, a `Prometheus` instance targetting those `ServiceMonitors` is needed. A possible selector in the `Prometheus` spec is:

```yaml
serviceMonitorSelector:
    matchLabels:
      app.kubernetes.io/name: kcp
```
