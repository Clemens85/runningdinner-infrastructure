#! /bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source ./config.sh

docker build -t "$DOCKER_IMAGE" .