# syntax=docker/dockerfile:experimental

#
# (c) Copyright IBM Corp. 2021
# (c) Copyright Instana Inc.
#

FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest AS build-gomplate

ENV LANG=C.UTF-8

RUN export GO_VERSION="1.19.4" && \
    export GO_SHAR256="c9c08f783325c4cf840a94333159cc937f05f75d36a8b307951d5bd959cf2ab8 go${GO_VERSION}.linux-amd64.tar.gz" && \
    export GO_BINARY="go${GO_VERSION}.linux-amd64.tar.gz" && \
    export GOMPLATE_VERSION="3.11.3" && \
    export GOMPLATE_SHA256="4f26895921e52e0515b273659508802676aafa4765cc3751c383b27eb0e9dca1  v${GOMPLATE_VERSION}.tar.gz" && \
    microdnf install tar gzip wget make findutils && \
    cd /tmp && \
    wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    echo "${GO_SHAR256}" | sha256sum --check && \
    gunzip "${GO_BINARY}" && \
    tar xf "${GO_BINARY//.gz/}" && \
    mv go /usr/local/bin && \
    rm -rf /tmp/* && \
    mkdir -p /root/go/src/github.com/hairyhenderson && \
    cd /root/go/src/github.com/hairyhenderson && \
    wget https://github.com/hairyhenderson/gomplate/archive/v${GOMPLATE_VERSION}.tar.gz && \
    echo "${GOMPLATE_SHA256}" | sha256sum --check && \
    tar xzf v${GOMPLATE_VERSION}.tar.gz && \
    mv gomplate-${GOMPLATE_VERSION} gomplate && \
    cd gomplate/ && \
    /usr/local/bin/go/bin/go get -u golang.org/x/crypto && \
    /usr/local/bin/go/bin/go get -u github.com/aws/aws-sdk-go && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 /usr/local/bin/go/bin/go build -o gomplate_amd64 ./cmd/gomplate && \
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 /usr/local/bin/go/bin/go build -o gomplate_arm64 ./cmd/gomplate && \
    GOOS=linux GOARCH=s390x CGO_ENABLED=0 /usr/local/bin/go/bin/go build -o gomplate_s390x ./cmd/gomplate && \
    GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 /usr/local/bin/go/bin/go build -o gomplate_ppc64le ./cmd/gomplate && \
    mkdir -p /usr/bin/linux/{amd64,arm64,s390x,ppc64le} && \
    chmod u+x gomplate_* && \
    cp gomplate_amd64 /usr/bin/linux/amd64/gomplate && \
    cp gomplate_arm64 /usr/bin/linux/arm64/gomplate && \
    cp gomplate_s390x /usr/bin/linux/s390x/gomplate && \
    cp gomplate_ppc64le /usr/bin/linux/ppc64le/gomplate

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS instana-agent

ARG TARGETPLATFORM='linux/amd64'
ARG CLASSIFIER=''
ARG DOWNLOAD_KEY
# This is for backwards compatibility for end users that build their own images
ARG FTP_PROXY

RUN microdnf update && curl -sSL https://packages.instana.io/Instana.gpg -o /tmp/Instana.gpg && \
    rpm --import /tmp/Instana.gpg && \
    export arch=$(case "${TARGETPLATFORM}" in 'linux/amd64') echo 'x86_64' ;; 'linux/arm64') echo 'aarch64' ;; 'linux/s390x') echo 's390x' ;; 'linux/ppc64le') echo 'ppc64le' ;; esac) && \
    [[ -z "${FTP_PROXY}" ]] || DOWNLOAD_KEY="${FTP_PROXY}" && \
    [[ "${arch}" != "s390x" && "${arch}" != "ppc64le" ]] || CLASSIFIER="-j9" && \
    [[ "${CLASSIFIER}x" = "x" ]] || [[ "${CLASSIFIER#-}" != "${CLASSIFIER}" ]] || CLASSIFIER="-${CLASSIFIER}" && \
    echo -e "[instana-agent]\nname=Instana\nbaseurl=https://_:${DOWNLOAD_KEY}@packages.instana.io/agent/generic/${arch}\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.instana.io/Instana.gpg\nsslverify=1" > /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf install "instana-agent-dynamic${CLASSIFIER}" && \
    mv /opt/instana/agent/licenses /licenses && \
    rm -rf /tmp/* /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf clean all

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

LABEL name="instana-agent" \
      vendor="Instana Inc." \
      release="1" \
      summary="Instana APM agent" \
      description="Instana APM agent"

ARG TARGETPLATFORM='linux/amd64'

RUN microdnf upgrade \
    && microdnf install --nodocs --noplugins hostname procps iproute util-linux python3 jq findutils less tar gzip socat libseccomp \
    && cd /tmp/ \
    && microdnf download runc \
    && rpm -i runc*.rpm --nodeps \
    && rm -rf /tmp/* \
    && microdnf clean all

RUN pip3 install pip

# !! NOTE: the following sections contain inverse IF-statements to make sure commands succeed
# when not applicable but breaks when any command fails. The regular " IF ... && <command> || true " won't work.

# s390x and ppc64le do not carry the Docker cli (and neither do RHEL official repositories)
RUN [[ "${TARGETPLATFORM}" = 'linux/s390x' || "${TARGETPLATFORM}" = 'linux/ppc64le' ]] || ( \
        echo -e '[docker-ce-stable]\nname=Docker CE Stable - $basearch\nbaseurl=https://download.docker.com/linux/centos/8/$basearch/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg' > /etc/yum.repos.d/docker.repo \
        && microdnf install --nodocs docker-ce-cli \
        && rm -rf /tmp/* /etc/yum.repos.d/docker.repo \
        && rm -rf /usr/libexec/docker/cli-plugins/* \
        && microdnf clean all \
    )

# containerd cli is only available for amd64
RUN export CONTAINERD_BASE_URL="https://github.com/containerd/containerd/releases" \
    && [[ "${TARGETPLATFORM}" != 'linux/amd64' ]] || ( \
       export CONTAINERD_VERSION=$(curl -w '\n' -L -s -H 'Accept: application/json' "${CONTAINERD_BASE_URL}/latest" | sed -e 's/.*"tag_name":"v\([0-9\.]*\)".*/\1/') \
       && export CONTAINERD_BINARY="containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" \
       && echo "Containerd version: ${CONTAINERD_VERSION}" \
       && cd /tmp \
       && curl -L --fail --show-error --silent "${CONTAINERD_BASE_URL}/download/v${CONTAINERD_VERSION}/${CONTAINERD_BINARY}" --output "${CONTAINERD_BINARY}" \
       && echo $(curl -L --fail --show-error --silent "${CONTAINERD_BASE_URL}/download/v${CONTAINERD_VERSION}/${CONTAINERD_BINARY}.sha256sum" | awk '{print $1}') "${CONTAINERD_BINARY}" | sha256sum --check \
       && gunzip "${CONTAINERD_BINARY}" \
       && tar xf "${CONTAINERD_BINARY//.gz/}" \
       && mv bin/* /usr/local/bin \
       && rm -rf /tmp/* \
)

