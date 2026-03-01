# Mock Kubernetes Server in Dev Container

The Dev Container includes a local Kubernetes cluster (powered by [kind](https://kind.sigs.k8s.io/)) that mirrors the mock server used in the CI validation workflow. This lets you run server-side dry-run validation locally before pushing changes.

## What Is Set Up Automatically

When you open the repository in the Dev Container, the `postCreateCommand` runs `.devcontainer/setup-mock-k8s.sh` which:

1. Creates a local kind cluster named `mock` using the same Kubernetes node image as CI (`kindest/node:v1.31.4`).
2. Installs the GKE-specific CRD stubs from `k8s/mock/crds.yaml` so that GKE custom resources (e.g. `BackendConfig`, `ManagedCertificate`) are accepted by the mock server.

## Running Manifest Validation

After the container starts, validate your Kubernetes manifests with server-side dry-run:

```bash
# Development overlay
kustomize build k8s/overlays/development | kubectl apply --dry-run=server -f -

# Production overlay
kustomize build k8s/overlays/production | kubectl apply --dry-run=server -f -
```

This is the same validation that the CI workflow performs in `.github/workflows/validate.yml`.

## Re-running the Setup Script

If the kind cluster is ever deleted or becomes unavailable, you can re-run the setup script at any time:

```bash
bash .devcontainer/setup-mock-k8s.sh
```

The script is idempotent — it skips cluster creation when the `mock` cluster already exists.

## Checking Cluster Status

```bash
# List running kind clusters
kind get clusters

# Check cluster nodes
kubectl get nodes
```

## Tools Available

| Tool | Purpose |
|------|---------|
| `kind` | Creates and manages the local Kubernetes cluster |
| `kubectl` | Interacts with the cluster (dry-run validation, CRD installation, etc.) |
| `kustomize` | Builds Kubernetes manifests from overlays |
| `skaffold` | Deploys manifests to a real cluster |
