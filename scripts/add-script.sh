#!/bin/bash
# Script to add a new script container to Docker Application Launcher

set -e

# Print header
echo "🐳 Docker Application Launcher - Add Script Container"
echo "==================================================="
echo ""

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <script_name> [source_script_path]"
    echo ""
    echo "Examples:"
    echo "  $0 audio-enhancer"
    echo "  $0 voice-cleaner applications/voice_cleaner.py"
    exit 1
fi

SCRIPT_NAME=$1
SOURCE_PATH=$2

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$BASE_DIR/scripts/$SCRIPT_NAME"

echo "🔍 Adding new script container: $SCRIPT_NAME"
echo "📁 Target directory: $TARGET_DIR"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Create utils directory and copy path_utils.py
mkdir -p "$TARGET_DIR/utils"
if [ -f "$BASE_DIR/applications/utils/path_utils.py" ]; then
    echo "📄 Copying path_utils.py..."
    cp "$BASE_DIR/applications/utils/path_utils.py" "$TARGET_DIR/utils/path_utils.py"
    chmod +x "$TARGET_DIR/utils/path_utils.py"
    echo "✅ path_utils.py copied successfully"
else
    echo "⚠️ Warning: path_utils.py not found in applications/utils directory"
    echo "   Script container may have path handling issues"
fi

# Copy script if provided
if [ -n "$SOURCE_PATH" ]; then
    if [ -f "$SOURCE_PATH" ]; then
        echo "📄 Copying script from $SOURCE_PATH..."
        
        # Determine file extension
        EXT="${SOURCE_PATH##*.}"
        
        # Copy the file
        cp "$SOURCE_PATH" "$TARGET_DIR/script.$EXT"
        chmod +x "$TARGET_DIR/script.$EXT"
        
        echo "✅ Script copied successfully"
    else
        echo "❌ Source script not found: $SOURCE_PATH"
        exit 1
    fi
else
    # Create a template Python script
    echo "📄 Creating template Python script..."
    cat > "$TARGET_DIR/script.py" << 'EOF'
#!/usr/bin/env python3
"""
Docker Application Launcher - Script Container

This is a template script. Replace this with your actual script logic.
"""

import os
import sys
import argparse
from pathlib import Path

# Import utilities for path conversion
try:
    from utils.path_utils import convert_to_container_path, get_default_output_folder, validate_path
    print("✅ Successfully imported path_utils")
except ImportError as e:
    print(f"⚠️ WARNING: Could not import path_utils: {e}")
    print("⚠️ Path handling may not work correctly")
    # Fallbacks if utils are not available
    def convert_to_container_path(path):
        """Fallback path conversion if utils are not available"""
        if not path:
            return path
        path = str(path).strip().strip('"\'')
        if path.startswith('/host/'):
            return path
        if path.startswith('/Users/'):
            return f"/host{path}"
        if path.startswith('/home/'):
            return f"/host{path}"
        return path
    
    def get_default_output_folder():
        """Fallback output folder if utils are not available"""
        return Path("/app/output")
        
    def validate_path(path):
        """Fallback path validation if utils are not available"""
        if os.path.exists(path):
            return True, path
        container_path = convert_to_container_path(path)
        if container_path != path and os.path.exists(container_path):
            return True, container_path
        return False, path

def parse_arguments():
    parser = argparse.ArgumentParser(description="Script container template")
    parser.add_argument("--input", "-i", help="Input file or directory")
    parser.add_argument("--output", "-o", help="Output file or directory")
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    # Get input and output paths
    input_path = args.input
    output_path = args.output
    
    # Convert paths to container paths if provided
    if input_path:
        input_path = convert_to_container_path(input_path)
        # Validate the path exists
        input_exists, input_path = validate_path(input_path)
        if not input_exists:
            print(f"❌ Error: Input path does not exist: {input_path}")
            sys.exit(1)
    
    # Use default output folder if not specified
    if not output_path:
        output_path = get_default_output_folder()
    else:
        output_path = convert_to_container_path(output_path)
        # Create output directory if it doesn't exist
        try:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
        except Exception as e:
            print(f"⚠️ Warning: Could not create output directory: {e}")
    
    # Print welcome message
    print(f"🐳 Docker Application Launcher - Script Container")
    print(f"===============================================")
    print(f"Input: {input_path}")
    print(f"Output: {output_path}")
    print("")
    
    # Your script logic goes here
    print("✅ Script template executed successfully")
    print("Replace this template with your actual processing logic")

if __name__ == "__main__":
    main()
EOF
    chmod +x "$TARGET_DIR/script.py"
    echo "✅ Template script created"
fi

echo ""
echo "✅ Script container '$SCRIPT_NAME' added successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Edit script: $TARGET_DIR/script.py"
echo "  2. Build all containers: ./scripts/build-all.sh"
echo ""
echo "ℹ️ Note: All dependencies are in the orchestrator container."
echo "💡 Tip: Run './scripts/list-containers.sh' to see all available containers" 