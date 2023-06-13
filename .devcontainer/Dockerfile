FROM mcr.microsoft.com/devcontainers/base:1-bullseye

ARG SKAFFOLD_VERSION=2.2.0
ARG KUSTOMIZE_VERSION=5.0.1
RUN \
  if [ "${SKAFFOLD_VERSION}" != "none" ]; then \
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-amd64 \
    && install skaffold /usr/local/bin \
    && rm skaffold; \
  fi \
  && if [ "${KUSTOMIZE_VERSION}" != "none" ]; then \
    curl -Lo kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 \
    && install kustomize /usr/local/bin \
    && rm kustomize; \
  fi
