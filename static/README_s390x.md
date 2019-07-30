## Instana Agent Static Docker s390x

The build of the Instana agent docker image for s390x is special.<br/>
We **do not provide** pre-built images here (see reasons at the
end of this document).

The differences between the x86\_64 and the s390x Dockerfile are:

* architecture is set to s390x
* `docker-ce` package is used instead of `docker-ce-cli`
* `gomplate` binary is added from this project directory

[Gomplate](https://docs.gomplate.ca/) is required for running the
Instana agent in a Docker container. But there is usually no pre-built
`gomplate` binary for s390x Linux distributions. So it has to be built
from source.

### Building gomplate

Run the following command:
```
./build_s390x_gomplate.sh
```

The script uses [Dockerfile.s390x_gomplate](Dockerfile.s390x_gomplate)
to create an image `gomplate:latest`, runs it as `gomplate`, copies
the `gomplate` binary from the container to this project directory,
and cleans up container and image again. The gomplate binary is built
in a Ubuntu 18.04 container. Adapt the Dockerfile if you need something
else.

### Building the Instana Agent Docker Image

For this step you should have built the `gomplate` binary already.
You also need your Instana agent key for this one to be able to
get the `instana-agent-static` package from us.

The build command is:
```
docker build ./ --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} \
  -f Dockerfile.s390x -t instana_agent:latest --no-cache
```

It creates a Ubuntu 18.04 image named `instana_agent:latest`.

Feel free to adapt the Dockerfile to your needs like e.g.
integrating the IBM Java SDK or adding your credentials.

### Running the Instana Agent Container

For this step you need all your Instana agent credentials and the
IBM Java SDK for Linux on z Systems 64-bit has to be installed to
the host system already. We assume the path `/opt/ibm/java-s390x-80/`
here.

An example for getting the IBM Java SDK is downloading the file
`ibm-java-s390x-sdk-8.0-5.35.bin` from
https://developer.ibm.com/javasdk/downloads/sdk8/, making it
executable, and executing it.

The Instana agent inside the Docker container expects the JDK at 
`/opt/instana/agent/jvm`. This is independent of the `JAVA_HOME`
environment variable.

Run the following command to test the image:
```
docker run --name instana_agent -h instana_agent_host -dt \
  -e INSTANA_AGENT_KEY="***" -e INSTANA_AGENT_ENDPOINT="***" \
  -e INSTANA_AGENT_ENDPOINT_PORT="***" \
  -v "/opt/ibm/java-s390x-80/:/opt/instana/agent/jvm" \
  instana_agent:latest
```

Replace `***` with your actual Instana backend credentials.

### No Docker Image Build by Instana

You have to build the s390x Docker image yourself as we:

* do not have enough access to s390x environments for proprietary SW development
* have much fewer customers on s390x (high efforts for little benefit)
* cannot maintain too many variants (e.g. size issue)
* cannot integrate the IBM Java SDK (license issue)
* cannot add your credentials to the image
