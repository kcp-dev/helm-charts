# kcp Helm Charts

Repository for kcp Helm charts.

## Overview

The following charts are currently available from this repository:

- [kcp](./charts/kcp/)
- [api-syncagent](./charts/api-syncagent/)
- [kcp-operator](./charts/kcp-operator/)

> [!CAUTION]
> The charts below are work-in-progress and currently not ready for production use.

In addition, to support multi-shard kcp setups, we support a collection of charts
that are meant to be used together:

- [certificates](./charts/certificates/)
- [shard](./charts/shard/)
- [proxy](./charts/proxy/)
- [cache](./charts/cache/)

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's
[documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add kcp https://kcp-dev.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions
of the packages. You can then run `helm search repo kcp` to see the charts.

For individual usage instructions, please see the respective chart documentation linked above.

## Contributing

We ❤️ our contributors! If you're interested in helping us out, please check out [contributing to kcp](https://docs.kcp.io/kcp/latest/contributing/).

This community has a [Code of Conduct](https://github.com/kcp-dev/kcp/blob/main/code-of-conduct.md). Please make sure to follow it.

## Getting in touch

There are several ways to communicate with us:

- The [`#kcp-dev` channel](https://app.slack.com/client/T09NY5SBT/C021U8WSAFK) in the [Kubernetes Slack workspace](https://slack.k8s.io).
- Our mailing lists:
    - [kcp-dev](https://groups.google.com/g/kcp-dev) for development discussions.
    - [kcp-users](https://groups.google.com/g/kcp-users) for discussions among users and potential users.
- By joining the kcp-dev mailing list, you should receive an invite to our bi-weekly community meetings.
- See recordings of past community meetings on [YouTube](https://www.youtube.com/channel/UCfP_yS5uYix0ppSbm2ltS5Q).
- The next community meeting dates are available via our [CNCF community group](https://community.cncf.io/kcp/).
- Check the [community meeting notes document](https://docs.google.com/document/d/1PrEhbmq1WfxFv1fTikDBZzXEIJkUWVHdqDFxaY1Ply4) for future and past meeting agendas.

## License

Helm charts in this repository are licensed under [Apache-2.0](./LICENSE).
