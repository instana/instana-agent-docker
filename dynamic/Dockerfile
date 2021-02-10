FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

# Setup of dependencies we need inside the container
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg2 ca-certificates curl && \
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list && \
    apt-key adv --fetch-keys "https://download.docker.com/linux/ubuntu/gpg" && \
    apt-get update && \
    apt-get install -y --no-install-recommends inotify-tools docker-ce-cli containerd python3-pip iptables iproute2 jq && \
    apt-get upgrade -y && \
    curl -L https://github.com/hairyhenderson/gomplate/releases/download/v3.8.0/gomplate_linux-amd64-slim -o /usr/bin/gomplate && \
    echo "847f7d9fc0dc74c33188c2b0d0e9e4ed9204f67c36da5aacbab324f8bfbf29c9 /usr/bin/gomplate" | sha256sum -c - > /dev/null && \
    chmod 755 /usr/bin/gomplate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Configuration up to this line needs to be in sync with static/Dockerfile
# Dynamic & static agent start to diverge here:
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

# Setup to install the Instana package
RUN echo "deb [arch=amd64] https://_:${FTP_PROXY}@packages.instana.io/agent/deb generic main" > /etc/apt/sources.list.d/instana-agent.list && \
    apt-key adv --fetch-keys "https://packages.instana.io/Instana.gpg" && \
    apt-get update && \
    apt-get install -y instana-agent-dynamic && \
    apt-get purge -y gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /etc/apt/sources.list.d/instana-agent.list && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    sed -i -e 's/^root:[^:]*:/root:!locked:/' /etc/shadow

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
