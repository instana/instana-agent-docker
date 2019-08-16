## instana-agent-docker

This repo contains the Dockerfiles relating to the various containers Instana
supports.

 * dynamic - is the image used in the Helm chart and is suggested as the
             preferred image for a standard install.
 * static - the static image that contains all run-time dependencies ideal for
            network access restricted environments such as airgapped servers.
 * rhel - is the RHEL Atomic based image which is suggested for environments
          where a RHEL base image is required.

