#!/bin/bash
# Build script for Docker Application Launcher containers

# Exit on error
set -e

# Configuration
if [ -z "$OCIR_REGISTRY" ]; then
    REGISTRY=${REGISTRY:-"localhost/docker-application-launcher"}
else
    REGISTRY=${REGISTRY:-"$OCIR_REGISTRY/docker-application-launcher"}
fi
TAG=${TAG:-"latest"}
PUSH=${PUSH:-"false"}

# Function Definitions First

build_orchestrator() {
    echo "🔨 Building orchestrator container..."
    # Orchestrator Dockerfile is at ./Dockerfile.orchestrator (or just Dockerfile.orchestrator)
    # Orchestrator build context is . (current directory: docker-application-launcher/)
    # It needs requirements.txt from the current directory.
    echo "  Copying requirements.txt for orchestrator context (if not already present by Dockerfile COPY)"
    # Dockerfile.orchestrator should handle copying its own requirements.txt from its context.
    docker build -t "$REGISTRY/orchestrator:$TAG" -f Dockerfile.orchestrator .
    echo "✅ Orchestrator container built successfully"
    
    if [ "$PUSH" = "true" ]; then
        echo "🚀 Pushing orchestrator container... ($REGISTRY/orchestrator:$TAG)"
        docker push "$REGISTRY/orchestrator:$TAG"
    fi
}

build_script_container() {
    local name=$1
    local script_type=$2
    local script_path=$3 # This is the path to the script in its prepared subdir, e.g. ./youtube-downloader-ffmpeg/script.py
    # temp_dir_for_script is relative to current dir (docker-application-launcher), e.g. ./temp-build/<name>
    local temp_dir_for_script="temp-build/$name" 

    echo "  Creating temporary directory for script: $temp_dir_for_script (resolved: $(readlink -f "$temp_dir_for_script" 2>/dev/null || echo "$temp_dir_for_script not yet created"))"
    mkdir -p "$temp_dir_for_script"
    
    # Copy the path_utils.py for Python scripts
    if [ "$script_type" = "py" ]; then
        mkdir -p "$temp_dir_for_script/utils"
        # Source: ./applications/utils/path_utils.py
        # Dest: ./temp-build/$name/utils/path_utils.py
        cp "./applications/utils/path_utils.py" "$temp_dir_for_script/utils/path_utils.py"
        echo "  Copied path_utils.py to $temp_dir_for_script/utils/"
    fi
    
    # Copy the script itself into the temp context
    # Source script_path is like ./<container_name>/script.py (e.g. ./youtube-downloader-ffmpeg/script.py)
    # Dest: ./temp-build/$name/script.py
    echo "  Copying script $script_path to $temp_dir_for_script/script.$script_type"
    cp "$script_path" "$temp_dir_for_script/script.$script_type"
    
    # Copy requirements.txt to the temporary build directory
    # Source: ./requirements.txt (docker-application-launcher/requirements.txt)
    # Dest: ./temp-build/$name/requirements.txt
    echo "  Copying ./requirements.txt to $temp_dir_for_script/requirements.txt"
    cp "./requirements.txt" "$temp_dir_for_script/requirements.txt"
    
    # Create temporary Dockerfile from template
    # Source: ./Dockerfile.script-template
    # Dest: ./temp-build/$name/Dockerfile
    echo "  Generating Dockerfile from ./Dockerfile.script-template into $temp_dir_for_script/Dockerfile"
    sed -e "s|SCRIPT_EXT|$script_type|g" \
        "./Dockerfile.script-template" > "$temp_dir_for_script/Dockerfile.tmp"

    if [ "$script_type" = "sh" ]; then # Comment out 'COPY utils' for shell scripts
        sed -e '/COPY utils \/app\/utils/ s/^/#/' "$temp_dir_for_script/Dockerfile.tmp" > "$temp_dir_for_script/Dockerfile"
    else # For python scripts, utils are copied
        mv "$temp_dir_for_script/Dockerfile.tmp" "$temp_dir_for_script/Dockerfile"
    fi
    
    # Add a newline before appending CMD, then append CMD
    echo "" >> "$temp_dir_for_script/Dockerfile" # Ensure CMD is on a new line
    if [ "$script_type" = "py" ]; then
        echo "CMD [\"sh\", \"-c\", \"cat /app/script.py && echo '--- END OF SCRIPT ---' && python /app/script.py\"]" >> "$temp_dir_for_script/Dockerfile"
    elif [ "$script_type" = "sh" ]; then
        echo "CMD [\"/bin/bash\", \"/app/script.sh\"]" >> "$temp_dir_for_script/Dockerfile"
    fi

    echo "--- Content of generated Dockerfile for $name: ---"
    cat "$temp_dir_for_script/Dockerfile"
    echo "--- End of Dockerfile for $name ---"
    
    echo "  Current directory before docker build: $(pwd)"
    echo "  Contents of build context '$temp_dir_for_script' (resolved: $(readlink -f "$temp_dir_for_script")) before Docker build:"
    ls -la "$temp_dir_for_script"
    
    # Build the container
    # Dockerfile path: ./temp-build/$name/Dockerfile
    # Build context: ./temp-build/$name
    local docker_image_tag="$REGISTRY/$name:$TAG"
    echo "  Attempting to build Docker image: $docker_image_tag"
    echo "  Building container $name with context $(readlink -f "$temp_dir_for_script") and Dockerfile $(readlink -f "$temp_dir_for_script/Dockerfile")"
    
    docker build --no-cache --build-arg PASSED_SCRIPT_NAME="$name" -t "$docker_image_tag" -f "$temp_dir_for_script/Dockerfile" "$temp_dir_for_script"
    
    echo "✅ $name container built successfully"

    if [ "$PUSH" = "true" ]; then
        echo "🚀 Pushing $name container... ($docker_image_tag)"
        docker push "$docker_image_tag"
    fi
}

