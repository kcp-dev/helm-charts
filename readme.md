# KCP Helm Charts

Repository for KCP helm charts.

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
