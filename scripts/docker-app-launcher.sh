#!/bin/bash

# Docker Application Launcher
# A simple menu-driven interface for managing Docker applications

set -e

# Configuration
APPS_DIR="$HOME/.docker-app-launcher/apps"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure apps directory exists
mkdir -p "$APPS_DIR"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_color $RED "❌ Docker is not installed. Please install Docker Desktop first."
        echo "   Download: https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_color $RED "❌ Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
}

# Function to load app configurations
load_apps() {
    local apps=()
    local app_files=()
    
    if [[ -d "$APPS_DIR" ]]; then
        while IFS= read -r -d '' file; do
            if [[ -f "$file" && "$file" == *.json ]]; then
                local app_name=$(jq -r '.name // "Unknown App"' "$file" 2>/dev/null || echo "Invalid JSON")
                if [[ "$app_name" != "Invalid JSON" ]]; then
                    apps+=("$app_name")
                    app_files+=("$file")
                fi
            fi
        done < <(find "$APPS_DIR" -name "*.json" -print0 2>/dev/null)
    fi
    
    echo "${#apps[@]}"
    printf '%s\n' "${apps[@]}"
    printf '%s\n' "${app_files[@]}"
}

# Function to get running containers
get_running_containers() {
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || echo ""
}

# Function to run an app
run_app() {
    local app_file=$1
    local app_name=$(jq -r '.name' "$app_file")
    local image=$(jq -r '.image' "$app_file")
    local interactive=$(jq -r '.interactive // false' "$app_file")
    local remove_after_exit=$(jq -r '.remove_after_exit // true' "$app_file")
    
    print_color $BLUE "🚀 Starting $app_name..."
    
    # Build docker command
    local docker_cmd="docker run"
    
    # Add remove flag if specified
    if [[ "$remove_after_exit" == "true" ]]; then
        docker_cmd+=" --rm"
    fi
    
    # Add interactive flags if specified
    if [[ "$interactive" == "true" ]]; then
        docker_cmd+=" -it"
    fi
    
    # Add volumes
    local volumes=$(jq -r '.volumes[]? | "--v \(.host):\(.container)"' "$app_file" 2>/dev/null)
    if [[ -n "$volumes" ]]; then
        # Expand environment variables in volumes
        volumes=$(echo "$volumes" | envsubst)
        docker_cmd+=" $volumes"
    fi
    
    # Add environment variables
    local env_vars=$(jq -r '.environment[]? | "-e \(.name)=\(.value)"' "$app_file" 2>/dev/null)
    if [[ -n "$env_vars" ]]; then
        docker_cmd+=" $env_vars"
    fi
    
    # Add ports
    local ports=$(jq -r '.ports[]? | "-p \(.host):\(.container)"' "$app_file" 2>/dev/null)
    if [[ -n "$ports" ]]; then
        docker_cmd+=" $ports"
    fi
    
    # Add additional flags
    local additional_flags=$(jq -r '.additional_flags // ""' "$app_file")
    if [[ -n "$additional_flags" && "$additional_flags" != "null" ]]; then
        docker_cmd+=" $additional_flags"
    fi
    
    # Add image
    docker_cmd+=" $image"
    
    print_color $CYAN "📋 Command: $docker_cmd"
    echo ""
    
    # Execute the command
    eval "$docker_cmd"
}

# Function to stop a container
stop_container() {
    local container_name=$1
    print_color $YELLOW "🛑 Stopping container: $container_name"
    docker stop "$container_name" 2>/dev/null || print_color $RED "❌ Failed to stop $container_name"
}

# Function to show app details
show_app_details() {
    local app_file=$1
    local app_name=$(jq -r '.name' "$app_file")
    local description=$(jq -r '.description // "No description available"' "$app_file")
    local image=$(jq -r '.image' "$app_file")
    
    print_color $PURPLE "📋 App Details: $app_name"
    echo "Description: $description"
    echo "Docker Image: $image"
    echo ""
    
    # Show volumes
    local volumes=$(jq -r '.volumes[]? | "  • \(.host) → \(.container) (\(.description // ""))"' "$app_file" 2>/dev/null)
    if [[ -n "$volumes" ]]; then
        echo "Volumes:"
        echo "$volumes"
        echo ""
    fi
    
    # Show ports
    local ports=$(jq -r '.ports[]? | "  • \(.host):\(.container) (\(.description // ""))"' "$app_file" 2>/dev/null)
    if [[ -n "$ports" ]]; then
        echo "Ports:"
        echo "$ports"
        echo ""
    fi
}

