# KCP Helm Chart - kcp-operator

This Helm chart deploys an instance of the [kcp-operator](https://github.com/kcp-dev/kcp-operator).

## Requirements

* [cert-manager](https://cert-manager.io/docs/installation)

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's
[documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add kcp https://kcp-dev.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions
of the packages. You can then run `helm search repo kcp` to see the charts.

To install the kcp-operator chart (you can also pass custom values via `--values myvalues.yaml`):

```shell
helm install my-kcp-operator kcp/kcp-operator
```

To uninstall the release:

```shell
helm delete my-kcp-operator
```

Check [values.yaml](./values.yaml) for configuration options for this Helm chart.

## Documentation

For documentation on how to use kcp-operator, check out [docs.kcp.io/kcp-operator](https://docs.kcp.io/kcp-operator).
