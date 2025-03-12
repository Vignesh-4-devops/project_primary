#!/bin/bash

set -e  # Exit on any error

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get the image tag as argument
IMAGE_TAG=$1

if [ -z "$IMAGE_TAG" ]; then
    echo "Error: Image tag not provided"
    exit 1
fi

CONTAINER_NAME="site-analyzer"
IMAGE_NAME="site-analyzer:${IMAGE_TAG}"

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up containers..."
    if docker ps -a | grep -q ${CONTAINER_NAME}; then
        echo "Found existing container '${CONTAINER_NAME}', removing it..."
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    fi
}

# Ensure cleanup happens even if script fails
trap cleanup EXIT

echo "🚀 Starting container test for image: ${IMAGE_NAME}"

# Check if image exists locally
if ! docker image inspect ${IMAGE_NAME} >/dev/null 2>&1; then
    echo "❌ Error: Image ${IMAGE_NAME} not found locally"
    exit 1
fi

# Check if env file exists
if [ ! -f "${SCRIPT_DIR}/local/.env" ]; then
    echo "❌ Error: Environment file not found at ${SCRIPT_DIR}/local/.env"
    exit 1
fi

# Clean up any existing container before starting
cleanup

echo "📦 Starting test container..."
echo "⏳ Container will run for 20 seconds to verify stability..."

# Run container for 20 seconds
timeout 20s docker run \
    --name ${CONTAINER_NAME} \
    ${IMAGE_NAME}

# Check exit code - 124 means timeout which is good (service stayed up)
# Any other non-zero code means failure
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
    echo ""  # Add newline after logs
    echo "✅ Container test completed successfully!"
    echo "✨ Service stayed up for 20 seconds without errors"
    cleanup  # Clean up before exiting
    exit 0  # Exit with success
elif [ $EXIT_CODE -eq 0 ]; then
    echo ""  # Add newline after logs
    echo "✅ Container exited cleanly"
    exit 0  # Exit with success
else
    echo ""  # Add newline after logs
    echo "❌ Container failed with exit code: $EXIT_CODE"
    exit 1  # Exit with failure
fi  