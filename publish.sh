#!/bin/bash -eu -o pipefail

docker push instana/agent:${INSTANA_AGENT_RELEASE}
docker push instana/agent:latest

docker push "instana/agent-static:${INSTANA_AGENT_RELEASE}"
docker push "instana/agent-static:latest"

docker push containers.instana.io/instana/release/agent/dynamic:${INSTANA_AGENT_RELEASE}
docker push containers.instana.io/instana/release/agent/dynamic:latest

docker push "containers.instana.io/instana/release/agent/static:${INSTANA_AGENT_RELEASE}"
docker push "containers.instana.io/instana/release/agent/static:latest"
