#!/bin/bash

# Dynamic Bounce Monitor - Setup Script
# Quick setup for administrators

set -e

echo "🎵 Dynamic Bounce Monitor - Administrator Setup"
echo "==============================================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is running"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh launcher.py web-launcher.py

# Build the Docker image
echo "🔨 Building Docker image..."
./scripts/build.sh

if [[ $? -eq 0 ]]; then
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test terminal interface: ./scripts/run.sh"
    echo "   2. Test web interface: ./scripts/run.sh --web"
    echo "   3. Create installer: ./scripts/create-installer.sh"
    echo "   4. Deploy to Docker Hub (see README.md)"
    echo ""
    echo "🚀 Ready to deploy to your team!"
else
    echo "❌ Setup failed. Please check the error messages above."
    exit 1
fi 