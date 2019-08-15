#!/bin/bash -eu -o pipefail

# Lame for now, but we need a button to push
# Love Z

# TODO: Consider a base image for use by the dynamic and static builds.

docker build ./dynamic --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t instana/agent
docker build ./static --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t "instana/agent-static"

docker tag instana/agent instana/agent:${INSTANA_AGENT_RELEASE}
docker tag instana/agent instana/agent:latest

docker tag "instana/agent-static" "instana/agent-static:${INSTANA_AGENT_RELEASE}"
docker tag "instana/agent-static" "instana/agent-static:latest"

docker tag instana/agent containers.instana.io/instana/release/agent/dynamic:${INSTANA_AGENT_RELEASE}
docker tag instana/agent containers.instana.io/instana/release/agent/dynamic:latest

docker tag "instana/agent-static" "containers.instana.io/instana/release/agent/static:${INSTANA_AGENT_RELEASE}"
docker tag "instana/agent-static" "containers.instana.io/instana/release/agent/static:latest"

