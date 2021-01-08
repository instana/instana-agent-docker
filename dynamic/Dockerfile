FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS build-gomplate

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
    cd gomplate/ && make && \
    cp bin/gomplate /usr/bin/gomplate && \
    chmod u+x /usr/bin/gomplate

# syntax = docker/dockerfile:1.2

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

LABEL name="instana-agent" \
      vendor="Instana Inc." \
      release="1" \
      summary="Instana APM agent" \
      description="Instana APM agent"

ARG arch="x86_64"

ENV arch=${arch}

ADD docker.repo /etc/yum.repos.d/docker.repo

RUN microdnf install docker-ce-cli iptables iproute util-linux python3 jq && \
    rm -rf /tmp/* /etc/yum.repos.d/docker.repo && \
    microdnf clean all

# Install runc and jq on the platforms that are supported
RUN ([[ "${arch}" = 'x86_64' || "${arch}" = 'aarch64' ]] && microdnf install runc && microdnf clean all) || true

COPY --from=build-gomplate /usr/bin/gomplate /usr/bin/gomplate

# Dynamic & static agent start to diverge here:

# The content of the help file is different
ADD help.1 /help.1

# Configuration up to this line needs to be in sync with static/Dockerfile
RUN --mount=type=secret,id=download_key,dst=/run/secrets/download_key,required=true \
    curl -sSL https://packages.instana.io/Instana.gpg -o /tmp/Instana.gpg && \
    rpm --import /tmp/Instana.gpg && \
    echo -e "[instana-agent]\nname=Instana\nbaseurl=https://_:$(cat /run/secrets/download_key)@packages.instana.io/agent/generic/${arch}\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.instana.io/Instana.gpg\nsslverify=1" > /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf install instana-agent-dynamic && \
    rm -rf /tmp/* /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf clean all && \
    ln -s /opt/instana/agent/licenses /licenses

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
