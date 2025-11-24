#!/bin/bash
set -e
env="$(dirname "$0")/../env.docker"
config="$(dirname "$0")/docker-compose.yaml"
docker-compose -f $config --env-file $env "$@"
