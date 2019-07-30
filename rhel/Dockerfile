FROM registry.access.redhat.com/rhel7-atomic:latest

LABEL name="instana-agent" \
      vendor="Instana Inc." \
      version="1.0.2" \
      release="1" \
      summary="Instana APM agent" \
      description="Instana APM agent"

ENV LANG=C.UTF-8 \
    INSTANA_AGENT_KEY="" \
    INSTANA_AGENT_ENDPOINT="" \
    INSTANA_AGENT_ENDPOINT_PORT="" \
    INSTANA_AGENT_ZONE="" \
    INSTANA_AGENT_TAGS="" \
    INSTANA_AGENT_HTTP_LISTEN="" \
    INSTANA_AGENT_PROXY_HOST="" \
    INSTANA_AGENT_PROXY_PORT="" \
    INSTANA_AGENT_PROXY_PROTOCOL="" \
    INSTANA_AGENT_PROXY_USER="" \
    INSTANA_AGENT_PROXY_PASSWORD="" \
    INSTANA_AGENT_PROXY_USE_DNS=""

RUN curl -sSL https://packages.instana.io/Instana.gpg -o /tmp/Instana.gpg && \
    rpm --import /tmp/Instana.gpg && \
    echo -e "[instana-agent]\nname=Instana\nbaseurl=https://_:${FTP_PROXY}@packages.instana.io/agent/generic/x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1gpgkey=https://packages.instana.io/Instana.gpg\nsslverify=1" > /etc/yum.repos.d/Instana-Agent.repo && \
    microdnf install instana-agent-dynamic && \
    rm -rf /tmp/* /etc/yum.repos.d/Instana-Agent.repo /etc/yum.repos.d/Docker.repo && \
    microdnf clean all

ADD licenses/* /licenses/
ADD help.1 /help.1

ADD gomplate /usr/bin/gomplate
ADD docker /usr/bin/docker
ADD org.ops4j.pax.logging.cfg /root/
ADD org.ops4j.pax.url.mvn.cfg /root/
ADD configuration.yaml /root/
ADD com.instana.agent.main.sender.Backend.cfg.tmpl /root/
ADD mvn-settings.xml.tmpl /root/
ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent

ENTRYPOINT ["./bin/run.sh"]