# Ensure path_utils.py exists in the main applications/utils directory
ensure_path_utils() {
    # This path is relative to build-all.sh (docker-application-launcher/)
    local target_utils_dir="./applications/utils"
    mkdir -p "$target_utils_dir" 
    
    if [ ! -f "$target_utils_dir/path_utils.py" ]; then
        echo "Creating path_utils.py in $target_utils_dir..."
        # Content of path_utils.py should be complete here
        cat > "$target_utils_dir/path_utils.py" <<'EOF'
#!/usr/bin/env python3
\"\"\"
Path Utilities for Docker Application Launcher
Handles host path conversions inside containers
\"\"\"

import os
from pathlib import Path
import platform # Added import

def convert_to_container_path(path):
    \"\"\"
    Convert a host path to a container path if needed
    
    Args:
        path (str): A path that might be from the host system
        
    Returns:
        str: The path with /host prefix if needed
    \"\"\"
    if not path:
        return path
    path = str(path).strip().strip('\"\\\'')
    if path.startswith('/host/'):
        return path
    # Standard User home directories
    if path.startswith('/Users/'): # macOS
        return f"/host{path}"
    if path.startswith('/home/'): # Linux
        return f"/host{path}"
    # Add other common host paths if necessary, e.g. /mnt/c for WSL
    return path

def get_host_user():
    \"\"\"
    Get the username of the host user
    
    Returns:
        str: The username of the host user
    \"\"\"
    return os.environ.get('HOST_USER', os.environ.get('USER', 'user'))

def get_host_home_dir():
    \"\"\"
    Get the path to the host user's home directory, prefixed for container access.
    
    Returns:
        Path: Path object representing the host home directory inside the container.
    \"\"\"
    actual_host_home = os.environ.get('HOST_HOME_DIR_FOR_CONTAINER') 
    if actual_host_home and os.path.isdir(actual_host_home):
        return Path(actual_host_home)

    user = get_host_user()
    if platform.system() == "Darwin": # macOS
        host_home_candidate = Path(f"/host/Users/{user}")
        if host_home_candidate.is_dir(): return host_home_candidate
    else: # Linux
        host_home_candidate = Path(f"/host/home/{user}")
        if host_home_candidate.is_dir(): return host_home_candidate
    
    # Fallback if specific structure not found, though less reliable
    # This indicates a potential issue with how $HOME is mounted or HOST_HOME_DIR_FOR_CONTAINER is set
    print(f"Warning: Could not reliably determine host home for user {user} via /host/Users or /host/home. Check Docker volume mounts.")
    return Path(f"/host/home/{user}") # Generic fallback


def get_downloads_dir():
    \"\"\"
    Get the path to the host user's Downloads directory, prefixed for container.
    
    Returns:
        Path: Path object representing the Downloads directory.
    \"\"\"
    home_dir = get_host_home_dir()
    return home_dir / 'Downloads'

def get_default_output_folder():
    \"\"\"
    Get the default output folder for applications.
    Attempts to use /app/output if writable, otherwise host's Downloads.
    
    Returns:
        Path: Path object representing the default output folder.
    \"\"\"
    app_output = Path('/app/output')
    if app_output.is_dir() and os.access(str(app_output), os.W_OK):
        return app_output
    
    return get_downloads_dir()

def validate_path(path_to_validate):
    \"\"\"
    Check if a path exists, trying both as-is and with /host prefix if applicable.
    
    Args:
        path_to_validate (str): Path to validate
        
    Returns:
        tuple: (bool, str) - (is_valid, validated_path_str)
               Returns (False, original_path_str) if no valid path is found.
    \"\"\"
    if not path_to_validate:
        return False, str(path_to_validate)

    path_str = str(path_to_validate).strip().strip('\"\\\'')
    
    if os.path.exists(path_str):
        return True, path_str
    
    potential_container_path = convert_to_container_path(path_str)
    if potential_container_path != path_str and os.path.exists(potential_container_path):
        return True, potential_container_path
        
    return False, path_str 

def is_running_in_container():
    \"\"\"
    Check if the code is running inside a Docker container.
    
    Returns:
        bool: True if running in container, False otherwise.
    \"\"\"
    if os.path.exists('/.dockerenv'):
        return True
        
    if os.path.isdir('/app'): 
        return True
        
    try:
        with open('/proc/1/cgroup', 'rt', encoding='utf-8') as f: 
            if 'docker' in f.read() or 'kubepods' in f.read(): 
                return True
    except FileNotFoundError: 
        pass
    except IOError: 
        pass
        
    if any(key in os.environ for key in ['KUBERNETES_SERVICE_HOST', 'ECS_CONTAINER_METADATA_URI']):
        return True
        
    return False

if __name__ == '__main__':
    print(f"Running in container: {is_running_in_container()}")

EOF
        chmod +x "$target_utils_dir/path_utils.py"
        echo "✅ Created path_utils.py in $target_utils_dir"
    else
        echo "✅ path_utils.py already exists in $target_utils_dir"
    fi
}

