# Instana Agent Static Docker Image

This build of the Instana agent includes all sensors. It requires proxy settings only for egress access to the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self-hosted Instana installation or for the Instana SaaS.

## Building

Needs Docker 18.09 or higher:

```sh
echo <DOWNLOAD_KEY> > download_key
DOCKER_BUILDKIT=1 docker build --secret id=download_key,src=download_key --no-cache . -t containers.instana.io/instana/release/agent/static
rm download_key
```

## Download Prebuilt Image

The static image can be found on containers.instana.io and can be downloaded using the following commands:

```sh
docker login containers.instana.io -u _ -p <agent_key>

docker pull containers.instana.io/instana/release/agent/static:latest
```

## OS Architecture Specifics

For Linux s390x see: [s390x Build Documentation](README_s390x.md)
