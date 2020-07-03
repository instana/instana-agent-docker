#!/bin/bash

set -e

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

if [ -z "${INSTANA_DOWNLOAD_KEY}" ]; then
  INSTANA_DOWNLOAD_KEY="${INSTANA_AGENT_KEY}"
fi

if  [ -z "${INSTANA_MVN_REPOSITORY_URL}" ]; then
  INSTANA_MVN_REPOSITORY_URL='https://artifact-public.instana.io'
fi

if  [ -z "${INSTANA_MVN_REPOSITORY_FEATURES_PATH}" ]; then
  INSTANA_MVN_REPOSITORY_FEATURES_PATH='artifactory/features-public@id=features@snapshots@snapshotsUpdate=always'
fi

if  [ -z "${INSTANA_MVN_REPOSITORY_SHARED_PATH}" ]; then
  INSTANA_MVN_REPOSITORY_SHARED_PATH='artifactory/shared@id=shared@snapshots@snapshotsUpdate=never'
fi

if  [ -z "${INSTANA_LOG_LEVEL}" ]; then
  INSTANA_LOG_LEVEL='INFO'
fi
if [ -n "${INSTANA_LOG_LEVEL}" ]; then
  case ${INSTANA_LOG_LEVEL} in
    INFO|DEBUG|TRACE|ERROR|OFF)
      ;;
    *)
      echo "Log level is set to '${INSTANA_LOG_LEVEL}' which is unsupported, falling back to 'INFO'"
      INSTANA_LOG_LEVEL=INFO
      ;;
  esac
fi

# Take over Agent Proxy variables if no Repository Proxy is enabled
case ${INSTANA_REPOSITORY_PROXY_ENABLED} in
  y|Y|yes|Yes|YES|1|true)
	# Don't do anything, use existing variables
	;;
  *)
	INSTANA_REPOSITORY_PROXY_HOST=${INSTANA_AGENT_PROXY_HOST}
	INSTANA_REPOSITORY_PROXY_PORT=${INSTANA_AGENT_PROXY_PORT}
	INSTANA_REPOSITORY_PROXY_PROTOCOL=${INSTANA_AGENT_PROXY_PROTOCOL}
	INSTANA_REPOSITORY_PROXY_USER=${INSTANA_AGENT_PROXY_USER}
	INSTANA_REPOSITORY_PROXY_PASSWORD=${INSTANA_AGENT_PROXY_PASSWORD}
	INSTANA_REPOSITORY_PROXY_USE_DNS=${INSTANA_AGENT_PROXY_USE_DNS}
	;;
esac

