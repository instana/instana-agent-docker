FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

LABEL name="instana-agent" \
      vendor="Instana Inc." \
      release="1" \
      summary="Instana APM agent" \
      description="Instana APM agent"

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

ADD docker.repo /etc/yum.repos.d/docker.repo

RUN curl -sSL https://packages.instana.io/Instana.gpg -o /tmp/Instana.gpg && \
    rpm --import /tmp/Instana.gpg && \
    echo -e "[instana-agent]\nname=Instana\nbaseurl=https://_:${FTP_PROXY}@packages.instana.io/agent/generic/x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.instana.io/Instana.gpg\nsslverify=1" > /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf install instana-agent-dynamic docker-ce-cli iptables iproute util-linux python3 && \
    curl -L https://github.com/hairyhenderson/gomplate/releases/download/v3.8.0/gomplate_linux-amd64-slim -o /usr/bin/gomplate && \
    echo "847f7d9fc0dc74c33188c2b0d0e9e4ed9204f67c36da5aacbab324f8bfbf29c9 /usr/bin/gomplate" | sha256sum -c - > /dev/null && \
    chmod 755 /usr/bin/gomplate && \
    curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/bin/jq && \
    echo "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44 /usr/bin/jq" | sha256sum -c - > /dev/null && \
    chmod 755 /usr/bin/jq && \
    curl -L https://github.com/opencontainers/runc/releases/download/v1.0.0-rc92/runc.amd64 -o /usr/bin/runc && \
    echo "256bd490a55a1939a4c9cd15c043404b79a86429ee04129c00d33dab8c0cf040 /usr/bin/runc" | sha256sum -c - > /dev/null && \
    chmod 755 /usr/bin/runc && \
    rm -rf /tmp/* /etc/yum.repos.d/Instana-Agent.repo /etc/yum.repos.d/docker.repo && \
    microdnf clean all

ADD licenses/* /licenses/
ADD help.1 /help.1

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
