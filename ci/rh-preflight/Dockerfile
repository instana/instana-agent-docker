#
# (c) Copyright IBM Corp. 2022
# (c) Copyright Instana Inc.
#
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS build



WORKDIR /
COPY oc kubectl /usr/local/bin/
# install GO
RUN cd /tmp \
    && export GO_VERSION="1.18" \
  	&& export GO_BINARY="go${GO_VERSION}.linux-amd64.tar.gz" \
    && microdnf install tar gzip wget make findutils socat \
    && wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    && gunzip "${GO_BINARY}" \
    && tar xf "${GO_BINARY//.gz/}" \
    && mv go /usr/local/bin \
    && rm -rf /tmp/* \
    && microdnf clean all
ENV PATH=$PATH:/usr/local/bin/go/bin
ENV GOPATH=/usr/local/bin/go/bin
# install OperatorSdk
RUN cd /tmp \
    && wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/operator-sdk/4.9.0/operator-sdk-v1.10.1-ocp-linux-x86_64.tar.gz \
    && tar xvf operator-sdk-v1.10.1-ocp-linux-x86_64.tar.gz \
    && chmod +x operator-sdk \
    && mv ./operator-sdk /usr/local/bin/operator-sdk \
    && rm -rf /tmp/*
# install preflight
RUN microdnf install tar gzip unzip git gcc \
    && cd /tmp \
    && git clone https://github.com/redhat-openshift-ecosystem/openshift-preflight \
    && cd openshift-preflight \
    && make build \
    && mv preflight /usr/local/bin/ \
    && rm -rf /tmp/* \
    && microdnf clean all

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

LABEL name="redhat-preflight" \
      vendor="Instana Inc." \
      release="1" \
      summary="Redhat Preflight components" \
      description="Redhat Preflight components"

COPY --from=build /usr/local/bin/preflight /usr/local/bin

# install Docker
RUN echo -e '[docker-ce-stable]\nname=Docker CE Stable - $basearch\nbaseurl=https://download.docker.com/linux/centos/8/$basearch/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg' > /etc/yum.repos.d/docker.repo \
    && microdnf install --nodocs docker-ce-cli docker-ce iproute \
    && rm -rf /tmp/* /etc/yum.repos.d/docker.repo \
    && microdnf clean all

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]