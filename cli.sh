#! /bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

source ./docker-cli/config.sh

REPO_DIR=$(pwd)

docker run --tty -it \
            -v "${REPO_DIR}":/workspace \
            -v "${HOME}"/.ssh:/home/tf_user/.ssh-host:ro \
            -v "${HOME}"/.aws:/home/tf_user/.aws-host:ro \
            -v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro \
            -w /workspace \
            "${DOCKER_IMAGE}"
