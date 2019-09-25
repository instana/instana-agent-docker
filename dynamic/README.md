# Instana Agent Docker - Dynamic Image

This build of the instana agent includes requires access to the publicly hosted Instana maven repository in order to download sensors. It requires proxy settings for egress access to the ${INSTANA_AGENT_ENDPOINT}, which may either be for your self hosted Instana installation or for the Instana SaaS, and for access to the Instana maven repository.

## Building

```sh
docker build ./ --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache
```

## Usage

This image has several configuration options activated via environment variables and mounted volumes, see [Configuration via environment](https://docs.instana.io/quick_start/agent_setup/container/docker) for the details.

## Docker Hub

The image can be found on docker hub [https://hub.docker.com/r/instana/agent/](https://hub.docker.com/r/instana/agent).
