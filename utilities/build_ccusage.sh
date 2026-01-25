#!/bin/bash

# Build script for ccusage container image
# Mirrors the ytdl build flow but targets the ccusage image/Dockerfile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_DIR="$(cd "${SCRIPT_DIR}/../dockerfiles" && pwd)"
DOCKERFILE="${DOCKERFILE_DIR}/ccusage.Dockerfile"
IMAGE_NAME="ccusage"
TAG="${TAG:-latest}"

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Dockerfile not found: ${DOCKERFILE}" >&2
  exit 1
fi

echo "Building Docker image: ${IMAGE_NAME}:${TAG}"
echo "Using Dockerfile: ${DOCKERFILE}"

docker build \
  -t "${IMAGE_NAME}:${TAG}" \
  -f "${DOCKERFILE}" \
  "${DOCKERFILE_DIR}"

echo "✓ Build complete!"
echo "To run the container:"
echo "  docker run --rm ${IMAGE_NAME}:${TAG}"
