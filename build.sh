#!/bin/sh
set -e

find $(dirname $0)/patches -exec touch -d2025-01-01 {} +

podman build --target=base   -t ghcr.io/eetsi123/silverblue:latest "$@" .
podman build --target=base   -t ghcr.io/eetsi123/silverblue:base   "$@" .
podman build --target=nvidia -t ghcr.io/eetsi123/silverblue:nvidia "$@" .
