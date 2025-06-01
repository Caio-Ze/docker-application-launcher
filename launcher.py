#!/usr/bin/env python3
"""
Dynamic Bounce Monitor - Docker Application Launcher
Main launcher script with menu interface for all applications
"""

import os
import sys
import subprocess
import time
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.prompt import Prompt, Confirm
from rich.text import Text
from rich import print as rprint
import threading
import signal

console = Console()

class ApplicationLauncher:
    def __init__(self):
        self.apps_dir = Path("/app/applications")
        self.data_dir = Path("/app/data")
        self.output_dir = Path("/app/output")
        self.temp_dir = Path("/app/temp")
        
        # Ensure directories exist
        for dir_path in [self.data_dir, self.output_dir, self.temp_dir]:
            dir_path.mkdir(exist_ok=True)
        
        # Available applications
        self.applications = {
            "1": {
                "name": "Voice Cleaner API v1",
                "description": "Clean audio files using ElevenLabs and Auphonic APIs",
                "script": "voice_cleaner_API1.py",
                "category": "Audio Processing"
            },
            "2": {
                "name": "Voice Cleaner API v2", 
                "description": "Advanced voice cleaning with enhanced features",
                "script": "voice_cleaner_API2.py",
                "category": "Audio Processing"
            },
            "3": {
                "name": "WAV/MP3 Converter",
                "description": "Convert between WAV and MP3 formats with quality options",
                "script": "WAVMP3_FIX.py",
                "category": "Audio Processing"
            },
            "4": {
                "name": "Audio Enhancer (Network)",
                "description": "Apply volume boost, compression and loudness normalization",
                "script": "EXTRA_PARA_NET_SPACE_FIX.py",
                "category": "Audio Processing"
            },
            "5": {
                "name": "YouTube Downloader",
                "description": "Download audio/video from YouTube with ffmpeg processing",
                "script": "youtube_downloader_PYFFMPEG.py",
                "category": "Content Acquisition"
            },
            "6": {
                "name": "Video Optimizer",
                "description": "Optimize videos for 480p with H.264 encoding",
                "script": "optimize_videos_PYFFMPEG.py",
                "category": "Video Processing"
            },
            "7": {
                "name": "Google Drive Manager",
                "description": "Manage Google Drive cache and Finder favorites",
                "script": "google_drive_manager_fixed.sh",
                "category": "Cloud Storage"
            },
            "8": {
                "name": "PTX Template Copier",
                "description": "Copy .ptx files and Audio Files to São Paulo template folders",
                "script": "COPY_PTX_CRF.sh",
                "category": "File Management"
            },
            "9": {
                "name": "PTX Template Copier (No AM)",
                "description": "Copy .ptx files excluding AM folders (AM pattern added)",
                "script": "COPY_PTX_CRF**SEM_AM.sh",
                "category": "File Management"
            },
            "10": {
                "name": "Folder Structure Creator",
                "description": "Create folder structures from clipboard content with LOC subfolders",
                "script": "PASTAS_CRF.py",
                "category": "File Management"
            }
        }
        
        self.running_processes = {}
        
    def show_header(self):
        """Display the application header"""
        header_text = Text("🎵 Dynamic Bounce Monitor", style="bold blue")
        subtitle_text = Text("Docker Application Launcher", style="italic cyan")
        
        panel = Panel.fit(
            f"{header_text}\n{subtitle_text}\n\nVersion 1.0 | Ready to Process Audio & Video",
            border_style="blue",
            padding=(1, 2)
        )
        console.print(panel)
        console.print()

    def show_menu(self):
        """Display the main menu"""
        table = Table(title="📋 Available Applications", show_header=True, header_style="bold magenta")
        table.add_column("ID", style="cyan", width=4)
        table.add_column("Application", style="green", width=25)
        table.add_column("Category", style="yellow", width=20)
        table.add_column("Description", style="white", width=40)
        
        # Group applications by category
        categories = {}
        for app_id, app_info in self.applications.items():
            category = app_info["category"]
            if category not in categories:
                categories[category] = []
            categories[category].append((app_id, app_info))
        
        # Add applications to table grouped by category
        for category, apps in categories.items():
            for i, (app_id, app_info) in enumerate(apps):
                table.add_row(
                    app_id,
                    app_info["name"],
                    category if i == 0 else "",  # Only show category for first item
                    app_info["description"]
                )
            if category != list(categories.keys())[-1]:  # Add separator except for last category
                table.add_row("", "", "", "", style="dim")
        
        console.print(table)
        console.print()
        
        # Additional options
        options_table = Table(show_header=False, box=None)
        options_table.add_column("Option", style="cyan")
        options_table.add_column("Description", style="white")
        
        options_table.add_row("📊 status", "Show running processes")
        options_table.add_row("🛑 stop", "Stop running processes")
        options_table.add_row("🔧 shell", "Open interactive shell")
        options_table.add_row("📁 files", "Browse files")
        options_table.add_row("❌ exit", "Exit launcher")
        
        console.print(Panel(options_table, title="🛠️ System Options", border_style="yellow"))
        console.print()

    def run_application(self, app_id):
        """Run the selected application"""
        if app_id not in self.applications:
            console.print(f"❌ Invalid application ID: {app_id}", style="red")
            return
        
        app_info = self.applications[app_id]
        script_path = self.apps_dir / app_info["script"]
        
        if not script_path.exists():
            console.print(f"❌ Script not found: {script_path}", style="red")
            return
        
        console.print(f"🚀 Starting: {app_info['name']}", style="green")
        console.print(f"📝 Description: {app_info['description']}", style="cyan")
        console.print()
        
        try:
            # Determine how to run the script
            if script_path.suffix == ".py":
                cmd = [sys.executable, str(script_path)]
            elif script_path.suffix == ".sh":
                cmd = ["bash", str(script_path)]
            else:
                console.print(f"❌ Unsupported script type: {script_path.suffix}", style="red")
                return
            
            # Set up environment
            env = os.environ.copy()
            env["PYTHONPATH"] = str(self.apps_dir)
            env["DATA_DIR"] = str(self.data_dir)
            env["OUTPUT_DIR"] = str(self.output_dir)
            env["TEMP_DIR"] = str(self.temp_dir)
            
            # Run the application
            process = subprocess.Popen(
                cmd,
                cwd=str(self.apps_dir),
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            self.running_processes[app_id] = {
                "process": process,
                "name": app_info["name"],
                "start_time": time.time()
            }
            
            # Stream output in real-time
            for line in iter(process.stdout.readline, ''):
                if line:
                    console.print(line.rstrip())
            
            process.wait()
            
            # Clean up
            if app_id in self.running_processes:
                del self.running_processes[app_id]
            
            if process.returncode == 0:
                console.print(f"✅ {app_info['name']} completed successfully!", style="green")
            else:
                console.print(f"❌ {app_info['name']} exited with code {process.returncode}", style="red")
                
        except KeyboardInterrupt:
            console.print("\n⚠️ Process interrupted by user", style="yellow")
            if app_id in self.running_processes:
                self.running_processes[app_id]["process"].terminate()
                del self.running_processes[app_id]
        except Exception as e:
            console.print(f"❌ Error running application: {e}", style="red")
        
        console.print("\nPress Enter to continue...")
        input()

    def show_status(self):
        """Show running processes"""
        if not self.running_processes:
            console.print("ℹ️ No applications currently running", style="cyan")
            return
        
        status_table = Table(title="🔄 Running Processes", show_header=True, header_style="bold green")
        status_table.add_column("ID", style="cyan")
        status_table.add_column("Application", style="green")
        status_table.add_column("Runtime", style="yellow")
        status_table.add_column("Status", style="white")
        
        for app_id, proc_info in self.running_processes.items():
            runtime = time.time() - proc_info["start_time"]
            runtime_str = f"{int(runtime//60)}m {int(runtime%60)}s"
            
            if proc_info["process"].poll() is None:
                status = "🟢 Running"
            else:
                status = "🔴 Finished"
            
            status_table.add_row(app_id, proc_info["name"], runtime_str, status)
        
        console.print(status_table)

    def stop_processes(self):
        """Stop running processes"""
        if not self.running_processes:
            console.print("ℹ️ No processes to stop", style="cyan")
            return
        
        self.show_status()
        console.print()
        
        choice = Prompt.ask("Enter process ID to stop (or 'all' for all processes)")
        
        if choice.lower() == "all":
            if Confirm.ask("Are you sure you want to stop all processes?"):
                for app_id, proc_info in list(self.running_processes.items()):
                    proc_info["process"].terminate()
                    console.print(f"🛑 Stopped: {proc_info['name']}", style="yellow")
                self.running_processes.clear()
        elif choice in self.running_processes:
            proc_info = self.running_processes[choice]
            proc_info["process"].terminate()
            console.print(f"🛑 Stopped: {proc_info['name']}", style="yellow")
            del self.running_processes[choice]
        else:
            console.print("❌ Invalid process ID", style="red")

    def open_shell(self):
        """Open an interactive shell"""
        console.print("🐚 Opening interactive shell...", style="cyan")
        console.print("Type 'exit' to return to the launcher", style="yellow")
        console.print()
        
        try:
            subprocess.run(["/bin/bash"], cwd=str(self.apps_dir))
        except KeyboardInterrupt:
            pass
        
        console.print("\n🔙 Returning to launcher...", style="cyan")

    def browse_files(self):
        """Browse files and directories"""
        dirs_to_show = {
            "📁 Applications": self.apps_dir,
            "💾 Data": self.data_dir,
            "📤 Output": self.output_dir,
            "🗂️ Temp": self.temp_dir,
            "🏠 Home": Path("/host/Users") if Path("/host/Users").exists() else Path("/app")
        }
        
        file_table = Table(title="📂 Directory Browser", show_header=True, header_style="bold blue")
        file_table.add_column("Location", style="cyan")
        file_table.add_column("Path", style="green")
        file_table.add_column("Files", style="yellow")
        
        for name, path in dirs_to_show.items():
            if path.exists():
                try:
                    file_count = len(list(path.iterdir()))
                    file_table.add_row(name, str(path), str(file_count))
                except PermissionError:
                    file_table.add_row(name, str(path), "Access Denied")
            else:
                file_table.add_row(name, str(path), "Not Found")
        
        console.print(file_table)
        console.print()
        
        choice = Prompt.ask("Enter directory name to explore (or press Enter to continue)")
        if choice:
            for name, path in dirs_to_show.items():
                if choice.lower() in name.lower() and path.exists():
                    try:
                        subprocess.run(["ls", "-la", str(path)])
                    except Exception as e:
                        console.print(f"❌ Error listing directory: {e}", style="red")
                    break

    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        console.print("\n🛑 Shutting down launcher...", style="yellow")
        
        # Stop all running processes
        for proc_info in self.running_processes.values():
            try:
                proc_info["process"].terminate()
            except:
                pass
        
        console.print("👋 Goodbye!", style="green")
        sys.exit(0)

    def run(self):
        """Main application loop"""
        # Set up signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        while True:
            try:
                console.clear()
                self.show_header()
                self.show_menu()
                
                choice = Prompt.ask("Select an option", default="exit").strip().lower()
                
                if choice in self.applications:
                    self.run_application(choice)
                elif choice == "status":
                    self.show_status()
                    input("\nPress Enter to continue...")
                elif choice == "stop":
                    self.stop_processes()
                    input("\nPress Enter to continue...")
                elif choice == "shell":
                    self.open_shell()
                elif choice == "files":
                    self.browse_files()
                    input("\nPress Enter to continue...")
                elif choice in ["exit", "quit", "q"]:
                    if Confirm.ask("Are you sure you want to exit?"):
                        break
                else:
                    console.print(f"❌ Invalid option: {choice}", style="red")
                    time.sleep(1)
                    
            except KeyboardInterrupt:
                if Confirm.ask("\nAre you sure you want to exit?"):
                    break
            except Exception as e:
                console.print(f"❌ Unexpected error: {e}", style="red")
                time.sleep(2)
        
        self.signal_handler(None, None)

if __name__ == "__main__":
    launcher = ApplicationLauncher()
    launcher.run() 