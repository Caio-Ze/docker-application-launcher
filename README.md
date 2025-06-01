# 🎵 Dynamic Bounce Monitor - Docker Application Launcher

A comprehensive, user-friendly Docker application launcher for audio and video processing tools. Perfect for teams that need to run multiple Python scripts and shell tools without dealing with dependencies, installations, or complex commands.

## 🚀 Quick Start

**One-command installation for end users:**
```bash
curl -sSL https://your-domain.com/install-dynamic-bounce-monitor.sh | bash
```

## ✅ Requirements

- **macOS, Linux, or Windows** (with Docker Desktop)
- **Docker Desktop** installed and running
  - Download: https://www.docker.com/products/docker-desktop/
- **Terminal** access for interactive operations

## 📋 Features

### 🎯 **Rich Terminal Interface**
- **💻 Interactive Menu System** - Beautiful, categorized terminal interface
- **📊 Real-time Process Monitoring** - Track running applications and their status
- **🔧 Built-in File Browser** - Easy access to input/output directories
- **⚡ One-Click Application Launch** - No need to remember complex commands

### 🔄 **Complete Application Suite**
- **🎤 Voice Cleaner API v1 & v2** - Clean audio using ElevenLabs and Auphonic APIs
- **🔄 WAV/MP3 Converter** - Convert between audio formats with quality options
- **🎵 Audio Enhancer** - Apply volume boost, compression and loudness normalization
- **📺 YouTube Downloader** - Download audio/video with ffmpeg processing
- **🎬 Video Optimizer** - Optimize videos for 480p with H.264 encoding
- **☁️ Google Drive Manager** - Manage Google Drive cache and Finder favorites
- **📁 PTX Template Copier** - Copy .ptx files and Audio Files to São Paulo template folders
- **📁 PTX Template Copier (No AM)** - PTX copying excluding AM folders
- **🗂️ Folder Structure Creator** - Create folder structures from clipboard content

### 🛠️ **Enterprise Features**
- **🐳 Zero Installation** - Everything runs in Docker containers
- **📱 Desktop Integration** - One-click shortcuts for non-technical users
- **⚡ Auto-dependency Management** - All Python packages and system tools included
- **🔧 Real-time Process Management** - Start, stop, and monitor applications
- **📊 Status Monitoring** - Live process status and runtime information
- **🗂️ File Browser** - Easy access to input/output directories

## 🎮 Usage

### Terminal Interface
```bash
# Using aliases (after installation)
dbm                    # Short alias
dynamic-bounce         # Full alias

# Direct execution
~/.dynamic-bounce-monitor/launch.sh

# Docker command
./scripts/run.sh
```

### Desktop Shortcuts
- **macOS**: Double-click "Dynamic Bounce Monitor.command" on desktop
- **Windows/Linux**: Use created shortcuts or terminal commands

## 🏗️ Development & Deployment

### Building the Docker Image
```bash
# Clone the repository
git clone <your-repo-url>
cd docker-application-launcher

# Build the image
./scripts/build.sh

# Test locally
./scripts/run.sh
```

### Creating the Installer
```bash
# Generate the one-click installer
./scripts/create-installer.sh

# This creates: install-dynamic-bounce-monitor.sh
```

### Deployment Options

#### Option 1: Docker Hub (Recommended)
```bash
# Tag and push to Docker Hub
docker tag dynamic-bounce-monitor:latest your-username/dynamic-bounce-monitor:latest
docker push your-username/dynamic-bounce-monitor:latest

# Update installer script with your image name
# Then host the installer on your web server
```

#### Option 2: Private Registry
```bash
# Push to your private registry
docker tag dynamic-bounce-monitor:latest your-registry.com/dynamic-bounce-monitor:latest
docker push your-registry.com/dynamic-bounce-monitor:latest
```

#### Option 3: Direct Distribution
```bash
# Save image as file
docker save dynamic-bounce-monitor:latest | gzip > dynamic-bounce-monitor.tar.gz

# Load on target machine
gunzip -c dynamic-bounce-monitor.tar.gz | docker load
```

## 📂 Project Structure

