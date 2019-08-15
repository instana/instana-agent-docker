#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"

docker build ./ -f Dockerfile.s390x_gomplate -t gomplate:latest --no-cache
docker run --name gomplate -dt gomplate:latest
docker cp gomplate:/root/go/src/github.com/hairyhenderson/gomplate/bin/gomplate .
docker stop gomplate
docker rm gomplate
docker image rm gomplate:latest
