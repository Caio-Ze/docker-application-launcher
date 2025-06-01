#!/bin/bash

# Dynamic Bounce Monitor - Docker Run Script
# This script runs the Docker container with proper volume mounts

set -e

echo "🚀 Dynamic Bounce Monitor - Starting Container"
echo "=============================================="

# Configuration
IMAGE_NAME="dynamic-bounce-monitor:latest"
CONTAINER_NAME="dynamic-bounce-monitor"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Description:"
            echo "  Starts the Dynamic Bounce Monitor terminal interface"
            echo "  All your audio/video processing tools in one place"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "❌ Docker image not found: $IMAGE_NAME"
    echo "Please build the image first: ./scripts/build.sh"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 Stopping existing container..."
    docker stop "$CONTAINER_NAME" &> /dev/null || true
    docker rm "$CONTAINER_NAME" &> /dev/null || true
fi

# Determine the user's home directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    USER_HOME="$HOME"
    HOST_MOUNT="/host/Users/$(whoami)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    USER_HOME="$HOME"
    HOST_MOUNT="/host/home/$(whoami)"
else
    # Windows (Git Bash/WSL)
    USER_HOME="$HOME"
    HOST_MOUNT="/host/Users/$(whoami)"
fi

echo "📁 Mounting user directory: $USER_HOME -> $HOST_MOUNT"

# Create local data directories if they don't exist
mkdir -p "$USER_HOME/DynamicBounceMonitor/data"
mkdir -p "$USER_HOME/DynamicBounceMonitor/output"

echo "💻 Starting Terminal Interface..."

# Run the container
docker run \
    --name "$CONTAINER_NAME" \
    --hostname "dynamic-bounce-monitor" \
    -it \
    --rm \
    -v "$USER_HOME:$HOST_MOUNT" \
    -v "$USER_HOME/DynamicBounceMonitor/data:/app/data" \
    -v "$USER_HOME/DynamicBounceMonitor/output:/app/output" \
    -e "USER_HOME=$HOST_MOUNT" \
    -e "HOST_USER=$(whoami)" \
    -e "TERM=xterm-256color" \
    --workdir "/app" \
    "$IMAGE_NAME"

echo ""
echo "👋 Container stopped. Thank you for using Dynamic Bounce Monitor!" 