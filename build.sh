#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "$0")"

IMAGE="${IMAGE:-glm53-flash-exl3-lil:jovian-r1}"
DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-0}" docker build --tag "$IMAGE" .

docker image inspect "$IMAGE" --format 'Built {{index .RepoTags 0}} ({{.Id}})'
