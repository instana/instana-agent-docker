Instana Agent Docker RH
====================

*PRELIMINARY CERTIFICATION ONLY BUILD*

This build of the instana agent includes requires access to the publicly hosted Instana maven repository in order to download sensors. It requires proxy settings for egress access to the ${INSTANA_AGENT_ENDPOINT}, which may either be for your self hosted Instana installation or for the Instana SaaS, and for access to the Instana maven repository.

Building
========

docker build ./ --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache

*Note*

FTP_PROXY is being abused to pass in the agent key for the package download during docker build, we are doing this until docker build time secrets issue is resolved: [issue GH33343](https://github.com/moby/moby/issues/33343)

