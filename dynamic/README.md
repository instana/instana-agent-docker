# Instana Agent Dynamic Docker Image

This build of the Instana agent requires access to the publicly hosted Instana maven repository in order to download sensors.
It may require proxy settings for egress access to:

* the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self-hosted Instana installation or for the Instana SaaS
* the [Instana Artifactory repository](https://artifact-public.instana.io/), unless you set up a mirror and use the `INSTANA_MVN_REPOSITORY_URL` to direct the Instana Agent to use it

Additional documentation about the usage of this image is available on the [Installing the Host Agent on Docker](https://www.instana.com/docs/setup_and_manage/host_agent/on/docker) documentation.

## Building

```sh
echo <DOWNLOAD_KEY> > download_key
DOCKER_BUILDKIT=1 docker build --secret id=download_key,src=download_key --no-cache . -t instana-agent
rm download_key
```

## Docker Hub

The image can be found on docker hub [https://hub.docker.com/r/instana/agent/](https://hub.docker.com/r/instana/agent).
