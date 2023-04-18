#!/bin/bash

#
# (c) Copyright IBM Corp. 2021
# (c) Copyright Instana Inc.
#

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

if  [ -z "${INSTANA_LOG_LEVEL}" ]; then
  INSTANA_LOG_LEVEL='INFO'
fi
if [ -n "${INSTANA_LOG_LEVEL}" ]; then
  case ${INSTANA_LOG_LEVEL} in
    INFO|DEBUG|TRACE|WARN|ERROR|OFF)
      ;;
    *)
      echo "Log level is set to '${INSTANA_LOG_LEVEL}' which is unsupported, falling back to 'INFO'"
      INSTANA_LOG_LEVEL=INFO
      ;;
  esac
fi

if [ "${INSTANA_GIT_REMOTE_REPOSITORY}" == "" ]; then
  unset INSTANA_GIT_REMOTE_REPOSITORY
fi

if [ "${INSTANA_GIT_REMOTE_BRANCH}" == "" ]; then
  unset INSTANA_GIT_REMOTE_BRANCH
fi

if [ "${INSTANA_GIT_REMOTE_USERNAME}" == "" ]; then
  unset INSTANA_GIT_REMOTE_USERNAME
fi

# Empty string is a valid value for INSTANA_GIT_REMOTE_PASSWORD
# so don't unset it like the other environment variables

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

readonly CANONICAL_DOCKER_SOCKET_PATH='/var/run/docker.sock'
# Adjust Docker socket for VMware TKGI
if [ ! -S "${CANONICAL_DOCKER_SOCKET_PATH}" ]; then
  echo "Docker socket not found at ${CANONICAL_DOCKER_SOCKET_PATH}"

  readonly KUBO_DOCKER_SOCKET_PATH='/var/vcap/sys/run/docker/docker.sock'
  if [ -S "${KUBO_DOCKER_SOCKET_PATH}" ]; then
    # Adjust Docker socket for VMware TKGI and older PKS systems
    echo "Docker socket found at ${KUBO_DOCKER_SOCKET_PATH}, linking it under ${CANONICAL_DOCKER_SOCKET_PATH}"
    ln -sf "${KUBO_DOCKER_SOCKET_PATH}" "${CANONICAL_DOCKER_SOCKET_PATH}"
  fi
fi

