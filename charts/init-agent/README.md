# KCP Helm Chart - Init Agent

This Helm chart deploys an instance of the [Init Agent](https://github.com/kcp-dev/init-agent).

## Mode of Operation

The Init Agent connects to a variety of workspaces inside kcp. In each of them, the necessary
RBAC needs to be provisioned for the agent to do its work.

To accomplish this, this Helm chart can be configured to output three different sets of manifests,
called **targets**:

* `""` (default) – By default, the Helm chart will output the Deployment, ServiceAccount and RBAC to
  run the Init Agent on a Kubernetes cluster. For this to work, you need to provide Helm with a
  kubeconfig for that cluster.
* `configcluster` – In this mode, the Helm chart outputs the RBAC necessary for the agent to read
  and process its `InitTarget` objects. This is meant to be installed into the workspace that is
  configured via `.configWorkspace` when installing the chart in default mode (above). This needs
  to be done once, using a kubeconfig for Helm that points to the config workspace of choice in
  kcp.
* `wstcluster` – This mode outputs the necessary RBAC to read and initialize `WorkspaceTypes`. This
  needs to be installed into each workspace where `WorkspaceType` objects exist that are referenced
  by an `InitTarget`.For this to work, you need to provide Helm with a kubeconfig that points to
  the effective workspace.

To toggle between these, use the Helm variable `target`:

```bash
helm install init-agent kcp/init-agent \
  --set "target=configcluster" \
  --values myvalues.yaml
```

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's
[documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add kcp https://kcp-dev.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions
of the packages. You can then run `helm search repo kcp` to see the charts.

To install the kcp chart:

```shell
helm upgrade --install my-init-agent kcp/init-agent --values ./myvalues.yaml
```

**NB:** Remember to install the chart also into kcp. See [mode of operation](#mode-of-operation) above.

To uninstall the release:

```shell
helm delete my-init-agent
```

## Configuration

### kcp kubeconfig

When installing the Init Agent, you need to provide it with the name of a Kubernetes Secret that
contains a kubeconfig to communicate with kcp (using the `kcpKubeconfig` variable of this chart).

Since the concrete way you choose to authenticate to kcp is up to you (the [kcp-operator](https://docs.kcp.io/kcp-operator/) for example relies on client certificates), and the Helm chart can configure RBAC,
you need to configure in the Helm chart as what user the Init Agent is authenticated in kcp. The
default configuration assumes that the user is named `kcp-init-agent`:

```yaml
configCluster:
  rbacSubject:
    kind: User
    name: my-init-agent
```
