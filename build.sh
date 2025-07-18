#!/bin/sh

# Setup.
cd $(dirname $0)
set -eux

# Build docker images.
docker build \
    -t damrrc/rocky-with-python3.11:latest .
docker build \
    --build-arg BASE_IMAGE=fedora:42 \
    --build-arg DNF=dnf \
    -t damrrc/fedora-with-python3.11:latest .

# Upload docker images.
docker push damrrc/rocky-with-python3.11:latest
docker push damrrc/fedora-with-python3.11:latest
