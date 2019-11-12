FROM ubuntu:18.04

# Setup of dependencies we need inside the container
RUN apt-get update && \
    apt-get install -y gnupg2 ca-certificates curl && \
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" > /etc/apt/sources.list.d/docker.list && \
    apt-key adv --fetch-keys "https://download.docker.com/linux/ubuntu/gpg" && \
    apt-get update && \
    apt-get install -y inotify-tools docker-ce-cli containerd python-pip iptables && \
    apt-get clean

# Setup to install the Instana package
RUN echo "deb [arch=amd64] https://_:${FTP_PROXY}@packages.instana.io/agent/deb generic main" > /etc/apt/sources.list.d/instana-agent.list && \
    apt-key adv --fetch-keys "https://packages.instana.io/Instana.gpg" && \
    apt-get update && \
    apt-get install -y gomplate && \
    apt-get clean

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
    INSTANA_AGENT_PROXY_USE_DNS=""

RUN apt-get install -y instana-agent-static

# Cleanup
RUN apt-get purge -y gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /etc/apt/sources.list.d/instana-agent.list && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

COPY org.ops4j.pax.logging.cfg configuration.yaml com.instana.agent.main.sender.Backend.cfg.tmpl com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl /root/
ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent

ENTRYPOINT ["./bin/run.sh"]
