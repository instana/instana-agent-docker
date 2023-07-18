# Instana Agent Docker Images

This repo contains the Dockerfiles relating to the various Instana agent containers.

* [`dynamic`](./dynamic/) is the image used by default in the Helm chart and is suggested as the preferred image for a standard install; the `dynamic` image container a dynamic Instana agent, which is capable of updating itself automatically as new versions of its components are published.
* [`static`](./static/) is an image that contains all run-time dependencies ideal for network access restricted environments such as air-gapped servers.

For more information on dynamic and static agents, refer to the [Instana Host Agent Types](https://www.ibm.com/docs/en/instana-observability/current?topic=agents-host#host-agent-types) documentation.
