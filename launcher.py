#!/usr/bin/env python3
"""
Docker Application Launcher - Docker Application Orchestrator
This script provides a menu interface to run applications in isolated Docker containers
"""

import os
import sys
import subprocess
import time
from pathlib import Path

# Rich UI components - ensure rich==13.3.5 is installed
# pip install rich==13.3.5
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.prompt import Prompt, Confirm
from rich.text import Text
from rich import print as rprint

console = Console()

class ContainerOrchestrator:
    def __init__(self):
        rprint("[bold yellow]DEBUG: Initializing ContainerOrchestrator[/bold yellow]")
        rprint(f"[bold red]WARNING: Environment check for critical path variables[/bold red]")
        
        # Get all environment variables
        for key, value in sorted(os.environ.items()):
            if 'HOME' in key or 'DIR' in key:
                rprint(f"[yellow]ENV: {key} = {value}[/yellow]")
        
        rprint(f"[bold yellow]DEBUG: Path.home() inside orchestrator: {str(Path.home())}[/bold yellow]")

        # Setup configuration
        self.registry = os.environ.get("CONTAINER_REGISTRY", "localhost/docker-application-launcher")
        self.tag = os.environ.get("CONTAINER_TAG", "latest")
        self.host_user = os.environ.get("HOST_USER", os.environ.get("USER", "user"))
        
        # SIMPLIFIED APPROACH: Hardcode known good paths for macOS
        # This bypasses all the environment variable complexity
        self.host_os = os.environ.get("HOST_OS", "mac")
        
        # These are the ACTUAL paths on the macOS host
        if self.host_os == "mac":
            self.host_home_dir = "/Users/caioraphael"  # Hardcoded for macOS
        else:
            self.host_home_dir = "/home/caioraphael"   # Fallback for Linux
            
        # Define data and output directories on host
        self.host_data_dir = f"{self.host_home_dir}/DockerApplicationLauncher/data"
        self.host_output_dir = f"{self.host_home_dir}/DockerApplicationLauncher/output"
        
        # Log paths being used
        rprint(f"[bold green]Using host home directory: {self.host_home_dir}[/bold green]")
        rprint(f"[bold green]Using host data directory: {self.host_data_dir}[/bold green]")
        rprint(f"[bold green]Using host output directory: {self.host_output_dir}[/bold green]")
        
        # Applications configuration
        self.applications = [
            {
                "id": 1,
                "name": "YouTube Downloader",
                "description": "Download videos from YouTube and convert to MP3",
                "container": "youtube-downloader-ffmpeg",
                "category": "Content Acquisition"
            },
            {
                "id": 2,
                "name": "Voice Cleaner API1",
                "description": "Clean voice recordings using processing API 1",
                "container": "voice-cleaner-api1",
                "category": "Audio Processing"
            },
            {
                "id": 3,
                "name": "Voice Cleaner API2",
                "description": "Clean voice recordings using processing API 2",
                "container": "voice-cleaner-api2",
                "category": "Audio Processing"
            },
            {
                "id": 4,
                "name": "WAV/MP3 Converter",
                "description": "Convert between WAV and MP3 audio formats",
                "container": "wavmp3-fix",
                "category": "Audio Processing"
            },
            {
                "id": 5,
                "name": "Video Optimizer",
                "description": "Optimize video files for different platforms",
                "container": "optimize-videos-ffmpeg",
                "category": "Video Processing"
            },
            {
                "id": 6,
                "name": "PTX Copier",
                "description": "Copy PTX files and audio files to destination folders",
                "container": "copy-ptx-crf",
                "category": "File Management"
            },
            {
                "id": 7,
                "name": "PTX Copier (No AM)",
                "description": "Copy PTX files without AM flag to destination folders",
                "container": "copy-ptx-crf-sem-am",
                "category": "File Management"
            },
            {
                "id": 8,
                "name": "Folder Creator",
                "description": "Create standardized folder structures for projects",
                "container": "extra-para-net-space-fix",
                "category": "File Management"
            },
            {
                "id": 9,
                "name": "Audio Enhancer",
                "description": "Enhance audio quality with volume normalization",
                "container": "pastas-crf",
                "category": "Audio Processing"
            }
        ]

    def run_docker_container(self, container_name):
        """Run a script container using Docker CLI"""
        console.print(f"[bold]Running {container_name} container...[/bold]")
        
        try:
            # Check if the container image exists
            check_cmd = ["docker", "image", "inspect", f"{self.registry}/{container_name}:{self.tag}"]
            result = subprocess.run(check_cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                console.print(f"[yellow]Container image not found: {self.registry}/{container_name}:{self.tag}[/yellow]")
                
                # Ask if user wants to pull or build the image
                choice = Prompt.ask(
                    "Do you want to [b]uild or [s]kip?",
                    choices=["b", "s"],
                    default="s"
                )
                
                if choice == "s":
                    return
                
                # Build the image
                console.print("[yellow]Building image...[/yellow]")
                # Use build-all.sh script instead of direct docker build
                script_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "scripts", "build-all.sh")
                if not os.path.exists(script_path):
                    script_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "scripts", "build-all.sh")
                
                if os.path.exists(script_path):
                    build_cmd = ["bash", script_path]
                    build_result = subprocess.run(build_cmd)
                    
                    if build_result.returncode != 0:
                        console.print("[red]Failed to build image using build-all.sh[/red]")
                        return
                else:
                    console.print(f"[red]Cannot find build script at {script_path}[/red]")
                    console.print("[red]Please run the build-all.sh script manually to build all containers[/red]")
                    return
            
            # Set up paths for script container
            script_container_host_mount = f"/host{self.host_home_dir}"
            
            rprint(f"[bold yellow]LAUNCHING SCRIPT CONTAINER: {container_name}[/bold yellow]")
            rprint(f"[bold yellow]Volume mounts:[/bold yellow]")
            rprint(f"[bold yellow]  Host home dir: {self.host_home_dir} -> {script_container_host_mount}[/bold yellow]")
            rprint(f"[bold yellow]  Host data dir: {self.host_data_dir} -> /app/data[/bold yellow]")
            rprint(f"[bold yellow]  Host output dir: {self.host_output_dir} -> /app/output[/bold yellow]")

            console.print(f"[green]✓ Starting container: {container_name}[/green]")
            
            # Build Docker run command - let the container use its default CMD
            docker_cmd = f"docker run --rm -it "
            docker_cmd += f"-v {self.host_home_dir}:{script_container_host_mount} "
            docker_cmd += f"-v {self.host_data_dir}:/app/data "
            docker_cmd += f"-v {self.host_output_dir}:/app/output "
            docker_cmd += f"-e HOST_USER={self.host_user} "
            docker_cmd += f"-e DATA_DIR=/app/data "
            docker_cmd += f"-e OUTPUT_DIR=/app/output "
            docker_cmd += f"-e HOST_HOME={script_container_host_mount} "
            docker_cmd += f"-e PYTHONUNBUFFERED=1 "
            docker_cmd += f"-e TERM=xterm-256color "
            docker_cmd += f"{self.registry}/{container_name}:{self.tag}"
                
            rprint(f"[bold yellow]Executing: {docker_cmd}[/bold yellow]")
            
            # Use os.system instead of subprocess.run for more reliable terminal handling
            os.system(docker_cmd)
            
            console.print(f"[green]✓ Container {container_name} completed[/green]")
            
        except Exception as e:
            console.print(f"[red]Error running container: {str(e)}[/red]")
            import traceback
            traceback.print_exc()

    def show_menu(self):
        """Display main menu"""
        # Group applications by category
        categories = {}
        for app in self.applications:
            category = app.get("category", "Uncategorized")
            if category not in categories:
                categories[category] = []
            categories[category].append(app)
        
        # Create table
        table = Table(title="Docker Application Launcher - Applications")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Description", style="yellow")
        table.add_column("Category", style="blue")
        
        # Add applications to table
        for category, apps in categories.items():
            for app in apps:
                table.add_row(
                    str(app["id"]),
                    app["name"],
                    app["description"],
                    category
                )
        
        # Add exit option
        table.add_row("0", "Exit", "Exit the application", "System")
        
        # Display table
        console.print(table)
        
        # Get user choice
        choice = Prompt.ask(
            "Enter application ID to launch",
            choices=[str(app["id"]) for app in self.applications] + ["0"],
            default="0"
        )
        
        if choice == "0":
            return False
        
        # Find and run the selected application
        for app in self.applications:
            if str(app["id"]) == choice:
                self.run_docker_container(app["container"])
                break
        
        return True

    def start(self):
        """Start the application orchestrator"""
        # Display header
        console.print(Panel.fit(
            "[bold blue]Docker Application Launcher[/bold blue]\n"
            "[green]Multi-Container Application Processing Suite[/green]",
            title="🐳 Docker Application Launcher",
            subtitle="v2.0.0"
        ))
        
        # Main menu loop
        running = True
        while running:
            try:
                running = self.show_menu()
            except KeyboardInterrupt:
                console.print("\n[yellow]Operation interrupted[/yellow]")
                running = Confirm.ask("Return to main menu?", default=True)
        
        console.print(Panel.fit("[bold green]Thank you for using Docker Application Launcher[/bold green]"))

if __name__ == "__main__":
    orchestrator = ContainerOrchestrator()
    orchestrator.start() 