rm -rf /tmp/* /opt/instana/agent/etc/org.ops4j.pax.logging.cfg \
  /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg  \
  /opt/instana/agent/etc/instana/configuration.yaml \
  /opt/instana/agent/etc/instana/com.instana.agent.main.config.UpdateManager.cfg \
  /opt/instana/agent/etc/instana/com.instana.agent.bootstrap.AgentBootstrap.cfg

cp /root/configuration.yaml /opt/instana/agent/etc/instana
cp /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg.template /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
cat /root/org.ops4j.pax.logging.cfg.tmpl | gomplate > /opt/instana/agent/etc/org.ops4j.pax.logging.cfg
cat /root/mvn-settings.xml.tmpl | gomplate > /opt/instana/agent/etc/mvn-settings.xml
cat /root/org.ops4j.pax.url.mvn.cfg.tmpl | gomplate > /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg
cat /root/com.instana.agent.main.sender.Backend-1.cfg.tmpl | gomplate > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.sender.Backend-1.cfg
cat /root/com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl | gomplate > \
  /opt/instana/agent/etc/instana/com.instana.agent.bootstrap.AgentBootstrap.cfg
cat /root/com.instana.agent.main.config.UpdateManager.cfg.tmpl | gomplate > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.config.UpdateManager.cfg

if [ -n "${INSTANA_AGENT_HTTP_LISTEN}" ]; then
  echo -e "\nhttp.listen = ${INSTANA_AGENT_HTTP_LISTEN}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
fi

if [ "${INSTANA_AGENT_MODE}" = "AWS" ]; then
  echo "AWS mode configured"

  ###
  # Discover which platform we are running on
  ###
  if [ -n "${ECS_CONTAINER_METADATA_URI}" ]; then
    PLATFORM='ECS'
  elif curl -s http://169.254.169.254/latest/meta-data/ --connect-timeout 2 --fail; then
    PLATFORM='EC2'
  else
    PLATFORM='UNKNOWN'
  fi

  ###
  # Retrieve region
  ###
  if [ -n "${INSTANA_AWS_REGION_CONFIG}" ]; then
    echo "AWS region configured via environment: ${INSTANA_AWS_REGION_CONFIG}"
  else
    case "${PLATFORM}" in
    'ECS')
      AWS_AVAILABILITY_ZONE=$(curl -s "${ECS_CONTAINER_METADATA_URI}/task" --connect-timeout 2 --fail | jq -r '.AvailabilityZone')

      if [[ "${AWS_AVAILABILITY_ZONE}" =~ ^([a-z]+-[a-z]+-[0-9])* ]]; then
        INSTANA_AWS_REGION_CONFIG="${BASH_REMATCH[1]}"
      else
        echo "Cannot parse AWS region from the Availability Zone '${AWS_AVAILABILITY_ZONE}' retrieved from the '${ECS_CONTAINER_METADATA_URI}/task' endpoint"
        exit 1
      fi
      ;;
    'EC2')
      INSTANA_AWS_REGION_CONFIG=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document --connect-timeout 2 --fail | jq -r '.region')
      ;;
    *)
      if [ -n "${AWS_DEFAULT_REGION}" ]; then
        echo "Using the default AWS region '${AWS_DEFAULT_REGION}' set in the environment via the 'AWS_DEFAULT_REGION' environment variable."
      else
        echo "Platform not recognized: this agent does not seem to run on EC2 or ECS. Set the 'INSTANA_AWS_REGION_CONFIG' environment variable."
        exit 1
      fi
      ;;
    esac

    if [ -z "${INSTANA_AWS_REGION_CONFIG}" ]; then
      echo "Could not retrieve the AWS region from the AWS metadata"
      exit 1
    fi

    echo "Discovered AWS region: ${INSTANA_AWS_REGION_CONFIG}"

    export INSTANA_AWS_REGION_CONFIG
  fi

  ###
  # Look up roles
  ###
  readonly EC2_CREDENTIALS_ENDPOINT='http://169.254.169.254/latest/meta-data/iam/security-credentials/'
  case "${PLATFORM}" in
  'EC2')
    if curl -s "${EC2_CREDENTIALS_ENDPOINT}" --connect-timeout 2 --fail; then
      echo "IAM roles found using EC2's '${EC2_CREDENTIALS_ENDPOINT}' endpoint."
    fi
    ;;
  # 'ECS')  # On ECS, our agent does not know yet how to use IAM roles exposed there, so we need to go the ACCESS_KEY route
  *)
    if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
      echo "Neither 'AWS_ACCESS_KEY_ID' nor 'AWS_SECRET_ACCESS_KEY' environment variables are exported, and no IAM instance role is detected to allow AWS API access. Please configure either the 'AWS_ACCESS_KEY_ID' or the 'AWS_SECRET_ACCESS_KEY' environment variables."
      exit 1
    fi
    ;;
  esac
fi

# Normalize the Agent mode to those that are actually used by the agent itself, i.e., APM and INFRASTRUCTURE
if [ "${INSTANA_AGENT_MODE}" != "APM" ]; then
  INSTANA_AGENT_MODE='INFRASTRUCTURE'
fi

echo -e "\nmode = ${INSTANA_AGENT_MODE}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg

if [ -d /host/proc ]; then
  export INSTANA_AGENT_PROC_PATH=/host/proc
fi

if [ -f /root/crashReport.sh ] && [ -z "${INSTANA_DISABLE_CRASH_REPORT}" ]; then
  cp /root/crashReport.sh /opt/instana/agent/crashReport.sh

  # Rewrite the Karaf script to add FLAGS for hooking in the crashReport.sh script. Adding them simply to JAVA_OPTS
  # does not work, as the parameters contain spaces which will turn them into separate arguments.
  # Therefore instead modify the script directly so we can properly include the quotes and spaces are escaped correctly.
  FLAGS="-XX:OnError=\"/opt/instana/agent/crashReport.sh %p\" -XX:ErrorFile=/opt/instana/agent/hs_err.log -XX:OnOutOfMemoryError=\"/opt/instana/agent/crashReport.sh %p 'Out of Memory'\""
  sed -i "s|\ \${JAVA_OPTS}\ |\ \${JAVA_OPTS}\ ${FLAGS} |g" /opt/instana/agent/bin/karaf
fi

echo "Starting Instana Agent ..."
exec /opt/instana/agent/bin/karaf daemon
