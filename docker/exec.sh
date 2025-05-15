#!/bin/bash
set -e
env="$(dirname "$0")/../env.example"
config="$(dirname "$0")/docker-compose.yaml"
source $env
docker exec --env-file $env -it node "$@"
