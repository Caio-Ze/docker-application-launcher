#!/bin/bash
# List all available script containers for Docker Application Launcher

# Configuration
if [ -z "$OCIR_REGISTRY" ]; then
    REGISTRY=${REGISTRY:-"localhost/docker-application-launcher"}
else
    REGISTRY=${REGISTRY:-"$OCIR_REGISTRY/docker-application-launcher"}
fi

TAG=${TAG:-"latest"}

# Print header
echo "🐳 Docker Application Launcher - Available Containers"
echo "===================================================="
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    exit 1
fi

# List all script containers
echo "📋 Available Script Containers:"
echo "-------------------------------"

# Get all container images from this registry
docker images | grep "$REGISTRY" | grep -v "orchestrator" | awk '{print $1 " " $2 " " $3}' | while read IMAGE TAG ID; do
    # Extract the script name from the image name
    SCRIPT_NAME=$(echo $IMAGE | sed "s|$REGISTRY/||")
    
    echo "• $SCRIPT_NAME"
    # Get container description if available
    DESCRIPTION=$(docker inspect --format='{{index .Config.Labels "description"}}' "$IMAGE:$TAG" 2>/dev/null)
    if [ -n "$DESCRIPTION" ]; then
        echo "  Description: $DESCRIPTION"
    fi
done

# Check if orchestrator is available
if docker image inspect "$REGISTRY/orchestrator:$TAG" &> /dev/null; then
    echo ""
    echo "✅ Orchestrator container is available"
    echo "   Run ./scripts/run-orchestrator.sh to start"
else
    echo ""
    echo "⚠️ Orchestrator container is not available"
    echo "   Run ./scripts/build-all.sh to build all containers"
fi 