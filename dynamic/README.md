# Instana Agent Dynamic Docker Image

This build of the Instana agent requires access to the publicly hosted Instana maven repository in order to download sensors.
It may require proxy settings for egress access to:

* the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self-hosted Instana installation or for the Instana SaaS
* the [Instana Artifactory repository](https://artifact-public.instana.io/), unless you set up a mirror and use the `INSTANA_MVN_REPOSITORY_URL` to direct the Instana Agent to use it

Additional documentation about the usage of this image is available on the [Installing the Host Agent on Docker](https://www.instana.com/docs/setup_and_manage/host_agent/on/docker) documentation.

## Building

Needs Docker 18.09 or higher:

```sh
DOCKER_BUILDKIT=1 docker build --build-arg TARGETPLATFORM=<PLATFORM> --build-arg DOWNLOAD_KEY=<DOWNLOAD_KEY> --no-cache . -t instana-agent
```

Supported values of `<PLATFORM>`:

* `linux/amd64`
* `linux/arm64`
* `linux/s390x`

**Note:** For backwards compatibility reasons, the `<DOWNLOAD_KEY>` can also be passed via the `FTP_PROXY` build argument, and using buildkit, which is activated via the `DOCKER_BUILDKIT=1` environment variable, is optional.

## Download Prebuilt Image

The Instana Agent Dynamic Docker image can be found on:

* Docker Hub as [https://hub.docker.com/r/instana/agent/](https://hub.docker.com/r/instana/agent)
* `containers.instana.io` as `containers.instana.io/instana/release/agent/dynamic:latest`, which you can pull with the following commands:

```sh
docker login containers.instana.io -u _ -p <agent_key>

docker pull containers.instana.io/instana/release/agent/dynamic:latest
```
