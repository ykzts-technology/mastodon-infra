#!/bin/bash
set -euo pipefail

# renovate: datasource=docker depName=kindest/node
KIND_NODE_IMAGE="kindest/node:v1.31.4"
CLUSTER_NAME="mock"

# Wait for Docker daemon to be ready (required when using docker-in-docker)
echo "Waiting for Docker daemon..."
if ! timeout 60 sh -c 'until docker info &>/dev/null 2>&1; do sleep 2; done'; then
  echo "ERROR: Docker daemon did not become ready within 60 seconds." >&2
  exit 1
fi

# Create kind cluster if it doesn't already exist
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists, skipping creation."
else
  echo "Creating kind cluster '${CLUSTER_NAME}' (${KIND_NODE_IMAGE})..."
  kind create cluster --name "${CLUSTER_NAME}" --image "${KIND_NODE_IMAGE}"
fi

# Install GKE CRDs so that server-side dry-run validation accepts GKE-specific resources
echo "Installing GKE CRDs..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "${REPO_ROOT}/k8s/mock/crds.yaml"

echo ""
echo "Mock Kubernetes server is ready."
echo "Run server-side dry-run validation with:"
echo "  kustomize build k8s/overlays/development | kubectl apply --dry-run=server -f -"
echo "  kustomize build k8s/overlays/production  | kubectl apply --dry-run=server -f -"