```
docker-application-launcher/
├── Dockerfile                          # Main container definition
├── requirements.txt                    # Python dependencies
├── launcher.py                         # Terminal interface
├── applications/                       # Python scripts and shell tools
│   ├── voice_cleaner_API1.py
│   ├── voice_cleaner_API2.py
│   ├── WAVMP3_FIX.py
│   ├── EXTRA_PARA_NET_SPACE_FIX.py
│   ├── youtube_downloader_PYFFMPEG.py
│   ├── optimize_videos_PYFFMPEG.py
│   ├── google_drive_manager_fixed.sh
│   ├── COPY_PTX_CRF.sh
│   ├── COPY_PTX_CRF**SEM_AM.sh
│   └── PASTAS_CRF.py
├── scripts/                            # Build and deployment scripts
│   ├── build.sh                        # Build Docker image
│   ├── run.sh                          # Run container
│   └── create-installer.sh             # Generate installer
└── install-dynamic-bounce-monitor.sh   # Generated installer
```

## 🔧 Configuration

### Environment Variables
- `USER_HOME`: Mounted user home directory
- `HOST_USER`: Current user name
- `DATA_DIR`: `/app/data` (input files)
- `OUTPUT_DIR`: `/app/output` (processed files)
- `TEMP_DIR`: `/app/temp` (temporary files)

### Volume Mounts
- **User Home**: `$HOME` → `/host/Users/$(whoami)` (full access)
- **Data Directory**: `$HOME/DynamicBounceMonitor/data` → `/app/data`
- **Output Directory**: `$HOME/DynamicBounceMonitor/output` → `/app/output`

## 👥 Team Deployment

### For 20 Users (3 Administrators)

#### Administrator Setup
1. **Build and test** the Docker image
2. **Push to Docker registry** (Docker Hub or private)
3. **Host the installer script** on a web server
4. **Share the installation command** with team

#### End User Installation
```bash
# One command - no technical knowledge required
curl -sSL https://your-domain.com/install-dynamic-bounce-monitor.sh | bash
```

#### User Experience
- **Desktop shortcut** for one-click access
- **Terminal aliases** for power users
- **Rich terminal interface** with categorized applications
- **Automatic updates** when you push new images

## 🆘 Troubleshooting

### Common Issues

1. **"Docker is not running"**
   ```bash
   # Start Docker Desktop and wait for it to fully load
   # Check the Docker icon in your system tray/menu bar
   ```

2. **"Image not found"**
   ```bash
   # Build the image first
   ./scripts/build.sh
   
   # Or pull from registry
   docker pull your-username/dynamic-bounce-monitor:latest
   ```

3. **"Permission denied"**
   ```bash
   # Make sure Docker Desktop is running
   # Check that your user can run Docker commands
   docker run hello-world
   ```

4. **"Files not accessible"**
   ```bash
   # Check volume mounts and permissions
   # Files should be in: ~/DynamicBounceMonitor/data/
   ```

### Getting Help

- 📧 **Issues**: Create GitHub issues for bugs
- 📖 **Documentation**: This README and inline help
- 🔧 **Configuration**: Check Docker logs: `docker logs dynamic-bounce-monitor`

## 🎯 Perfect For

- **🎵 Audio Production Teams** - Streamlined voice cleaning and processing
- **📺 Content Creators** - YouTube downloading and video optimization
- **🏢 Non-Technical Users** - Simple terminal interface for complex tools
- **👥 Mixed Teams** - Both technical and non-technical users
- **☁️ Remote Teams** - Consistent environment across all machines

## 🔒 Security Considerations

- **Container Isolation** - Applications run in isolated Docker containers
- **Limited Host Access** - Only mounted directories are accessible
- **No System Modifications** - Host system remains unchanged
- **Easy Cleanup** - Complete removal with `docker rmi dynamic-bounce-monitor`

## 📈 Scaling & Cloud Deployment

### Cloud Deployment Options
- **AWS ECS/Fargate** - Serverless container deployment
- **Google Cloud Run** - Fully managed container platform
- **Azure Container Instances** - Simple container hosting
- **Kubernetes** - For large-scale deployments

### Load Balancing
- Multiple container instances for high availability
- Shared storage for input/output files

## 📄 License

MIT License - feel free to use and modify for your team's needs.

---

**🎵 Made with ❤️ for teams who want powerful audio/video tools without the complexity**

### Quick Commands Reference

```bash
# Build and test
./scripts/build.sh
./scripts/run.sh

# Create installer
./scripts/create-installer.sh

# Deploy to Docker Hub
docker tag dynamic-bounce-monitor:latest username/dynamic-bounce-monitor:latest
docker push username/dynamic-bounce-monitor:latest
```