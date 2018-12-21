FROM alpine:3.7

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

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --update-cache --update gomplate@edge bash ca-certificates curl docker@edge containerd@testing inotify-tools && \
    curl -sSL https://packages.instana.io/Instana.rsa -o /etc/apk/keys/instana.rsa.pub && \
    echo "https://_:${FTP_PROXY}@packages.instana.io/agent/apk/generic" >> /etc/apk/repositories && \
    apk update && \
    apk add instana-agent-dynamic && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    sed -i '$d' /etc/apk/repositories && \
    rm -rf /tmp/* /var/cache/apk/*

ADD THIRD_PARTY /opt/instana/agent
ADD org.ops4j.pax.logging.cfg /root/
ADD org.ops4j.pax.url.mvn.cfg /root/
ADD configuration.yaml /root/
ADD com.instana.agent.main.sender.Backend.cfg.tmpl /root/
ADD mvn-settings.xml.tmpl /root/
ADD run.sh /opt/instana/agent/bin

WORKDIR /opt/instana/agent

ENTRYPOINT ["./bin/run.sh"]
