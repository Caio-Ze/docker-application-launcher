# Docker Application Launcher - Multi-Container Application Processing Suite

A modular, containerized application launcher system that orchestrates multiple lightweight containers for specialized tasks.

## Overview

The Docker Application Launcher provides a unified interface to run various containerized applications. Each application runs in its own isolated container with only the dependencies it needs, making the system modular and lightweight.

### Key Features

- **Multi-Container Architecture**: Runs applications in isolated containers
- **Orchestrator Interface**: Simple menu-driven interface to launch containers
- **Automatic Path Handling**: Converts file paths between host and containers
- **Easy to Extend**: Simple process to add new script containers
- **Consistent Environment**: Each script runs in the same environment every time

## Installation

### Quick Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-application-launcher.git
cd docker-application-launcher

# Run the installer
./install.sh
```

### Development Installation

For development and testing, use the development installer:

```bash
./install-dev.sh
```

This creates a separate installation with the `dev` tag.

## Usage

### Running the Application

After installation, run:

```bash
~/docker-app-launcher.sh
```

For development version:

```bash
~/docker-app-launcher-dev.sh
```

### Using the Interface

1. Select an application from the menu
2. Follow the prompts for input/output files
3. Results will be saved to the output directory

## Architecture

The Docker Application Launcher uses a multi-container architecture:

### Orchestrator Container

The main container that provides the user interface and coordinates script containers. It contains:

- Python with Rich UI library
- Docker CLI to manage script containers
- Shared utilities for all scripts

### Script Containers

Lightweight containers that each perform a specific function:

- YouTube Downloader: Downloads videos and converts to audio
- Voice Cleaner: Processes voice recordings
- WAV/MP3 Converter: Converts between audio formats
- Video Optimizer: Optimizes videos for different platforms
- PTX Copier: Manages project files
- And more...

## Directory Structure

```
docker-application-launcher/
├── Dockerfile.orchestrator       # Dockerfile for the main container
├── Dockerfile.script-template    # Template for script containers
├── applications/                 # Application scripts
│   └── utils/                    # Shared utilities
│       └── path_utils.py         # Path handling utilities
├── scripts/                      # Script container management
│   ├── add-script.sh             # Tool to add new script containers
│   ├── build-all.sh              # Builds all containers
│   ├── list-containers.sh        # Lists available containers
│   ├── run-orchestrator.sh       # Runs the orchestrator container
│   └── script-containers/        # Individual script containers
│       ├── youtube-downloader/   # YouTube downloader script
│       ├── voice-cleaner-api1/   # Voice cleaning (API 1)
│       └── ...                   # Other script containers
├── launcher.py                   # Main launcher script
├── requirements.txt              # Python dependencies
├── install.sh                    # Production installer
└── install-dev.sh                # Development installer
```

## Adding New Scripts

To add a new script container:

```bash
./scripts/add-script.sh my-new-script
```

This creates a new script container template that you can customize.

## Script Container Directory

The `scripts/` directory contains all the script containers for the Docker Application Launcher:

- **youtube-downloader**: Downloads videos from YouTube and converts to MP3
- **voice-cleaner-api1**: Cleans voice recordings using API 1
- **voice-cleaner-api2**: Cleans voice recordings using API 2
- **wav-mp3-converter**: Converts between WAV and MP3 formats
- **video-optimizer**: Optimizes videos for different platforms
- **ptx-copier**: Copies PTX files to destination folders
- **folder-creator**: Creates standardized folder structures

## Technical Details

### Dependency Management

The Docker Application Launcher uses a **unified dependency approach**:

1. **Orchestrator Container**: Contains all dependencies for all scripts
2. **Script Containers**: Contain only the script and minimal runtime

This approach reduces the size of script containers and speeds up build time.

### Path Handling

The system automatically handles path conversion between the host and containers:

- Host paths are converted to container paths
- Container paths are converted back to host paths
- Special handling for different operating systems

## License

[MIT License](LICENSE)

## Credits

Created by [Your Name]