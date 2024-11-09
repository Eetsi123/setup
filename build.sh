#!/bin/sh
set -e

find $(dirname $0)/{files-nvidia/etc/nvidia/kernel.conf,fixes,patches} -exec touch -d2025-01-01 {} +

podman build --target=base   -t ghcr.io/eetumos/silverblue:latest "$@" .
podman build --target=base   -t ghcr.io/eetumos/silverblue:base   "$@" .
podman build --target=nvidia -t ghcr.io/eetumos/silverblue:nvidia "$@" .
