# build kustomize
FROM golang:1.14 as build-kustomize

ARG KUSTOMIZE_VERSION

RUN apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/kubernetes-sigs/kustomize.git -b v${KUSTOMIZE_VERSION} \
    && cd kustomize/kustomize \
    && go install

# build sops
FROM golang:1.14 as build-sops

ARG SOPS_VERSION

RUN apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/mozilla/sops.git -b v${SOPS_VERSION} \
    && cd sops/cmd/sops \
    && go install

# base image
ARG VERSION

FROM sminamot/actions-runner:${VERSION} as base

FROM base as base-amd64
ARG KUBECTL_ARCH=amd64

FROM base as base-arm
ARG KUBECTL_ARCH=arm

# main image
FROM base-$TARGETARCH
ARG KUBECTL_VERSION

RUN wget -O /usr/localbin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl \
    && chmod +x /usr/localbin/kubectl

COPY --from=build-kustomize /go/bin/kustomize /usr/local/bin/kustomize
COPY --from=build-sops /go/bin/sops /usr/local/bin/sops
