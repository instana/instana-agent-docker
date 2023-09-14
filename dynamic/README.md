# Instana Agent Dynamic Docker Image

This build of the Instana agent requires access to the publicly hosted Instana maven repository in order to download sensors.
It may require proxy settings for egress access to:

* the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self-hosted Instana installation or for the Instana SaaS
* the [Instana Artifactory repository](https://artifact-public.instana.io/), unless you set up a mirror and use the `INSTANA_MVN_REPOSITORY_URL` to direct the Instana Agent to use it

Additional documentation about the usage of this image is available on the [Installing the Host Agent on Docker](https://www.ibm.com/docs/en/instana-observability/current?topic=agents-installing-host-agent-docker) documentation.

## Building

**Note**: Needs Docker 18.09 or higher. Also [Experimental
features](https://github.com/docker/cli/blob/master/experimental/README.md) need to be enabled and
[Buildx](https://github.com/docker/buildx/) CLI plugin needs to be installed.

```sh
export TARGETPLATFORM=linux/s390x
export DOWNLOAD_KEY=my-key

echo "${DOWNLOAD_KEY}" > ${HOME}/.INSTANA_DOWNLOAD_KEY

docker buildx build --no-cache \
  --secret id=DOWNLOAD_KEY,src=${HOME}/.INSTANA_DOWNLOAD_KEY \
  --platform="${TARGETPLATFORM}" \
  --build-arg "TARGETPLATFORM=${TARGETPLATFORM}" \
  -t instana/agent \
  .

rm -f ${HOME}/.INSTANA_DOWNLOAD_KEY
```

Supported values of `<PLATFORM>`:

* `linux/amd64`
* `linux/arm64`
* `linux/s390x`

**Note:** For backwards compatibility reasons, the `<DOWNLOAD_KEY>` can also be passed via the `FTP_PROXY` build argument.

## Download Prebuilt Image

The Instana Agent Dynamic Docker image can be found on:

* Docker Hub as [https://hub.docker.com/r/instana/agent/](https://hub.docker.com/r/instana/agent)
* `containers.instana.io` as `containers.instana.io/instana/release/agent/dynamic:latest`, which you can pull with the following commands:

```sh
docker login containers.instana.io -u _ -p <agent_key>

docker pull containers.instana.io/instana/release/agent/dynamic:latest
```
