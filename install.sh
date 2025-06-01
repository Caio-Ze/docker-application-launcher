#!/bin/bash

# Docker Application Launcher - Installation Script
# This script installs the Docker Application Launcher system-wide

set -e

echo "🐳 Docker Application Launcher - Installation"
echo "=============================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first:"
    echo "   https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is installed and running"

# Create installation directory
INSTALL_DIR="$HOME/.docker-app-launcher"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/scripts"
mkdir -p "$INSTALL_DIR/apps"

echo "📁 Created installation directory: $INSTALL_DIR"

# Download the main launcher script
echo "📥 Downloading launcher script..."
curl -sSL https://raw.githubusercontent.com/Caio-Ze/docker-application-launcher/master/scripts/docker-app-launcher.sh -o "$INSTALL_DIR/scripts/docker-app-launcher.sh"
chmod +x "$INSTALL_DIR/scripts/docker-app-launcher.sh"

# Download the app template
echo "📥 Downloading app template..."
curl -sSL https://raw.githubusercontent.com/Caio-Ze/docker-application-launcher/master/examples/app-template.json -o "$INSTALL_DIR/apps/app-template.json"

# Create default apps configuration with Dynamic Bounce Manager
echo "📝 Creating default apps configuration..."
cat > "$INSTALL_DIR/apps/dynamic-bounce-manager.json" << 'EOF'
{
  "name": "Dynamic Bounce Manager",
  "description": "Audio file monitoring and organization tool",
  "image": "caioze/dynamic-bounce-manager:latest",
  "ports": [],
  "volumes": [
    {
      "host": "$HOME",
      "container": "/host/Users/$(whoami)",
      "description": "Mount home directory for file access"
    }
  ],
  "environment": [
    {
      "name": "TERM",
      "value": "xterm-256color",
      "description": "Terminal compatibility"
    }
  ],
  "interactive": true,
  "remove_after_exit": true,
  "additional_flags": "--rm"
}
EOF

# Add aliases to shell configuration
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    echo "🔧 Adding shell aliases..."
    
    # Remove existing aliases if they exist
    sed -i '' '/alias dockerapps=/d' "$SHELL_CONFIG" 2>/dev/null || true
    sed -i '' '/alias da=/d' "$SHELL_CONFIG" 2>/dev/null || true
    
    # Add new aliases
    echo "" >> "$SHELL_CONFIG"
    echo "# Docker Application Launcher aliases" >> "$SHELL_CONFIG"
    echo "alias dockerapps='$INSTALL_DIR/scripts/docker-app-launcher.sh'" >> "$SHELL_CONFIG"
    echo "alias da='$INSTALL_DIR/scripts/docker-app-launcher.sh'" >> "$SHELL_CONFIG"
    
    echo "✅ Added aliases: dockerapps, da"
fi

# Create system-wide command (optional)
if [[ -w "/usr/local/bin" ]]; then
    ln -sf "$INSTALL_DIR/scripts/docker-app-launcher.sh" "/usr/local/bin/docker-app-launcher"
    echo "✅ Created system-wide command: docker-app-launcher"
fi

# Create desktop shortcut for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🖥️  Creating desktop shortcut..."
    
    # Create .command file for easy double-click execution
    cat > "$HOME/Desktop/Docker Apps.command" << EOF
#!/bin/bash
cd "\$HOME"
"$INSTALL_DIR/scripts/docker-app-launcher.sh"
EOF
    chmod +x "$HOME/Desktop/Docker Apps.command"
    
    echo "✅ Created desktop shortcut: Docker Apps.command"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📋 How to use:"
echo "   • Type 'dockerapps' or 'da' in terminal"
echo "   • Double-click 'Docker Apps.command' on desktop"
echo "   • Run '$INSTALL_DIR/scripts/docker-app-launcher.sh' directly"
echo ""
echo "📁 Configuration directory: $INSTALL_DIR"
echo "📖 Add more apps by creating JSON files in: $INSTALL_DIR/apps/"
echo ""
echo "🔄 Restart your terminal or run: source $SHELL_CONFIG"
echo ""