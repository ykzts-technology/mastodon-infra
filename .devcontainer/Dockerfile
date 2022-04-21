# [Choice] Go version (use -bullseye variants on local arm64/Apple Silicon): 1, 1.16, 1.17, 1-bullseye, 1.16-bullseye, 1.17-bullseye, 1-buster, 1.16-buster, 1.17-buster
ARG VARIANT=1-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/go:0-${VARIANT}

COPY library-scripts/*.sh /tmp/library-scripts/

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y graphviz \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

ARG INSTALL_DOCKER="true"
RUN if [ "${INSTALL_DOCKER}" = "true" ]; then \
        bash /tmp/library-scripts/docker-debian.sh "true" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
    else \
        echo '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# Install Terraform, tflint, Terragrunt
ARG TERRAFORM_VERSION=0.12.16
ARG TFLINT_VERSION=0.8.2
ARG TERRAGRUNT_VERSION=0.28.1
RUN bash /tmp/library-scripts/terraform-debian.sh "${TERRAFORM_VERSION}" "${TFLINT_VERSION}" "${TERRAGRUNT_VERSION}" \
    && rm -rf /tmp/library-scripts

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment the next lines to use go get to install anything else you need
# USER vscode
# RUN go get -x <your-dependency-or-tool>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

ARG KIND_VERSION=0.12.0
ARG SKAFFOLD_VERSION=1.38.0
ARG KUSTOMIZE_VERSION=4.5.4
ARG KO_VERSION=0.11.2
RUN if [ "${KIND_VERSION}" != "none" ]; then \
        curl -Lo kind https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64 \
        && install kind /usr/local/bin \
        && rm kind; \
    fi \
    && if [ "${SKAFFOLD_VERSION}" != "none" ]; then \
        curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-amd64 \
        && install skaffold /usr/local/bin \
        && rm skaffold; \
    fi \
    && if [ "${KUSTOMIZE_VERSION}" != "none" ]; then \
        curl -Lo kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 \
        && install kustomize /usr/local/bin \
        && rm kustomize; \
    fi \
    && if [ "${KO_VERSION}" != "none" ]; then \
        curl -L https://github.com/google/ko/releases/download/v${KO_VERSION}/ko_${KO_VERSION}_Linux_x86_64.tar.gz | tar xzf - ko \
        && install ko /usr/local/bin \
        && rm ko; \
    fi
