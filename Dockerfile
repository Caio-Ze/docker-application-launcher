# Dynamic Bounce Monitor - Docker Application Launcher
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    wget \
    git \
    jq \
    nano \
    vim \
    htop \
    tree \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY applications/ ./applications/
COPY scripts/ ./scripts/

# Create assets directory (copy if exists, otherwise create empty)
RUN mkdir -p ./assets/

# Make scripts executable
RUN chmod +x scripts/*.sh 2>/dev/null || true
RUN chmod +x applications/*.py

# Create directories for user data
RUN mkdir -p /app/data /app/output /app/temp /app/templates

# Set up the launchers
COPY launcher.py .
RUN chmod +x launcher.py

# Create startup script
RUN echo '#!/bin/bash\n\
echo "🎵 Dynamic Bounce Monitor - Starting..."\n\
echo "======================================"\n\
echo "💻 Terminal Interface Ready"\n\
echo ""\n\
python launcher.py' > /app/start.sh && chmod +x /app/start.sh

# Default command
CMD ["/app/start.sh"] 