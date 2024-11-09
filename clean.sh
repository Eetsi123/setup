#!/bin/sh
buildah rm --all
podman image prune --force
