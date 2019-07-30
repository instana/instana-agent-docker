#!/bin/bash

if [[ "${INSTANA_KEY}" == "" ]] && [[ "${INSTANA_AGENT_KEY}" == "" ]]; then
  echo "Please add the INSTANA_AGENT_KEY environment variable and provide your Agent Key!"
  exit 1
fi

if [[ "${INSTANA_HOST}" == "" ]] && [[ "${INSTANA_AGENT_ENDPOINT}" == "" ]]; then
  echo "Please add the INSTANA_AGENT_ENDPOINT environment variable to let the agent know where to connect to!"
  exit 1
fi

if [[ "${INSTANA_PORT}" == "" ]] && [[ "${INSTANA_AGENT_ENDPOINT_PORT}" == "" ]]; then
  echo "Please add the INSTANA_AGENT_ENDPOINT_PORT environment variable to let the agent know where to connect to!"
  exit 1
fi

[ -z "${INSTANA_AGENT_KEY}" ] && [ -n "${INSTANA_KEY}" ] && \
  INSTANA_AGENT_KEY="${INSTANA_KEY}"

[ -z "${INSTANA_AGENT_ENDPOINT}" ] && [ -n "${INSTANA_HOST}" ] && \
  INSTANA_AGENT_ENDPOINT="${INSTANA_HOST}"

[ -z "${INSTANA_AGENT_ENDPOINT_PORT}" ] && [ -n "${INSTANA_PORT}" ] && \
  INSTANA_AGENT_ENDPOINT_PORT="$INSTANA_PORT"

[ -z "${INSTANA_TAGS}" ] && [ -n "${INSTANA_AGENT_TAGS}" ] && \
  INSTANA_TAGS="${INSTANA_AGENT_TAGS}" && export INSTANA_TAGS

[ -z "${INSTANA_ZONE}" ] && [ -n "${INSTANA_AGENT_ZONE}" ] && \
  INSTANA_ZONE="${INSTANA_AGENT_ZONE}" && export INSTANA_ZONE

if [ -n "${INSTANA_AGENT_PROXY_USE_DNS}" ]; then
  case ${INSTANA_AGENT_PROXY_USE_DNS} in
    y|Y|yes|Yes|YES|1|true) 
      INSTANA_AGENT_PROXY_USE_DNS=1
      ;;
    *)
      INSTANA_AGENT_PROXY_USE_DNS=0
      ;;
  esac
fi

rm -rf /tmp/* /opt/instana/agent/etc/org.ops4j.pax.logging.cfg \
  /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg  \
  /opt/instana/agent/etc/instana/configuration.yaml

cp /root/org.ops4j.pax.logging.cfg /opt/instana/agent/etc
cp /root/org.ops4j.pax.url.mvn.cfg /opt/instana/agent/etc
cp /root/configuration.yaml /opt/instana/agent/etc/instana
cp /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg.template /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
cat /root/mvn-settings.xml.tmpl | gomplate > /opt/instana/agent/etc/mvn-settings.xml
cat /root/com.instana.agent.main.sender.Backend.cfg.tmpl | gomplate > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.sender.Backend.cfg

echo "origin = public_docker" >> /opt/instana/agent/etc/instana/com.instana.agent.bootstrap.AgentBootstrap.cfg

if [[ "${INSTANA_AGENT_HTTP_LISTEN}" != "" ]]; then
  echo -e "\nhttp.listen = ${INSTANA_AGENT_HTTP_LISTEN}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
fi

if [ -d /host/proc ]; then
  export INSTANA_AGENT_PROC_PATH=/host/proc
fi

echo "Starting Instana Agent ..."
exec /opt/instana/agent/bin/karaf daemon