# On s390x, install docker ce and containerd from docker static s390x build
RUN [[ "${TARGETPLATFORM}" != 'linux/s390x' ]] || ( \
        cd /tmp \
        && curl -L --fail --show-error --silent https://download.docker.com/linux/static/stable/s390x/docker-18.06.3-ce.tgz -o /tmp/docker-18.06.3-ce.tgz \
        && gunzip docker-18.06.3-ce.tgz \
        && tar -xvf docker-18.06.3-ce.tar \
        && mv docker/docker /usr/local/bin/docker \
        && mv docker/docker-containerd /usr/local/bin/containerd \
        && mv docker/docker-containerd-shim /usr/local/bin/containerd-shim \
        && rm -rf /tmp/* \
    )

# On ppc64le, install docker ce and containerd from docker static ppc64le build
RUN [[ "${TARGETPLATFORM}" != 'linux/ppc64le' ]] || ( \
        cd /tmp \
        && curl -L --fail --show-error --silent https://download.docker.com/linux/static/stable/ppc64le/docker-18.06.3-ce.tgz -o /tmp/docker-18.06.3-ce.tgz \
        && gunzip docker-18.06.3-ce.tgz \
        && tar -xvf docker-18.06.3-ce.tar \
        && mv docker/docker /usr/local/bin/docker \
        && mv docker/docker-containerd /usr/local/bin/containerd \
        && mv docker/docker-containerd-shim /usr/local/bin/containerd-shim \
        && rm -rf /tmp/* \
    )

# "//" -> replace all of "\/" (escaped slash) next "/" is the delimiter between pattern and replacement "-"
# e.g. linux/amd64 -> linux-amd64
RUN export ARCH=${TARGETPLATFORM//\//-} \
    && export CRICTL_VERSION=v$(curl -w '\n' -L -s -H 'Accept: application/json' https://github.com/kubernetes-sigs/cri-tools/releases/latest | sed -e 's/.*"tag_name":"v\([0-9\.]*\)".*/\1/') \
    && export CRICTL_BINARY="crictl-${CRICTL_VERSION}-${ARCH}.tar.gz" \
    && echo "Crictl version: ${CRICTL_VERSION}" \
    && cd /tmp \
    && curl -L --fail --show-error --silent https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/${CRICTL_BINARY} --output crictl.tar.gz \
    && echo $(curl -L --fail --show-error --silent https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/${CRICTL_BINARY}.sha256 | awk '{print $1}') crictl.tar.gz | sha256sum --check \
    && gunzip crictl.tar.gz \
    && tar xf crictl.tar \
    && mv crictl /usr/local/bin/crictl \
    && chmod +x /usr/local/bin/crictl \
    && rm -rf /tmp/*

# Install iptables 1.4.21 on x86_64 to carry out service mesh bypass scripts. See https://www.notion.so/instana/ServiceMesh-Bypass-435d8f15300140aa80468b52aef1bf4a
RUN export IPTABLES_X86_SHA256="c260f06c1e71850dc7d69a4fc54f05a6edf5dfac7bc7e27f38a9f22f774f5d01  iptables-1.4.21-35.el7.x86_64.rpm" \
    && [[ "${TARGETPLATFORM}" != 'linux/amd64' ]] || ( \
        microdnf install libnetfilter_conntrack \
        && cd /tmp \
        && curl -L --fail --show-error --silent http://mirror.centos.org/centos/7/os/x86_64/Packages/iptables-1.4.21-35.el7.x86_64.rpm -o /tmp/iptables-1.4.21-35.el7.x86_64.rpm \
        && echo "${IPTABLES_X86_SHA256}" | sha256sum --check > /dev/null \
        && rpm --force -i /tmp/iptables-1.4.21-35.el7.x86_64.rpm \
        && rm -rf /tmp/* \
        && microdnf clean all \
    )

# Install iptables 1.4.21 on aarch64 to carry out service mesh bypass scripts. See https://www.notion.so/instana/ServiceMesh-Bypass-435d8f15300140aa80468b52aef1bf4a
RUN export IPTABLES_ARM64_SHA256="53cc2bd47614463eb76ffc727ec838b9d92e0239d68ab5cd38fb2e5f18380431  iptables-1.4.21-35.el7.aarch64.rpm" \
    && [[ "${TARGETPLATFORM}" != 'linux/arm64' ]] || ( \
        microdnf install libnetfilter_conntrack \
        && cd /tmp \
        && curl -L --fail --show-error --silent http://mirror.centos.org/altarch/7/os/aarch64/Packages/iptables-1.4.21-35.el7.aarch64.rpm -o /tmp/iptables-1.4.21-35.el7.aarch64.rpm \
        && echo "${IPTABLES_ARM64_SHA256}" | sha256sum --check > /dev/null \
        && rpm --force -i /tmp/iptables-1.4.21-35.el7.aarch64.rpm \
        && rm -rf /tmp/* \
        && microdnf clean all \
    )

# Install iptables for s390x, default version, since 1.4.21 is not available for s390x
RUN [[ "${TARGETPLATFORM}" != 'linux/s390x' ]] || ( \
        microdnf install --nodocs iptables \
        && rm -rf /tmp/* \
        && microdnf clean all \
    )

# Install iptables 1.4.21 on ppc64le to carry out service mesh bypass scripts. See https://www.notion.so/instana/ServiceMesh-Bypass-435d8f15300140aa80468b52aef1bf4a
RUN export IPTABLES_PPC64LE_SHA256="1eb70870bd717d010127a0d6a6bd61d1e621120b770d7c9e9bde125b08d9bd71  iptables-1.4.21-35.el7.ppc64le.rpm" \
    && [[ "${TARGETPLATFORM}" != 'linux/ppc64le' ]] || ( \
        microdnf install libnetfilter_conntrack \
        && cd /tmp \
        && curl -L --fail --show-error --silent http://mirror.centos.org/altarch/7/os/ppc64le/Packages/iptables-1.4.21-35.el7.ppc64le.rpm -o /tmp/iptables-1.4.21-35.el7.ppc64le.rpm \
        && echo "${IPTABLES_PPC64LE_SHA256}" | sha256sum --check > /dev/null \
        && rpm --force -i /tmp/iptables-1.4.21-35.el7.ppc64le.rpm \
        && rm -rf /tmp/* \
        && microdnf clean all \
    )

# Install Tini, to handle signals (SIGTERM / SIGKILL) correctly in our container since we need to run the Agent from a
# script and cannot 'exec' to replace it. That would kill the container on restarts of the Agent.
RUN export ARCH=$(case "${TARGETPLATFORM}" in 'linux/amd64') echo 'amd64' ;; 'linux/arm64') echo 'arm64' ;; 'linux/s390x') echo 's390x' ;; 'linux/ppc64le') echo 'ppc64le' ;; esac) \
    && export TINI_VERSION=$(curl -L -s -H 'Accept: application/json' https://github.com/krallin/tini/releases/latest | sed -e 's/.*"tag_name":"v\([0-9\.]*\)".*/\1/') \
    && echo "Tini version: ${TINI_VERSION}" \
    && cd /tmp \
    && curl -L --fail --show-error --silent https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${ARCH} -o tini-${ARCH} \
    && echo $(curl -L --fail --show-error --silent https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${ARCH}.sha256sum) | sha256sum --check \
    && mv tini-${ARCH} /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini \
    && rm -rf /tmp/*

COPY --from=build-gomplate /usr/bin/${TARGETPLATFORM}/gomplate /usr/bin/gomplate

# Dynamic & static agent start to diverge here:

# The content of the help file is different
ADD help.1 /help.1

# Configuration up to this line needs to be in sync with static/Dockerfile
COPY --from=instana-agent /opt/instana /opt/instana
COPY --from=instana-agent /licenses /licenses
COPY --from=instana-agent /usr/lib/tmpfiles.d/instana-agent.conf /usr/lib/tmpfiles.d/instana-agent.conf

ENV LANG=C.UTF-8 \
    INSTANA_AGENT_KEY="" \
    INSTANA_DOWNLOAD_KEY="" \
    INSTANA_AGENT_ENDPOINT="" \
    INSTANA_AGENT_ENDPOINT_PORT="" \
    INSTANA_AGENT_ZONE="" \
    INSTANA_AGENT_TAGS="" \
    INSTANA_AGENT_HTTP_LISTEN="" \
    INSTANA_AGENT_UPDATES_VERSION="" \
    INSTANA_AGENT_UPDATES_FREQUENCY="" \
    INSTANA_AGENT_UPDATES_TIME="" \
    INSTANA_AGENT_MODE="APM" \
    INSTANA_AGENT_PROXY_HOST="" \
    INSTANA_AGENT_PROXY_PASSWORD="" \
    INSTANA_AGENT_PROXY_PORT="" \
    INSTANA_AGENT_PROXY_PROTOCOL="" \
    INSTANA_AGENT_PROXY_USER="" \
    INSTANA_AGENT_PROXY_USE_DNS="" \
    INSTANA_GIT_REMOTE_REPOSITORY="" \
    INSTANA_GIT_REMOTE_BRANCH="" \
    INSTANA_GIT_REMOTE_USERNAME="" \
    INSTANA_GIT_REMOTE_PASSWORD="" \
    INSTANA_GIT_LOG_COUNT="10" \
    INSTANA_REPOSITORY_PROXY_ENABLED="false" \
    INSTANA_REPOSITORY_PROXY_HOST="" \
    INSTANA_REPOSITORY_PROXY_PORT="" \
    INSTANA_REPOSITORY_PROXY_PROTOCOL="" \
    INSTANA_REPOSITORY_PROXY_USER="" \
    INSTANA_REPOSITORY_PROXY_PASSWORD="" \
    INSTANA_REPOSITORY_PROXY_USE_DNS="" \
    INSTANA_MVN_REPOSITORY_URL="" \
    INSTANA_MVN_REPOSITORY_FEATURES_PATH="" \
    INSTANA_MVN_REPOSITORY_SHARED_PATH="" \
    INSTANA_USE_MEMORY_CALCULATOR="true" \
    INSTANA_LOG_LEVEL=""

COPY org.ops4j.pax.logging.cfg.tmpl \
    org.ops4j.pax.url.mvn.cfg.tmpl \
    com.instana.agent.main.sender.Backend-1.cfg.tmpl \
    com.instana.agent.main.config.UpdateManager.cfg.tmpl \
    com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl \
    mvn-settings.xml.tmpl \
    /opt/instana/agent/etc/

COPY configuration.yaml \
    /root/

ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent
VOLUME ["/opt/instana/agent/etc/instana"]
ENTRYPOINT ["/usr/local/bin/tini", "-s", "-g", "--", "./bin/run.sh"]
