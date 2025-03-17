FROM mcr.microsoft.com/devcontainers/base:1-bullseye@sha256:0b3c5ffb423d8ed2a7698d6a2bcf49f0fec8c6bb867f7d878d5af16e8ddae47d

 # renovate: datasource=github-releases depName=skaffold packageName=GoogleContainerTools/skaffold
ARG SKAFFOLD_VERSION=2.14.1
# renovate: datasource=github-releases depName=kustomize packageName=kubernetes-sigs/kustomize extractVersion=^kustomize/v(?<version>.+)$
ARG KUSTOMIZE_VERSION=5.6.0

RUN \
  if [ "${SKAFFOLD_VERSION}" != "none" ]; then \
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-amd64 \
    && install skaffold /usr/local/bin \
    && rm skaffold; \
  fi \
  && if [ "${KUSTOMIZE_VERSION}" != "none" ]; then \
    curl -Lo kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && tar xf kustomize.tar.gz \
    && install kustomize /usr/local/bin \
    && rm kustomize; \
  fi
