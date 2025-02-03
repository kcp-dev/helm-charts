# kcp

This Helm chart deploys kcp, including the following components:

* kcp (server) Pod, including virtual workspace container
* etcd
* kcp-front-proxy

## Requirements

* [cert-manager](https://cert-manager.io/docs/installation)
* Openshift route support (optional)
* Ingress Controller (optional)
* Prometheus Operator (optional, see [Monitoring](#monitoring))

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's
[documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add kcp https://kcp-dev.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions
of the packages. You can then run `helm search repo kcp` to see the charts.

To install the kcp chart:

    helm install my-kcp kcp/kcp --values ./myvalues.yaml

To uninstall the chart:

    helm delete my-kcp

Note that `myvalues.yaml` will depend on your environment (you must specify which ingress method
is used to expose the front-proxy endpoint), a minimal example:

```yaml
externalHostname: "<external hostname as exposed by ingress method below>"
kcpFrontProxy:
  ingress:
    enabled: true
```

Export the externalHostname variable, that will be used later to interact with kcp setup:

    export KCP_EXTERNAL_HOSTNAME=kcp.dev.local


## PKI

The chart will create a full PKI system, with root CA, intermediate CAs and more. The diagram below
shows the default configuration, however the issuer for the `kcp-front-proxy` certificate can be
configured and used, for example, Let's Encrypt.

```mermaid
graph TB
    A([kcp-pki-bootstrap]):::issuer --> B(kcp-pki-ca):::ca
    B --> C([kcp-pki]):::issuer

    X([lets-encrypt-staging]):::issuer
    Y([lets-encrypt-prod]):::issuer

    C --> D(kcp-etcd-client-ca):::ca
    C --> E(kcp-etcd-peer-ca):::ca
    C --> F(kcp-front-proxy-client-ca):::ca
    C --> G(kcp-ca):::ca
    C --> H(kcp-requestheader-client-ca):::ca
    C --> I(kcp-client-ca):::ca
    C --> J(kcp-service-account-ca):::ca

    D --> K([kcp-etcd-client-issuer]):::issuer
    E --> L([kcp-etcd-peer-issuer]):::issuer
    F --> M([kcp-front-proxy-client-issuer]):::issuer
    G --> N([kcp-server-issuer]):::issuer
    H --> O([kcp-requestheader-client-issuer]):::issuer
    I --> P([kcp-client-issuer]):::issuer
    J --> Q([kcp-service-account-issuer]):::issuer

    K --- K1(kcp-etcd):::cert --> K2(kcp-etcd-client):::cert
    L --> L1(kcp-etcd-peer):::cert
    M --> M1(kcp-external-admin-kubeconfig):::cert
    N --- N1(kcp):::cert --- N2(kcp-front-proxy):::cert --> N3(kcp-virtual-workspaces):::cert
    O --- O1(kcp-front-proxy-requestheader):::cert --> O2(kcp-front-proxy-vw-client):::cert
    P --- P1(kcp-front-proxy-kubeconfig):::cert --> P2(kcp-internal-admin-kubeconfig):::cert
    Q --> Q1(kcp-service-account):::cert

    classDef issuer color:#77F
    classDef ca color:#F77
    classDef cert color:orange
```

Note that by default all certificates are signed by the Helm chart's own PKI and so will not be
trusted by browsers. You can however change the `kcp-front-proxy`'s certificate to be issued
by, for example, Let's Encrypt. For this you have to enable the creation of the Let's Encrypt
issuer like so:

```yaml
externalHostname: "<external hostname as exposed by ingress method below>"
kcpFrontProxy:
  ingress:
    enabled: true
  certificateIssuer:
    name: kcp-letsencrypt-prod
    kind: ClusterIssuer
letsEncrypt:
  enabled: true
  production:
    enabled: true
    email: lets-encrypt-notifications@example.com
```

## Access

To access the deployed kcp, it will be necessary to create a kubeconfig which connects via the
front-proxy external endpoint (specified via `externalHostname` above).

The content of the kubeconfig will depend on the kcp authentication configuration, below we describe
one option which uses client-cert auth to enable a kcp-admin user.

:warning: this example allows global admin permissions across all workspaces, you may also want to
consider using more restricted groups for example `system:kcp:workspace:access` to provide a
user `system:authenticated` access to a workspace.

### Create kubeconfig and add CA cert

First we get the CA cert for the front proxy, saving it to a file `ca.crt`

    kubectl get secret kcp-front-proxy-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt

Now we create a new kubeconfig which references the `ca.crt`

    kubectl --kubeconfig=admin.kubeconfig config set-cluster base --server https://$KCP_EXTERNAL_HOSTNAME:443 --certificate-authority=ca.crt
    kubectl --kubeconfig=admin.kubeconfig config set-cluster root --server https://$KCP_EXTERNAL_HOSTNAME:443/clusters/root --certificate-authority=ca.crt

### Create client-cert credentials

Now we must add credentials to the kubeconfig, so requests to the front-proxy may be authenticated.

One way to do this is to create a client certificate with a cert-manager `Certificate`

    cat <<EOF | kubectl apply -f -
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: cluster-admin-client-cert
    spec:
      commonName: cluster-admin
      issuerRef:
        name: kcp-front-proxy-client-issuer
      privateKey:
        algorithm: RSA
        size: 2048
      secretName: cluster-admin-client-cert
      subject:
        organizations:
        - system:kcp:admin
      usages:
      - client auth
    EOF

This will result in a `cluster-admin-client-cert` secret which we can again save to local files:

    kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.crt}' | base64 -d > client.crt
    kubectl get secret cluster-admin-client-cert -o=jsonpath='{.data.tls\.key}' | base64 -d > client.key
    chmod 600 client.crt client.key

We can now add these credentials to the `admin.kubeconfig` and access kcp:

    kubectl --kubeconfig=admin.kubeconfig config set-credentials kcp-admin --client-certificate=client.crt --client-key=client.key
    kubectl --kubeconfig=admin.kubeconfig config set-context base --cluster=base --user=kcp-admin
    kubectl --kubeconfig=admin.kubeconfig config set-context root --cluster=root --user=kcp-admin
    kubectl --kubeconfig=admin.kubeconfig config use-context root
    kubectl --kubeconfig=admin.kubeconfig workspace
    export KUBECONFIG=$PWD/admin.kubeconfig
    kubectl workspace
    Current workspace is "1gnrr0twy6c3o".

## Install to kind cluster (for development)

There is a helper script to install kcp to a [kind](https://github.com/kubernetes-sigs/kind) cluster.
It will install cert-manager and kcp. The `kind` cluster binds to host port 8443 for exposing kcp.
This particular configuration is useful for development and testing, but will not work with Let's Encrypt.
From the root directory of this repository, run:

    ./hack/kind-setup.sh

Pre-requisites established by that script:

* `kind` executable installed at `/usr/local/bin/kind`
* kind cluster named `kcp`
* [cert-manager](https://cert-manager.io/) installed on the cluster
* `/etc/hosts` entry for `kcp.dev.local` pointing to `127.0.0.1`

The script will then install kcp the following way:

    helm upgrade --install my-kcp ./charts/kcp/ \
      --values ./hack/kind-values.yaml \
      --namespace kcp \
      --create-namespace

See [hack/kind-values.yaml](./hack/kind-values.yaml) for the values passed to the Helm chart.

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
* Authorization Webhook

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
