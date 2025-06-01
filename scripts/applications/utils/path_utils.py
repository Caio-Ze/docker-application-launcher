#!/usr/bin/env python3
"""
Path Utilities for Docker Application Launcher
Handles host path conversions inside containers
"""

import os
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
    path = str(path).strip().strip('"\'')
    if path.startswith('/host/'):
        return path
    if path.startswith('/Users/'):
        return f"/host{path}"
    if path.startswith('/home/'):
        return f"/host{path}"
    return path

def get_host_user():
    """
    Get the username of the host user
    
    Returns:
        str: The username of the host user
    """
    return os.environ.get('HOST_USER', os.environ.get('USER', 'user'))

def get_host_home_dir():
    """
    Get the path to the host user's home directory
    
    Returns:
        Path: Path object representing the host home directory
    """
    user = get_host_user()
    if os.path.exists('/host/Users'):
        return Path(f'/host/Users/{user}')
    if os.path.exists('/host/home'):
        return Path(f'/host/home/{user}')
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
    if os.path.exists('/app/output') and os.access('/app/output', os.W_OK):
        return Path('/app/output')
    return get_downloads_dir()

def validate_path(path):
    """
    Check if a path exists, trying both as-is and with /host prefix
    
    Args:
        path (str): Path to validate
        
    Returns:
        tuple: (bool, str) - (is_valid, validated_path)
    """
    if os.path.exists(path):
        return True, path
    container_path = convert_to_container_path(path)
    if container_path != path and os.path.exists(container_path):
        return True, container_path
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