setup_script_containers() {
    # Source of scripts is ./applications (relative to build-all.sh CWD)
    local source_applications_dir="./applications"
    # Destination for prepared scripts is the current directory (docker-application-launcher/) in subfolders
    # These subfolders (e.g., ./youtube-downloader-ffmpeg/) become the $script_path for build_script_container
    local prepared_scripts_target_dir="." 
    
    echo "🔍 Setting up script files from $source_applications_dir into subdirectories of $(readlink -f "$prepared_scripts_target_dir")..."
    
    if [ ! -d "$source_applications_dir" ]; then
        echo "❌ ERROR: Source applications directory not found: $(readlink -f "$source_applications_dir")"
        exit 1
    fi
    if [ ! -d "$source_applications_dir/utils" ] || [ ! -f "$source_applications_dir/utils/path_utils.py" ]; then
        echo "⚠️ Warning: path_utils.py not found in $source_applications_dir/utils. Ensure ensure_path_utils ran correctly."
    fi

    local py_scripts=$(find "$source_applications_dir" -maxdepth 1 -name "*.py" -type f -not -path "*/utils/*")
    local sh_scripts=$(find "$source_applications_dir" -maxdepth 1 -name "*.sh" -type f -not -path "*/utils/*")
    
    for script_abs_path in $py_scripts; do
        local script_basename=$(basename "$script_abs_path" .py)
        local container_name=$(echo "$script_basename" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
        # Target directory for this script, e.g. ./youtube-downloader-ffmpeg/
        local target_script_dir="$prepared_scripts_target_dir/$container_name" 
        
        echo "  📦 Setting up for Python script $script_basename (container: $container_name) in $target_script_dir"
        mkdir -p "$target_script_dir" # Creates ./<container_name>
        cp "$script_abs_path" "$target_script_dir/script.py" # Copies app script to ./<container_name>/script.py
        chmod +x "$target_script_dir/script.py"
        
        mkdir -p "$target_script_dir/utils"
        cp "$source_applications_dir/utils/path_utils.py" "$target_script_dir/utils/" 
        
        echo "  ✅ Python script $script_basename setup complete in $target_script_dir"
    done
    
    for script_abs_path in $sh_scripts; do
        local script_basename=$(basename "$script_abs_path" .sh)
        local container_name=$(echo "$script_basename" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
        local target_script_dir="$prepared_scripts_target_dir/$container_name"

        echo "  📦 Setting up for Shell script $script_basename (container: $container_name) in $target_script_dir"
        mkdir -p "$target_script_dir"
        cp "$script_abs_path" "$target_script_dir/script.sh"
        chmod +x "$target_script_dir/script.sh"
        echo "  ✅ Shell script $script_basename setup complete in $target_script_dir"
    done
    echo "✅ Script setup phase complete."
} 

# Print header
echo "🐳 Docker Application Launcher - Container Builder"
echo "================================================="
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "Push images: $PUSH"
echo "-------------------------------------------------"


# Check Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    echo "Please start Docker Desktop or Docker service"
    exit 1
else
    echo "✅ Docker is running."
fi

# Main execution
echo "🚀 Starting build process..."

# Clean up previously created script directories (e.g., ./youtube-downloader-ffmpeg)
# but not temp-build, applications, scripts, manual-build etc.
echo "🧹 Cleaning up any previously prepared script directories (excluding essential ones)..."
# List directories, exclude known project structure dirs, then attempt to remove
find . -mindepth 1 -maxdepth 1 -type d -not -name 'temp-build' -not -name 'applications' -not -name 'scripts' -not -name 'manual-build' -not -name '.*' -exec rm -rf {} + 2>/dev/null || true


# This creates ./temp-build, used by build_script_container
if [ -d "temp-build" ]; then 
    echo "🧹 Cleaning up existing local temp-build directory..."
    rm -rf "temp-build"
fi
mkdir -p "temp-build" 
echo "🛠️ Created local temp-build directory: $(readlink -f temp-build)"


ensure_path_utils

setup_script_containers

build_orchestrator

echo "-------------------------------------------------"
echo "🔍 Identifying and building script containers from subdirectories in $(pwd)..."
# This loop iterates through subdirectories of the current directory (docker-application-launcher)
# It expects scripts to be in ./<container-name>/script.py (or .sh) after setup_script_containers
for script_dir_item in */ ; do
    script_dir_item_cleaned=${script_dir_item%/}

    # Skip directories that are not script containers prepared by setup_script_containers
    if [[ "$script_dir_item_cleaned" == "temp-build" || \
          "$script_dir_item_cleaned" == "applications" || \
          "$script_dir_item_cleaned" == "scripts" || \
          "$script_dir_item_cleaned" == "manual-build" || \
          "$script_dir_item_cleaned" == ".*" || \
          ( ! -f "./$script_dir_item_cleaned/script.py" && ! -f "./$script_dir_item_cleaned/script.sh" ) \
       ]]; then
        if [[ "$script_dir_item_cleaned" != "temp-build" && \
              "$script_dir_item_cleaned" != "applications" && \
              "$script_dir_item_cleaned" != "scripts" && \
              "$script_dir_item_cleaned" != "manual-build" && \
              "$script_dir_item_cleaned" != ".*" ]]; then
             # Only log warning for unexpected skips, not for known infra dirs.
             echo "⚠️ Warning: Directory $script_dir_item_cleaned does not appear to be a prepared script container (no script.py/sh) or is an excluded infra directory. Skipping."
        else
            echo "  Skipping directory (infra or not a script source): $script_dir_item_cleaned"
        fi
        continue
    fi
    
    # If we reach here, it's a directory that should contain a script
    # The previous condition was to SKIP if it's an infra dir OR if it doesn't have script.py/sh
    # So, if not skipped, it must be a script dir.
    # The original if [ -d "$script_dir_item_cleaned" ] is redundant now because the loop `for script_dir_item in */` only gives directories.

    script_name_from_dir=$(basename "$script_dir_item_cleaned") 
    
    script_file_py="./$script_dir_item_cleaned/script.py"
    script_file_sh="./$script_dir_item_cleaned/script.sh"
    
    if [ -f "$script_file_py" ]; then
        echo "-------------------------------------------------"
        echo "🐍 Processing Python script: $script_name_from_dir (Source: $script_file_py)"
        build_script_container "$script_name_from_dir" "py" "$script_file_py"
    elif [ -f "$script_file_sh" ];then
        echo "-------------------------------------------------"
        echo "🐚 Processing Shell script: $script_name_from_dir (Source: $script_file_sh)"
        build_script_container "$script_name_from_dir" "sh" "$script_file_sh"
    else
        # This case should ideally not be reached if the skip logic above is correct
        echo "🔥 INTERNAL LOGIC ERROR or UNEXPECTED STATE: Directory $script_dir_item_cleaned was not skipped but has no script.py/sh. Check skip logic."
    fi
done
echo "-------------------------------------------------"
echo "✅ All script containers processed."

echo "-------------------------------------------------"
echo "🧹 Cleaning up main temporary build files from $(readlink -f temp-build)..."
rm -rf "temp-build"

echo ""
echo "🎉 All Docker Application Launcher containers built successfully!"
echo ""
echo "📋 Final Images:"
docker images | grep "$REGISTRY" | sort || echo "No images found for $REGISTRY. Build might have failed for all."

echo ""
echo "🚀 To run the orchestrator (example):"
echo "   ./run-orchestrator.sh"
echo "   (Or manually: docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v \$HOME:/host\$HOME -v \"\$(pwd)\":/app \"$REGISTRY/orchestrator:$TAG\")"
echo ""
echo "💡 Tip: Ensure run-orchestrator.sh is in the project root (this directory) and is executable."


</rewritten_file> 