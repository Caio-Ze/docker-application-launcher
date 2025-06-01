# Docker Application Launcher

A simple, menu-driven interface for managing multiple Docker applications. Perfect for teams that need to run multiple Docker containers without remembering complex commands.

## 🚀 Quick Installation

**One-command installation:**
```bash
curl -sSL https://raw.githubusercontent.com/Caio-Ze/docker-application-launcher/master/install.sh | bash
```

## ✅ Requirements

- **macOS** (Intel or Apple Silicon)
- **Docker Desktop** installed and running
  - Download: https://www.docker.com/products/docker-desktop/
- **Terminal** access

## 📋 Features

- 🎯 **Simple Menu Interface** - No need to remember Docker commands
- 🔄 **Real-time Status** - See running containers at a glance
- 🛑 **Easy Management** - Start/stop containers with a few keystrokes
- 📱 **Desktop Integration** - Double-click shortcut for non-technical users
- ⚡ **Auto-download** - Docker images downloaded automatically as needed
- 🔧 **Terminal Aliases** - Quick access with `dockerapps` or `da` commands

## 🎮 Usage

After installation, you can launch the application in several ways:

### Terminal Commands
```bash
dockerapps    # Short alias
da           # Even shorter alias
docker-app-launcher  # Full command
```

### Desktop Shortcut
Double-click **"Docker Apps.command"** on your desktop

### Direct Execution
```bash
~/.docker-app-launcher/scripts/docker-app-launcher.sh
```

## 📁 Adding Applications

Applications are configured using JSON files in `~/.docker-app-launcher/apps/`

### Example Configuration
```json
{
  "name": "My Web App",
  "description": "A sample web application",
  "image": "nginx:latest",
  "ports": [
    {
      "host": "8080",
      "container": "80",
      "description": "Web interface"
    }
  ],
  "volumes": [
    {
      "host": "$HOME/data",
      "container": "/usr/share/nginx/html",
      "description": "Web content"
    }
  ],
  "environment": [
    {
      "name": "ENV_VAR",
      "value": "production",
      "description": "Environment setting"
    }
  ],
  "interactive": false,
  "remove_after_exit": true,
  "additional_flags": "--restart unless-stopped"
}
```

### Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name for the application |
| `description` | string | Brief description of what the app does |
| `image` | string | Docker image name and tag |
| `ports` | array | Port mappings (host:container) |
| `volumes` | array | Volume mounts (host:container) |
| `environment` | array | Environment variables |
| `interactive` | boolean | Run with `-it` flags |
| `remove_after_exit` | boolean | Add `--rm` flag |
| `additional_flags` | string | Any additional Docker flags |

## 🏢 Team Installation

For team-wide deployment, share this installation command:

```bash
curl -sSL https://raw.githubusercontent.com/Caio-Ze/docker-application-launcher/master/install.sh | bash
```

Each team member will get:
- ✅ Menu-driven interface
- ✅ Desktop shortcuts
- ✅ Terminal aliases
- ✅ Pre-configured applications

## 📂 Directory Structure

```
~/.docker-app-launcher/
├── scripts/
│   └── docker-app-launcher.sh    # Main launcher script
└── apps/
    ├── app-template.json          # Template for new apps
    └── dynamic-bounce-manager.json # Example app configuration
```

## 🔧 Management Features

The launcher provides several management options:

1. **📱 Run Applications** - Select and start any configured app
2. **📊 Show Running Containers** - View currently active containers
3. **🛑 Stop Containers** - Stop running containers by selection
4. **📋 Show App Details** - View detailed configuration for any app
5. **🔄 Refresh** - Update the display with current status
6. **❌ Exit** - Close the launcher

## 🆘 Troubleshooting

### Common Issues

1. **"Docker is not running"**
   - Start Docker Desktop and wait for it to fully load
   - Check the Docker icon in your menu bar

2. **"Command not found"**
   - Restart your terminal after installation
   - Or run: `source ~/.zshrc`

3. **"Permission denied"**
   - Make sure Docker Desktop is running
   - Check that your user is in the docker group

4. **"jq not found"**
   - The installer will attempt to install jq automatically
   - If it fails, install manually: `brew install jq`

### Getting Help

- 📧 **Issues**: https://github.com/Caio-Ze/docker-application-launcher/issues
- 📖 **Documentation**: This README
- 🔧 **Configuration**: Check `~/.docker-app-launcher/apps/app-template.json`

## 🎯 Perfect For

- **Development Teams** - Standardize Docker workflows
- **Non-Technical Users** - Simple interface for complex applications
- **Multiple Projects** - Manage 10-20+ Docker applications easily
- **Daily Use** - Quick access to frequently used containers

## 📄 License

MIT License - feel free to use and modify for your team's needs.

---

**Made with ❤️ for teams who want Docker without the complexity**