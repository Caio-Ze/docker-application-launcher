#!/bin/bash

# Dynamic Bounce Monitor - Docker Build Script
# This script builds the Docker image with all applications

set -e

echo "🐳 Dynamic Bounce Monitor - Docker Build"
echo "========================================"

# Configuration
IMAGE_NAME="dynamic-bounce-monitor"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is running"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📁 Project directory: $PROJECT_DIR"

# Verify required files exist
REQUIRED_FILES=(
    "Dockerfile"
    "requirements.txt"
    "launcher.py"
    "applications"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -e "$PROJECT_DIR/$file" ]]; then
        echo "❌ Required file/directory not found: $file"
        exit 1
    fi
done

echo "✅ All required files found"

# Create necessary directories if they don't exist
mkdir -p "$PROJECT_DIR/scripts"
mkdir -p "$PROJECT_DIR/assets"

# Build the Docker image
echo "🔨 Building Docker image: $FULL_IMAGE_NAME"
echo "This may take a few minutes..."

cd "$PROJECT_DIR"

docker build \
    --tag "$FULL_IMAGE_NAME" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VERSION="1.0.0" \
    .

if [[ $? -eq 0 ]]; then
    echo "✅ Docker image built successfully: $FULL_IMAGE_NAME"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Show image information
echo ""
echo "📊 Image Information:"
docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""
echo "🚀 Build completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   • Test the image: ./scripts/run.sh"
echo "   • Push to registry: ./scripts/push.sh"
echo "   • Create installer: ./scripts/create-installer.sh"
echo "" 