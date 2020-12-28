Instana Agent Dynamic Docker
============================

This build of the Instana agent requires access to the publicly hosted Instana maven repository in order to download sensors. It requires proxy settings for egress access to the `${INSTANA_AGENT_ENDPOINT}`, which may either be for your self hosted Instana installation or for the Instana SaaS, and for access to the Instana maven repository.

Building
========

```sh
echo <DOWNLOAD_KEY> > download_key
DOCKER_BUILDKIT=1 docker build --secret id=download_key,src=download_key --no-cache . -t instana-agent
rm download_key
```

Docker Hub
==========

The image can be found on docker hub [https://hub.docker.com/r/instana/agent/](https://hub.docker.com/r/instana/agent).
