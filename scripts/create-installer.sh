#!/bin/bash

# Dynamic Bounce Monitor - Installer Generator
# This script creates a one-click installer for end users

set -e

echo "📦 Dynamic Bounce Monitor - Creating Installer"
echo "=============================================="

# Configuration
PROJECT_DIR="$(pwd)"
INSTALLER_NAME="install-dynamic-bounce-monitor.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_status "Creating installer in: $PROJECT_DIR"

# Generate the installer script
cat > "$PROJECT_DIR/$INSTALLER_NAME" << 'EOF'
#!/bin/bash

# Dynamic Bounce Monitor - One-Click Installer
# This script installs and runs Dynamic Bounce Monitor

set -e

echo "🎵 Dynamic Bounce Monitor - One-Click Installer"
echo "==============================================="

# Configuration
IMAGE_NAME="caioze/dynamic-bounce-monitor:latest"
CONTAINER_NAME="dynamic-bounce-monitor"
APP_DIR="$HOME/.dynamic-bounce-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first:"
    echo "   macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "   Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "   Linux: https://docs.docker.com/desktop/install/linux-install/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

print_success "Docker is installed and running"

# Create application directory
mkdir -p "$APP_DIR"
print_success "Created application directory: $APP_DIR"

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping existing container..."
    docker stop "$CONTAINER_NAME" &> /dev/null || true
    docker rm "$CONTAINER_NAME" &> /dev/null || true
fi

# Pull the latest image
print_status "Downloading Dynamic Bounce Monitor (this may take a few minutes)..."
if docker pull "$IMAGE_NAME"; then
    print_success "Successfully downloaded Dynamic Bounce Monitor"
else
    print_error "Failed to download the application. Please check your internet connection."
    exit 1
fi

# Determine the user's home directory and OS
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

# Create local data directories
mkdir -p "$USER_HOME/DynamicBounceMonitor/data"
mkdir -p "$USER_HOME/DynamicBounceMonitor/output"
print_success "Created data directories"

# Create launcher script
LAUNCHER_SCRIPT="$APP_DIR/launch.sh"
cat > "$LAUNCHER_SCRIPT" << LAUNCHER_EOF
#!/bin/bash

# Dynamic Bounce Monitor Launcher
echo "🎵 Starting Dynamic Bounce Monitor..."

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Stop existing container if running
docker stop "$CONTAINER_NAME" &> /dev/null || true
docker rm "$CONTAINER_NAME" &> /dev/null || true

# Run the container
docker run -it --rm \\
    --name "$CONTAINER_NAME" \\
    --hostname "dynamic-bounce-monitor" \\
    -v "$USER_HOME:$HOST_MOUNT" \\
    -v "$USER_HOME/DynamicBounceMonitor/data:/app/data" \\
    -v "$USER_HOME/DynamicBounceMonitor/output:/app/output" \\
    -e "USER_HOME=$HOST_MOUNT" \\
    -e "HOST_USER=\$(whoami)" \\
    -e "TERM=xterm-256color" \\
    --workdir /app \\
    "$IMAGE_NAME"
LAUNCHER_EOF

chmod +x "$LAUNCHER_SCRIPT"
print_success "Created launcher script: $LAUNCHER_SCRIPT"

# Create desktop shortcut for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    DESKTOP_SHORTCUT="$HOME/Desktop/Dynamic Bounce Monitor.command"
    cat > "$DESKTOP_SHORTCUT" << DESKTOP_EOF
#!/bin/bash
cd "\$HOME"
"$LAUNCHER_SCRIPT"
DESKTOP_EOF
    chmod +x "$DESKTOP_SHORTCUT"
    print_success "Created desktop shortcut: Dynamic Bounce Monitor.command"
fi

# Add shell aliases
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    # Remove existing aliases if they exist
    sed -i '' '/alias dbm=/d' "$SHELL_CONFIG" 2>/dev/null || true
    sed -i '' '/alias dynamic-bounce=/d' "$SHELL_CONFIG" 2>/dev/null || true
    
    # Add new aliases
    echo "" >> "$SHELL_CONFIG"
    echo "# Dynamic Bounce Monitor aliases" >> "$SHELL_CONFIG"
    echo "alias dbm='$LAUNCHER_SCRIPT'" >> "$SHELL_CONFIG"
    echo "alias dynamic-bounce='$LAUNCHER_SCRIPT'" >> "$SHELL_CONFIG"
    
    print_success "Added shell aliases: dbm, dynamic-bounce"
fi

echo ""
print_success "🎉 Installation completed successfully!"
echo ""
echo "📋 How to use Dynamic Bounce Monitor:"
echo "   • Type 'dbm' or 'dynamic-bounce' in terminal"
if [[ "$OSTYPE" == "darwin"* ]]; then
echo "   • Double-click 'Dynamic Bounce Monitor.command' on desktop"
fi
echo "   • Run '$LAUNCHER_SCRIPT' directly"
echo ""
echo "📁 Your files will be saved to: $USER_HOME/DynamicBounceMonitor/"
echo "📖 Data directory: $USER_HOME/DynamicBounceMonitor/data/"
echo "📤 Output directory: $USER_HOME/DynamicBounceMonitor/output/"
echo ""

# Ask if user wants to start now
echo "🚀 Would you like to start Dynamic Bounce Monitor now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    print_status "Starting Dynamic Bounce Monitor..."
    exec "$LAUNCHER_SCRIPT"
else
    print_success "You can start Dynamic Bounce Monitor anytime using the methods above!"
fi
EOF

chmod +x "$PROJECT_DIR/$INSTALLER_NAME"

print_success "Installer created: $INSTALLER_NAME"
echo ""
echo "📋 Next steps:"
echo "   1. Test the installer: ./$INSTALLER_NAME"
echo "   2. Upload to a web server or GitHub"
echo "   3. Share the download link with users"
echo ""
echo "📝 One-line installation command for users:"
echo "   curl -sSL YOUR_DOMAIN/$INSTALLER_NAME | bash"
echo ""
