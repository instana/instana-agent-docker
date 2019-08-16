#!/bin/bash

if [ "${INSTANA_AGENT_KEY}" == "" ]; then
  echo "Please add the INSTANA_AGENT_KEY environment variable and provide your Agent Key!"
  exit 1
fi

if [ "${INSTANA_AGENT_ENDPOINT}" == "" ]; then
  echo "Please add the INSTANA_AGENT_ENDPOINT environment variable to let the agent know where to connect to!"
  exit 1
fi

if [ "${INSTANA_AGENT_ENDPOINT_PORT}" == "" ]; then
  echo "Please add the INSTANA_AGENT_ENDPOINT_PORT environment variable to let the agent know where to connect to!"
  exit 1
fi

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
  /opt/instana/agent/etc/instana/configuration.yaml \
  /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg

cp /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg.template /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg
touch /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg

cp /root/configuration.yaml /opt/instana/agent/etc/instana
cp /root/org.ops4j.pax.logging.cfg /opt/instana/agent/etc
cat /root/com.instana.agent.main.sender.Backend.cfg.tmpl | gomplate > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.sender.Backend.cfg

echo "origin = static_docker" >> /opt/instana/agent/etc/instana/com.instana.agent.bootstrap.AgentBootstrap.cfg

if [ ! -z "${INSTANA_AGENT_HTTP_LISTEN}" ]; then
  echo -e "\nhttp.listen = ${INSTANA_AGENT_HTTP_LISTEN}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
fi

if [ ! -z "${INSTANA_AGENT_MODE}" ]; then
  if [ "${INSTANA_AGENT_MODE}" = "AWS" ]; then

    INSTANA_AWS_REGION_CONFIG=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document --connect-timeout 2 | awk -F\" '/region/ {print $4}')
    
    if [ $? != 0 ]; then
      log_error "Error querying AWS metadata."
      exit 1
    fi

    export INSTANA_AWS_REGION_CONFIG

    ROLES_FOUND=false

    if ! curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ --connect-timeout 2 | grep 404&> /dev/null; then
      ROLES_FOUND=true
    fi

    if [ "$ROLES_FOUND" = "false" ]; then
      if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY not exported, and no IAM instance role detected to allow AWS API access."
        exit 1
      fi
    fi

    echo -e "\nmode = INFRASTRUCTURE" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
  else
    echo -e "\nmode = ${INSTANA_AGENT_MODE}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
  fi
fi

if [ -d /host/proc ]; then
  export INSTANA_AGENT_PROC_PATH=/host/proc
fi

echo "Starting Instana Agent ..."
exec /opt/instana/agent/bin/karaf daemon
