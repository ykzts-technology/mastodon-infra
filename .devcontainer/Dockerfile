FROM mcr.microsoft.com/devcontainers/base:2-bullseye@sha256:fb17cc95abb5489d81d129c8e5f58c7c1985d009397f2718a7d1d4c26f94b302

 # renovate: datasource=github-releases depName=skaffold packageName=GoogleContainerTools/skaffold
ARG SKAFFOLD_VERSION=2.18.3
# renovate: datasource=github-releases depName=kustomize packageName=kubernetes-sigs/kustomize extractVersion=^kustomize/v(?<version>.+)$
ARG KUSTOMIZE_VERSION=5.8.1
# renovate: datasource=github-releases depName=kind packageName=kubernetes-sigs/kind
ARG KIND_VERSION=0.31.0
# renovate: datasource=github-releases depName=kubectl packageName=kubernetes/kubernetes extractVersion=^v(?<version>.+)$
ARG KUBECTL_VERSION=1.35.2

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
  fi \
  && if [ "${KIND_VERSION}" != "none" ]; then \
    curl -fsSLo kind "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64" \
    && curl -fsSLo kind.sha256 "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64.sha256sum" \
    && echo "$(awk '{print $1}' kind.sha256)  kind" | sha256sum -c - \
    && install kind /usr/local/bin \
    && rm kind kind.sha256; \
  fi \
  && if [ "${KUBECTL_VERSION}" != "none" ]; then \
    curl -fsSLo kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && curl -fsSLo kubectl.sha256 "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" \
    && echo "$(awk '{print $1}' kubectl.sha256)  kubectl" | sha256sum -c - \
    && install kubectl /usr/local/bin \
    && rm kubectl kubectl.sha256; \
  fi
