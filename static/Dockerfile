FROM ubuntu:21.04

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
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup to install the Instana package
RUN echo "deb [arch=amd64] https://_:${FTP_PROXY}@packages.instana.io/agent/deb generic main" > /etc/apt/sources.list.d/instana-agent.list && \
    apt-key adv --fetch-keys "https://packages.instana.io/Instana.gpg" && \
    apt-get update && \
    apt-get install -y --no-install-recommends gomplate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configuration up to this line needs to be in sync with dynamic/Dockerfile
# Dynamic & static agent start to diverge here:
ENV LANG=C.UTF-8 \
    INSTANA_AGENT_KEY="" \
    INSTANA_AGENT_ENDPOINT="" \
    INSTANA_AGENT_ENDPOINT_PORT="" \
    INSTANA_AGENT_ZONE="" \
    INSTANA_AGENT_TAGS="" \
    INSTANA_AGENT_HTTP_LISTEN="" \
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
    INSTANA_LOG_LEVEL=""

RUN apt-get update && \
    apt-get install -y instana-agent-static && \
    apt-get purge -y gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /etc/apt/sources.list.d/instana-agent.list && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

COPY org.ops4j.pax.logging.cfg.tmpl \
    configuration.yaml \
    com.instana.agent.main.sender.Backend-1.cfg.tmpl \
    com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl \
    /root/

ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent

ENTRYPOINT ["./bin/run.sh"]
