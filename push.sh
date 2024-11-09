#!/bin/sh
set -e

export REGISTRY_AUTH_FILE=.ghcr
podman login ghcr.io

podman push ghcr.io/eetsi123/silverblue:latest "$@"
podman push ghcr.io/eetsi123/silverblue:base   "$@"
podman push ghcr.io/eetsi123/silverblue:nvidia "$@"
