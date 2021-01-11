## instana-agent-docker

This repo contains the Dockerfiles relating to the various containers Instana
supports.

 * dynamic - is the image used in the Helm chart and is suggested as the
             preferred image for a standard install.
 * static - the static image that contains all run-time dependencies ideal for
            network access restricted environments such as airgapped servers.
 * rhel - is the RHEL Atomic based image which is suggested for environments
          where a RHEL base image is required.

## Building

The agent docker images are built on agent-jenkins and updates are posted to the private #tech-agent-delivery channel in Slack.  Ask SRE for access to that channel if needed.

The QA team automatically builds PRs in [GCP Cloudbuild](https://console.cloud.google.com/cloud-build/builds?folder=&organizationId=&project=instana-qa) and the (eventually) built images land on [GCP GCR](https://gcr.io/instana-qa/github.com/instana/instana-agent-docker) for testing. Merges to master then get built on ops-jenkins again.

Cross platform build for s390x

```shell
docker buildx build \
  --secret id=download_key,src=download_key \
  --platform linux/s390x \
  --build-arg TARGETPLATFORM=linux/s390x \
  -t $MYIMAGE:$MYTAG dynamic
```
