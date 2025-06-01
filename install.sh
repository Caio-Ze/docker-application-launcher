#!/bin/bash

# Docker Application Launcher - Installer
# Standard installer for production environments

set -e

# Configuration
INSTALL_DIR="$HOME/DockerApplicationLauncher"
DATA_DIR="$INSTALL_DIR/data"
OUTPUT_DIR="$INSTALL_DIR/output"
REGISTRY="localhost/docker-application-launcher"
TAG="latest"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "🐳 Docker Application Launcher - Installation"
echo "============================================="
echo "Install directory: $INSTALL_DIR"
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$OUTPUT_DIR"
mkdir -p "$INSTALL_DIR/scripts"
mkdir -p "$INSTALL_DIR/applications/utils"

# Copy core files
echo "📦 Copying files..."
cp launcher.py "$INSTALL_DIR/"
cp Dockerfile.orchestrator "$INSTALL_DIR/"
cp Dockerfile.script-template "$INSTALL_DIR/"
cp requirements.txt "$INSTALL_DIR/"
cp README.md "$INSTALL_DIR/"
cp TECHNICAL_OVERVIEW.txt "$INSTALL_DIR/"

# Copy scripts
cp scripts/build-all.sh "$INSTALL_DIR/scripts/"
cp scripts/add-script.sh "$INSTALL_DIR/scripts/"
cp scripts/run-orchestrator.sh "$INSTALL_DIR/scripts/"
cp scripts/list-containers.sh "$INSTALL_DIR/scripts/"

# Copy applications
cp applications/utils/path_utils.py "$INSTALL_DIR/applications/utils/"
cp -r applications/*.py "$INSTALL_DIR/applications/" 2>/dev/null || true
cp -r applications/*.sh "$INSTALL_DIR/applications/" 2>/dev/null || true

# Make scripts executable
chmod +x "$INSTALL_DIR/launcher.py"
find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

# Create launcher script
echo "📝 Creating launcher script..."
cat > "$HOME/docker-app-launcher.sh" << EOF
#!/bin/bash
# Docker Application Launcher
cd "$INSTALL_DIR"
./scripts/run-orchestrator.sh
EOF
chmod +x "$HOME/docker-app-launcher.sh"

# Create desktop shortcut on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -d "$HOME/Desktop" ]; then
    echo "🖥️ Creating desktop shortcut..."
    cat > "$HOME/Desktop/Docker-App-Launcher.desktop" << EOF
[Desktop Entry]
Name=Docker Application Launcher
Exec=$HOME/docker-app-launcher.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
EOF
    chmod +x "$HOME/Desktop/Docker-App-Launcher.desktop"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "🚀 Run the launcher: $HOME/docker-app-launcher.sh"
echo ""
echo "📂 Data directory: $DATA_DIR"
echo "📂 Output directory: $OUTPUT_DIR"
echo ""