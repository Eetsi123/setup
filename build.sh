#!/bin/sh
set -e

podman build --target=base   -t ghcr.io/eetsi123/silverblue:latest "$@" .
podman build --target=base   -t ghcr.io/eetsi123/silverblue:base   "$@" .
podman build --target=nvidia -t ghcr.io/eetsi123/silverblue:nvidia "$@" .
