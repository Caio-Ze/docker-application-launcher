#!/bin/bash

# Docker Application Launcher - Quick Setup Script
# Prepares the development environment

set -e

# Configuration
REGISTRY="localhost/docker-application-launcher"
TAG="dev"
DATA_DIR="$HOME/DockerApplicationLauncher/data"
OUTPUT_DIR="$HOME/DockerApplicationLauncher/output"

echo "🐳 Docker Application Launcher - Development Setup"
echo "================================================="
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "Data directory: $DATA_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"

# Create required directories
echo "📁 Creating data and output directories..."
mkdir -p "$DATA_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "applications/utils"

# Ensure path_utils.py exists
if [ ! -f "applications/utils/path_utils.py" ]; then
    echo "⚠️ Missing path_utils.py, will be created by build-all.sh"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
find scripts -type f -name "*.sh" -exec chmod +x {} \;
chmod +x launcher.py

# Build the Docker images
echo "🔨 Building Docker images..."
REGISTRY="$REGISTRY" TAG="$TAG" ./scripts/build-all.sh

if [[ $? -eq 0 ]]; then
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Run the application: REGISTRY=\"$REGISTRY\" TAG=\"$TAG\" ./scripts/run-orchestrator.sh"
    echo "   2. Add new scripts: ./scripts/add-script.sh <script-name>"
    echo "   3. List available containers: REGISTRY=\"$REGISTRY\" TAG=\"$TAG\" ./scripts/list-containers.sh"
    echo ""
    echo "🚀 Ready for development!"
else
    echo "❌ Setup failed. Please check the error messages above."
    exit 1
fi 