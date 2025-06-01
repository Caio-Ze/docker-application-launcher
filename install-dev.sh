#!/bin/bash

# Docker Application Launcher - Development Installer
# Quick setup for development/testing environments

set -e

# Configuration
INSTALL_DIR="$HOME/DockerApplicationLauncher.dev"
DATA_DIR="$INSTALL_DIR/data"
OUTPUT_DIR="$INSTALL_DIR/output"
REGISTRY="localhost/docker-application-launcher"
TAG="dev"

# Check Docker
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "🐳 Docker Application Launcher - Dev Installation"
echo "================================================"
echo "Install directory: $INSTALL_DIR"
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$OUTPUT_DIR"

# Copy project files
cp -r ./* "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR/launcher.py"
find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

# Create launcher script
cat > "$HOME/docker-app-launcher-dev.sh" << EOF
#!/bin/bash
# Docker Application Launcher (Development)
cd "$INSTALL_DIR"
REGISTRY="$REGISTRY" TAG="$TAG" ./scripts/run-orchestrator.sh
EOF
chmod +x "$HOME/docker-app-launcher-dev.sh"

# Build containers
echo "🔨 Building containers..."
cd "$INSTALL_DIR"
REGISTRY="$REGISTRY" TAG="$TAG" ./scripts/build-all.sh

echo ""
echo "✅ Development installation complete!"
echo ""
echo "🚀 Run the launcher: $HOME/docker-app-launcher-dev.sh"
echo ""
