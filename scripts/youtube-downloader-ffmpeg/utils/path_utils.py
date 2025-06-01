#!/usr/bin/env python3
"""
Path Utilities for Docker Application Launcher
Handles host path conversions inside containers
"""

import os
import platform
from pathlib import Path

def convert_to_container_path(path):
    """
    Convert a host path to a container path if needed
    
    Args:
        path (str): A path that might be from the host system
        
    Returns:
        str: The path with /host prefix if needed
    """
    if not path:
        return path
        
    # Clean the path (remove quotes, etc.)
    path = path.strip().strip('"\'')
    
    # If it's already a container path, return it
    if path.startswith('/host/'):
        return path
        
    # Check if this is a macOS path
    if path.startswith('/Users/'):
        # This is a macOS path, prefix with /host
        return f"/host{path}"
        
    # Check if this is a Linux path
    if path.startswith('/home/'):
        # This is a Linux path, prefix with /host
        return f"/host{path}"
        
    # If it's a relative path or doesn't match patterns, return as is
    return path

def get_host_user():
    """
    Get the username of the host user
    
    Returns:
        str: The username of the host user
    """
    # First try to get it from environment variable
    host_user = os.environ.get('HOST_USER')
    if host_user:
        return host_user
        
    # Fallback to current user
    return os.environ.get('USER', 'user')

def get_host_home_dir():
    """
    Get the path to the host user's home directory
    
    Returns:
        Path: Path object representing the host home directory
    """
    user = get_host_user()
    
    # Check if we're on macOS-like host
    if os.path.exists('/host/Users'):
        return Path(f'/host/Users/{user}')
        
    # Check if we're on Linux-like host
    if os.path.exists('/host/home'):
        return Path(f'/host/home/{user}')
        
    # Fallback to current home directory (probably not correct in container)
    return Path.home()

def get_downloads_dir():
    """
    Get the path to the host user's Downloads directory
    
    Returns:
        Path: Path object representing the Downloads directory
    """
    home_dir = get_host_home_dir()
    return home_dir / 'Downloads'

def get_default_output_folder():
    """
    Get the default output folder for applications
    
    Returns:
        Path: Path object representing the default output folder
    """
    # Try the standard output directory first
    if os.path.exists('/app/output') and os.access('/app/output', os.W_OK):
        return Path('/app/output')
        
    # Fallback to Downloads directory
    return get_downloads_dir()

def validate_path(path):
    """
    Check if a path exists, trying both as-is and with /host prefix
    
    Args:
        path (str): Path to validate
        
    Returns:
        tuple: (bool, str) - (is_valid, validated_path)
    """
    # First try the path as provided
    if os.path.exists(path):
        return True, path
        
    # If path doesn't exist, try with /host prefix
    container_path = convert_to_container_path(path)
    if container_path != path and os.path.exists(container_path):
        return True, container_path
        
    # Path doesn't exist either way
    return False, path

def is_running_in_container():
    """
    Check if the code is running inside a container
    
    Returns:
        bool: True if running in container, False otherwise
    """
    # Check for common container indicators
    if os.path.exists('/.dockerenv'):
        return True
        
    if os.path.exists('/app'):
        return True
        
    # Check cgroup (Linux)
    try:
        with open('/proc/1/cgroup', 'r') as f:
            return 'docker' in f.read()
    except:
        pass
        
    return False 