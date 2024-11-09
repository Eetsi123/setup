#!/bin/sh
set -e

export REGISTRY_AUTH_FILE=.ghcr-auth
podman login ghcr.io

push() {
    user=$(podman login ghcr.io --get-login)

    [ "$1" = nc ] && shift && local nc=--no-cache

    podman build --pull=newer --target=base   -t ghcr.io/eetsi123/silverblue        $nc .
    podman build --pull=newer --target=base   -t ghcr.io/eetsi123/silverblue:base   $nc .
    podman build --pull=newer --target=nvidia -t ghcr.io/eetsi123/silverblue:nvidia $nc .

    podman push ghcr.io/$user/silverblue
    podman push ghcr.io/$user/silverblue:base
    podman push ghcr.io/$user/silverblue:nvidia

    [ "$1" = u ] && shift && rpm-ostree upgrade
}

time push "$@"
