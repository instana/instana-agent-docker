# Instana Agent Static Docker Image

This build of the Instana agent includes all sensors. It requires proxy settings only for egress access to the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self-hosted Instana installation or for the Instana SaaS.

## Building

Needs Docker 18.09 or higher:

```sh
DOCKER_BUILDKIT=1 docker build --build-arg TARGETPLATFORM=<PLATFORM> --build-arg DOWNLOAD_KEY=<DOWNLOAD_KEY> --no-cache . -t containers.instana.io/instana/release/agent/static
```

Supported values of `<PLATFORM>`:

* `linux/amd64`
* `linux/arm64`
* `linux/s390x`

**Note:** For backwards compatibility reasons, the `<DOWNLOAD_KEY>` can also be passed via the `FTP_PROXY` build argument, and using buildkit, which is activated via the `DOCKER_BUILDKIT=1` environment variable, is optional.

## Download Prebuilt Image

The Instana Agent static Docker image can be found on `containers.instana.io` and can be downloaded using the following commands:

```sh
docker login containers.instana.io -u _ -p <agent_key>

docker pull containers.instana.io/instana/release/agent/static:latest
```
