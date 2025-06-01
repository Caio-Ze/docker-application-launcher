#!/bin/bash
# Run script for Docker Application Launcher orchestrator

# Set working directory to script location
cd "$(dirname "$0")/.."

# Configuration
if [ -z "$OCIR_REGISTRY" ]; then
    REGISTRY=${REGISTRY:-"localhost/docker-application-launcher"}
else
    REGISTRY=${REGISTRY:-"$OCIR_REGISTRY/docker-application-launcher"}
fi
TAG=${TAG:-"latest"}
DATA_DIR=${DATA_DIR:-"$HOME/DockerApplicationLauncher/data"}
OUTPUT_DIR=${OUTPUT_DIR:-"$HOME/DockerApplicationLauncher/output"}

# Print header
echo "🐳 Docker Application Launcher - Orchestrator"
echo "============================================="
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "Data directory: $DATA_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    echo "Please start Docker Desktop or Docker service"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$DATA_DIR"
mkdir -p "$OUTPUT_DIR"

# Get the host OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    HOST_OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    HOST_OS="linux"
else
    # Windows or other
    HOST_OS="unknown"
fi

# Run the orchestrator container
echo "🚀 Starting orchestrator container..."

docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$HOME:/host$HOME" \
    -v "$DATA_DIR:/app/data" \
    -v "$OUTPUT_DIR:/app/output" \
    -e "HOST_USER=$USER" \
    -e "CONTAINER_REGISTRY=$REGISTRY" \
    -e "CONTAINER_TAG=$TAG" \
    -e "HOST_OS=$HOST_OS" \
    -e "ORCHESTRATOR_SIDE_DATA_DIR=/app/data" \
    -e "ORCHESTRATOR_SIDE_OUTPUT_DIR=/app/output" \
    -e "ORCHESTRATOR_SIDE_HOST_HOME=/host$HOME" \
    -e "ACTUAL_HOST_HOME_ON_HOST=$HOME" \
    -e "ACTUAL_HOST_DATA_ON_HOST=$DATA_DIR" \
    -e "ACTUAL_HOST_OUTPUT_ON_HOST=$OUTPUT_DIR" \
    -e "PYTHONUNBUFFERED=1" \
    -e "TERM=xterm-256color" \
    "$REGISTRY/orchestrator:$TAG"

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "❌ Orchestrator container exited with code $exit_code"
    echo ""
    echo "Possible issues:"
    echo "  1. Image doesn't exist - Run './scripts/build-all.sh'"
    echo "  2. Docker daemon is not running"
    echo "  3. Permission issues with volume mounts"
    echo ""
    exit $exit_code
fi

echo "✅ Orchestrator container exited successfully" 