# Main menu function
show_menu() {
    clear
    print_color $CYAN "🐳 Docker Application Launcher"
    print_color $CYAN "=============================="
    echo ""
    
    # Load apps
    local app_data=($(load_apps))
    local app_count=${app_data[0]}
    local apps=("${app_data[@]:1:$app_count}")
    local app_files=("${app_data[@]:$((app_count+1)):$app_count}")
    
    if [[ $app_count -eq 0 ]]; then
        print_color $YELLOW "📭 No applications configured."
        echo "Add JSON configuration files to: $APPS_DIR"
        echo ""
        echo "Press any key to exit..."
        read -n 1
        exit 0
    fi
    
    # Show running containers
    local running=$(get_running_containers)
    if [[ -n "$running" && "$running" != "" ]]; then
        print_color $GREEN "🟢 Running Containers:"
        echo "$running"
        echo ""
    fi
    
    print_color $BLUE "📱 Available Applications:"
    for i in "${!apps[@]}"; do
        echo "$((i+1)). ${apps[i]}"
    done
    echo ""
    
    print_color $YELLOW "🔧 Management Options:"
    echo "$((app_count+1)). 📊 Show running containers"
    echo "$((app_count+2)). 🛑 Stop a container"
    echo "$((app_count+3)). 📋 Show app details"
    echo "$((app_count+4)). 🔄 Refresh"
    echo "$((app_count+5)). ❌ Exit"
    echo ""
    
    print_color $CYAN "Select an option (1-$((app_count+5))): "
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $app_count ]]; then
        # Run selected app
        local selected_app="${app_files[$((choice-1))]}"
        run_app "$selected_app"
        echo ""
        print_color $GREEN "Press any key to continue..."
        read -n 1
        show_menu
    elif [[ $choice -eq $((app_count+1)) ]]; then
        # Show running containers
        clear
        print_color $GREEN "🟢 Running Containers:"
        local running=$(get_running_containers)
        if [[ -n "$running" && "$running" != "" ]]; then
            echo "$running"
        else
            print_color $YELLOW "No containers are currently running."
        fi
        echo ""
        print_color $GREEN "Press any key to continue..."
        read -n 1
        show_menu
    elif [[ $choice -eq $((app_count+2)) ]]; then
        # Stop a container
        clear
        print_color $YELLOW "🛑 Stop Container"
        echo "Running containers:"
        docker ps --format "{{.Names}}" | nl
        echo ""
        echo "Enter container number to stop (or 0 to cancel): "
        read -r stop_choice
        if [[ "$stop_choice" =~ ^[0-9]+$ ]] && [[ $stop_choice -gt 0 ]]; then
            local container_name=$(docker ps --format "{{.Names}}" | sed -n "${stop_choice}p")
            if [[ -n "$container_name" ]]; then
                stop_container "$container_name"
            else
                print_color $RED "❌ Invalid selection"
            fi
        fi
        echo ""
        print_color $GREEN "Press any key to continue..."
        read -n 1
        show_menu
    elif [[ $choice -eq $((app_count+3)) ]]; then
        # Show app details
        clear
        print_color $PURPLE "📋 App Details"
        echo "Select an app to view details:"
        for i in "${!apps[@]}"; do
            echo "$((i+1)). ${apps[i]}"
        done
        echo ""
        echo "Enter app number (or 0 to cancel): "
        read -r detail_choice
        if [[ "$detail_choice" =~ ^[0-9]+$ ]] && [[ $detail_choice -ge 1 ]] && [[ $detail_choice -le $app_count ]]; then
            local selected_app="${app_files[$((detail_choice-1))]}"
            show_app_details "$selected_app"
        fi
        echo ""
        print_color $GREEN "Press any key to continue..."
        read -n 1
        show_menu
    elif [[ $choice -eq $((app_count+4)) ]]; then
        # Refresh
        show_menu
    elif [[ $choice -eq $((app_count+5)) ]]; then
        # Exit
        print_color $GREEN "👋 Goodbye!"
        exit 0
    else
        print_color $RED "❌ Invalid selection. Please try again."
        sleep 1
        show_menu
    fi
}

# Main execution
main() {
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_color $RED "❌ jq is required but not installed."
        print_color $YELLOW "Installing jq..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            print_color $RED "Please install jq manually: https://stedolan.github.io/jq/"
            exit 1
        fi
    fi
    
    check_docker
    show_menu
}

# Run main function
main "$@"