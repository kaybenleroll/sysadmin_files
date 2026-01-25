#!/bin/bash

# Build script for my-ytdl container image
# This builds the YouTube downloader container based on Alpine Linux

set -euo pipefail  # Exit on error

DOCKERFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dockerfiles" && pwd)"
IMAGE_NAME="my-ytdl"
TAG="latest"
DOCKERFILE="ytdl.Dockerfile"

echo "Building Docker image: ${IMAGE_NAME}:${TAG}"
echo "Using Dockerfile: ${DOCKERFILE_DIR}/${DOCKERFILE}"

docker build \
  -t "${IMAGE_NAME}:${TAG}" \
  -f "${DOCKERFILE_DIR}/${DOCKERFILE}" \
  "${DOCKERFILE_DIR}"

echo "✓ Build complete!"
echo "To run the container:"
echo "  docker run --rm -v /path/to/downloads:/downloads ${IMAGE_NAME}:${TAG} [yt-dlp options]"