rm -rf /tmp/* /opt/instana/agent/etc/org.ops4j.pax.logging.cfg \
  /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg  \
  /opt/instana/agent/etc/instana/configuration.yaml

cp /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg.template /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg

ln -s /root/configuration.yaml /opt/instana/agent/etc/instana/configuration.yaml

gomplate < /opt/instana/agent/etc/org.ops4j.pax.logging.cfg.tmpl > /opt/instana/agent/etc/org.ops4j.pax.logging.cfg
gomplate < /opt/instana/agent/etc/com.instana.agent.main.sender.Backend-1.cfg.tmpl > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.sender.Backend-1.cfg

gomplate < /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg.tmpl > /opt/instana/agent/etc/org.ops4j.pax.url.mvn.cfg
gomplate < /opt/instana/agent/etc/mvn-settings.xml.tmpl > /opt/instana/agent/etc/mvn-settings.xml
gomplate < /opt/instana/agent/etc/com.instana.agent.bootstrap.AgentBootstrap.cfg.tmpl > \
  /opt/instana/agent/etc/instana/com.instana.agent.bootstrap.AgentBootstrap.cfg
gomplate < /opt/instana/agent/etc/com.instana.agent.main.config.UpdateManager.cfg.tmpl > \
  /opt/instana/agent/etc/instana/com.instana.agent.main.config.UpdateManager.cfg

if [ -n "${INSTANA_AGENT_HTTP_LISTEN}" ]; then
  echo -e "\nhttp.listen = ${INSTANA_AGENT_HTTP_LISTEN}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg
fi

if [ "${INSTANA_AGENT_MODE}" = 'AWS' ]; then
  echo 'AWS mode configured'

  ###
  # Discover which platform we are running on
  ###
  if [ -n "${ECS_CONTAINER_METADATA_URI}" ]; then
    PLATFORM='ECS'
    echo 'Running on ECS'
  elif curl -s http://169.254.169.254/latest/meta-data/ --connect-timeout 2 --fail 2>&1 /dev/null; then
    PLATFORM='EC2'
    echo 'Running on EC2'
  else
    PLATFORM='UNKNOWN'
    echo 'Cannot recognize the platform; it is neither ECS nor EC2'
  fi

  ###
  # Retrieve region
  ###
  if [ -n "${INSTANA_AWS_REGION_CONFIG}" ]; then
    echo "AWS region configured via environment: ${INSTANA_AWS_REGION_CONFIG}"
  else
    case "${PLATFORM}" in

    'ECS')
      if ! curl -s "${ECS_CONTAINER_METADATA_URI}/task" --connect-timeout 2 --fail -o /tmp/ecs_data; then
        echo "Cannot retrieve metadata from the '${ECS_CONTAINER_METADATA_URI}/task' endpoint. Aborting startup."
        exit 1
      fi

      if AWS_AVAILABILITY_ZONE=$(jq -e -r '.AvailabilityZone' < /tmp/ecs_data); then
        # The -e flag of jq will make it fail on purpose, if the data do not contain the 'AvailabilityZone' key
        readonly ARN_REGEXP='^([a-z]+-[a-z]+-[0-9])*'
        if [[ "${AWS_AVAILABILITY_ZONE}" =~ ${ARN_REGEXP} ]]; then
          echo "AWS region parsed from the availability zone"
          INSTANA_AWS_REGION_CONFIG="${BASH_REMATCH[1]}"
        else
          echo "Cannot parse the AWS region from the availability zone '${AWS_AVAILABILITY_ZONE}' retrieved from the '${ECS_CONTAINER_METADATA_URI}/task' endpoint. Aborting startup."
          cat /tmp/ecs_data
          exit 1
        fi
      elif INSTANA_AWS_REGION_CONFIG=$(jq -e -r '.Cluster' | awk -F ':' '{ print $5 }' < /tmp/ecs_data); then
        # The -e flag of jq will make it fail on purpose, if the data do not contain the 'Cluster' key
        echo "Metadata endpoint did not return the availability zone; parsing the region from the ARN."
      else
        echo "Cannot parse the AWS region from the data retrieved from the '${ECS_CONTAINER_METADATA_URI}/task' endpoint. Aborting startup."
        cat /tmp/ecs_data
        exit 1
      fi
      ;;

    'EC2')
      readonly EC2_METADATA_ENDPOINT='http://169.254.169.254/latest/dynamic/instance-identity/document'

      if ! curl -s "${EC2_METADATA_ENDPOINT}" --connect-timeout 2 --fail -o /tmp/ec2_data; then
        echo "Cannot retrieve metadata from the '${EC2_METADATA_ENDPOINT}' endpoint. Aborting startup."
        exit 1
      fi

      if ! INSTANA_AWS_REGION_CONFIG=$(jq -e -r '.region' < /tmp/ec2_data); then
        echo "The metadata endpoint did not return the 'region' key. Aborting startup."
        cat /tmp/ecs_data
        exit 1
      fi
      ;;

    *)
      if [ -n "${AWS_DEFAULT_REGION}" ]; then
        echo "Using the default AWS region '${AWS_DEFAULT_REGION}' set in the environment via the 'AWS_DEFAULT_REGION' environment variable."
        INSTANA_AWS_REGION_CONFIG="${AWS_DEFAULT_REGION}"
      else
        echo "Platform not recognized: this agent does not seem to run on EC2 or ECS. Set the 'INSTANA_AWS_REGION_CONFIG' environment variable. Aborting startup."
        exit 1
      fi
      ;;
    esac

    if [ -z "${INSTANA_AWS_REGION_CONFIG}" ]; then
      echo "Could not retrieve the AWS region from the AWS metadata. Aborting startup."
      exit 1
    fi

    echo "Discovered AWS region: ${INSTANA_AWS_REGION_CONFIG}"
    export INSTANA_AWS_REGION_CONFIG
  fi

  if [ "${PLATFORM}" = 'UNKNOWN' ]; then
    if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
      echo "The platform is not recognized (this agent does not seem to run on EC2 or ECS) and neither 'AWS_ACCESS_KEY_ID' nor 'AWS_SECRET_ACCESS_KEY' environment variables are exported. AWS Services monitoring might just not work. If so, please configure either the 'AWS_ACCESS_KEY_ID' or the 'AWS_SECRET_ACCESS_KEY' environment variables."
    fi
  fi
fi

# Normalize the Agent mode to those that are actually used by the agent itself, i.e., OFF, APM and INFRASTRUCTURE
case "${INSTANA_AGENT_MODE}" in
  'AWS')
    INSTANA_AGENT_MODE='INFRASTRUCTURE'
    ;; # The AWS agent mode is infra + AWS sensor setup
  'KUBERNETES')
    ;;
  'INFRASTRUCTURE')
    ;;
  'APM')
    ;;
  'OFF')
    ;;
  *)
    echo "Unknown agent mode ${INSTANA_AGENT_MODE}"
    exit 1;
esac

echo -e "\nmode = ${INSTANA_AGENT_MODE}" >> /opt/instana/agent/etc/instana/com.instana.agent.main.config.Agent.cfg

if [ -d /host/proc ]; then
  export INSTANA_AGENT_PROC_PATH=/host/proc
fi

# In containerized environments, we want to exit on Out of Memory so the Agent will be rescheduled
export JAVA_OPTS="-XX:+ExitOnOutOfMemoryError ${JAVA_OPTS}"

echo "Starting Instana Agent ..."
exec /opt/instana/agent/bin/karaf server
