# syntax=docker/dockerfile:experimental

FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest AS build-gomplate

ENV LANG=C.UTF-8 \
    GOMPLATE_VERSION="3.8.0" \
    GOMPLATE_SHA256="d32817821a7b083b0aeadf29c2aea17e3384b6b619f3a6285150db1914b94c89  v3.8.0.tar.gz"

RUN microdnf install tar gzip wget golang make findutils && \
    mkdir -p /root/go/src/github.com/hairyhenderson && \
    cd /root/go/src/github.com/hairyhenderson && \
    wget https://github.com/hairyhenderson/gomplate/archive/v${GOMPLATE_VERSION}.tar.gz && \
    echo "${GOMPLATE_SHA256}" | sha256sum --check && \
    tar xzf v${GOMPLATE_VERSION}.tar.gz && \
    mv gomplate-${GOMPLATE_VERSION} gomplate && \
    cd gomplate/ && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o gomplate_amd64 ./cmd/gomplate && \
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o gomplate_arm64 ./cmd/gomplate && \
    GOOS=linux GOARCH=s390x CGO_ENABLED=0 go build -o gomplate_s390x ./cmd/gomplate && \
    mkdir -p /usr/bin/linux/{amd64,arm64,s390x} && \
    chmod u+x gomplate_* && \
    cp gomplate_amd64 /usr/bin/linux/amd64/gomplate && \
    cp gomplate_arm64 /usr/bin/linux/arm64/gomplate && \
    cp gomplate_s390x /usr/bin/linux/s390x/gomplate

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS instana-agent

ARG TARGETPLATFORM='linux/amd64'
ARG CLASSIFIER=''
ARG DOWNLOAD_KEY
# This is for backwards compatibility for end users that build their own images
ARG FTP_PROXY

RUN curl -sSL https://packages.instana.io/Instana.gpg -o /tmp/Instana.gpg && \
    rpm --import /tmp/Instana.gpg && \
    export arch=$(case "${TARGETPLATFORM}" in 'linux/amd64') echo 'x86_64' ;; 'linux/arm64') echo 'aarch64' ;; 'linux/s390x') echo 's390x' ;; esac) && \
    [[ -z "${FTP_PROXY}" ]] || DOWNLOAD_KEY="${FTP_PROXY}" && \
    [[ "${arch}" != "s390x" ]] || CLASSIFIER="-j9" && \
    [[ "${CLASSIFIER}x" = 'x' ]] || [[ "${CLASSIFIER#-}" != "${CLASSIFIER}" ]] || CLASSIFIER="-${CLASSIFIER}" && \
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

RUN microdnf install --nodocs procps iptables iproute util-linux python3 jq findutils \
    && rm -rf /tmp/* \
    && microdnf clean all

# s390x does not carry the Docker cli
RUN ( \
        [[ "${TARGETPLATFORM}" != 'linux/s390x' ]] \
        && echo -e '[docker-ce-stable]\nname=Docker CE Stable - $basearch\nbaseurl=https://download.docker.com/linux/centos/8/$basearch/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg' > /etc/yum.repos.d/docker.repo \
        && microdnf install --nodocs docker-ce-cli \
        && rm -rf /tmp/* /etc/yum.repos.d/docker.repo \
        && microdnf clean all \
    ) || true

# containerd cli is only available for amd64
ENV CONTAINERD_VERSION=1.4.3 \
    CONTAINERD_SHA256="34a161e3f459fd337b03141a339eeb1a56c5c811922fe72012d2dac9fa5542f1  containerd-1.4.3-linux-amd64.tar.gz"
RUN ( \
        [[ "${TARGETPLATFORM}" = 'linux/amd64' ]] \
        && microdnf install --nodocs tar gzip wget \
        && cd /tmp \
        && wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
        && echo "${CONTAINERD_SHA256}" | sha256sum --check \
        && tar -xzf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz  && mv bin/* /usr/local/bin \
        && microdnf remove tar gzip wget \
        && microdnf clean all \
    ) || true

# Install runc on the x86_64, the other platforms are not supported
RUN ( \
        [[ "${TARGETPLATFORM}" = 'linux/amd64' ]] \
        && curl -L --fail --show-error --silent https://github.com/opencontainers/runc/releases/download/v1.0.0-rc92/runc.amd64 -o /usr/bin/runc \
        && echo '256bd490a55a1939a4c9cd15c043404b79a86429ee04129c00d33dab8c0cf040 /usr/bin/runc' | sha256sum -c - > /dev/null \
        && chmod 755 /usr/bin/runc \
    ) || true

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
    configuration.yaml \
    com.instana.agent.main.sender.Backend-1.cfg.tmpl \
    com.instana.agent.main.config.UpdateManager.cfg.tmpl \
    com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl \
    mvn-settings.xml.tmpl \
    /root/

ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent

ENTRYPOINT ["./bin/run.sh"]
