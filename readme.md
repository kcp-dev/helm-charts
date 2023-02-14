# KCP Helm Charts

Repository for KCP helm charts.

## Pre-requisites

- Cert-manager installed and running
- Ingress installed (e.g. nginx-ingress or OpenShift router)

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add kcp https://kcp-dev.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
kcp` to see the charts.

To install the kcp chart:

    helm install my-kcp kcp/kcp

To uninstall the chart:

    helm delete my-kcp

## Development usage

To install using the local chart:

    helm install kcp ./charts/kcp --values ./myvalues.yaml --namespace kcp --create-namespace

Changes can then be made locally and tested via upgrade:

    helm upgrade kcp ./charts/kcp --values ./myvalues.yaml --namespace kcp

Note `myvalues.yaml` will depend on your environment (you must specify which ingress method
is used to expose the front-proxy endpoint), a minimal example:

    externalHostname: "<external hostname as exposed by ingress method below>"
    kcpFrontProxy:
      ingress:
        enabled: true
