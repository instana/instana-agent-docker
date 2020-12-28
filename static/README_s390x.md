## Instana Agent Static Docker s390x

The build of the Instana agent docker image for s390x is special.

We **do not provide** pre-built images for s390x due to licensing issues with IBM's Java Virtual Machine.

The differences between the x86\_64 and the s390x Dockerfile are the following:

* architecture is set to s390x
* `docker-ce` package is used instead of `docker-ce-cli`
* `gomplate` binary is built in a multi-step build

[Gomplate](https://docs.gomplate.ca/) is required for running the Instana agent in a Docker container.
But there is usually no pre-built `gomplate` binary for s390x Linux distributions.
So it has to be built from source.

### Building the Instana Agent Docker Image

Needs Docker 18.09 or higher:

```sh
echo <DOWNLOAD_KEY> > download_key
DOCKER_BUILDKIT=1 docker build --secret id=download_key,src=download_key --no-cache . -t containers.instana.io/instana/release/agent/static
rm download_key
```

It creates an image named `containers.instana.io/instana/release/agent/static:latest`.

Feel free to adapt the Dockerfile to your needs like, e.g., integrating the IBM Java SDK or adding your credentials.

### Running the Instana Agent Container

For this step you need all your Instana agent credentials and the IBM Java SDK for Linux on z Systems 64-bit has to be installed to the host system already.
We assume the path `/opt/ibm/java-s390x-80/` here.

An example for getting the IBM Java SDK is downloading the file `ibm-java-s390x-sdk-8.0-5.35.bin` from https://developer.ibm.com/javasdk/downloads/sdk8/, making it executable, and executing it.

The Instana agent inside the Docker container expects the JDK at `/opt/instana/agent/jvm`.
This is independent of the `JAVA_HOME` environment variable.

Run the following command to test the image:

```sh
docker run --name instana_agent -h instana_agent_host -dt \
  -e INSTANA_AGENT_KEY="***" -e INSTANA_AGENT_ENDPOINT="***" \
  -e INSTANA_AGENT_ENDPOINT_PORT="***" \
  -v "/opt/ibm/java-s390x-80/:/opt/instana/agent/jvm" \
  instana_agent:latest
```

Replace `***` with your actual Instana backend credentials.
