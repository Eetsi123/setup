#!/bin/sh
set -e

touch -d "$(rg -oP 'Date: \K.*' patches/gnome-shell/2230-multiseat.patch | tail -n1)" \
                                patches/gnome-shell/2230-multiseat.patch

podman build --target=base   -t ghcr.io/eetsi123/silverblue:latest "$@" .
podman build --target=base   -t ghcr.io/eetsi123/silverblue:base   "$@" .
podman build --target=nvidia -t ghcr.io/eetsi123/silverblue:nvidia "$@" .
