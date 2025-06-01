#!/bin/bash

# Unified script to manage Google Drive cache and Finder favorites
# Fixed version to avoid the mysides segmentation fault problem

# Define the expected path for sidebartool
SIDEBARTOOL_CMD="$HOME/sidebartool"

# Function to display colored messages
function show_info {
  echo -e "\033[1;34mℹ️ $1\033[0m"
}

function show_success {
  echo -e "\033[1;32m✅ $1\033[0m"
}

function show_warning {
  echo -e "\033[1;33m⚠️ $1\033[0m"
}

function show_error {
  echo -e "\033[1;31m❌ $1\033[0m"
}

function show_header {
  clear
  echo -e "\033[1;36m===================================================\033[0m"
  echo -e "\033[1;36m  Google Drive and Finder Favorites Manager  \033[0m"
  echo -e "\033[1;36m===================================================\033[0m"
  echo ""
}

# Function to run commands with administrator privile   es
run_with_admin_privileges() {
  local cmd_to_run="$1"
  show_info "Requesting administrator privileges for: $cmd_to_run"
  osascript -e "do shell script \"$cmd_to_run\" with administrator privileges"
  local osascript_exit_code=$?
  if [ $osascript_exit_code -ne 0 ]; then
    show_error "Command failed with exit code $osascript_exit_code. Administrator privileges may not have been granted or the command itself failed."
  fi
  return $osascript_exit_code
}

# Check if sidebartool is installed
check_sidebartool() {
  # Check both command in PATH and the hardcoded path
  if ! command -v sidebartool &> /dev/null && [ ! -x "$SIDEBARTOOL_CMD" ]; then
    show_warning "The 'sidebartool' is not found in PATH and not at $SIDEBARTOOL_CMD."
    show_info "This tool is necessary to manage Finder favorites."
    show_info "Installation requires a C compiler (usually part of Xcode Command Line Tools)."
    show_info "Steps:"
    show_info "1. Ensure a C compiler is installed (e.g., via Xcode Command Line Tools: xcode-select --install)"
    show_info "2. Clone the repository: git clone https://github.com/andrewzirkel/sidebartool.git ~/sidebartool_src"
    show_info "3. Build and install: cd ~/sidebartool_src && make clean && make && sudo make install"
    show_info "   (The 'sudo make install' will use the script's admin privilege escalation)"
    show_info "4. Clean up: cd ~ && rm -rf ~/sidebartool_src"

    read -p "Do you want to attempt installation now? (Requires compiler and sudo for install) (y/n): " INSTALL
    if [[ "$INSTALL" == "y" || "$INSTALL" == "Y" ]]; then
      show_info "Attempting to install sidebartool using make..."
      # Check for make, though it's usually present if build tools are.
      if ! command -v make &> /dev/null; then
          show_error "'make' command not found. Please install build tools (e.g., Xcode Command Line Tools)."
          return 1
      fi

      show_info "Cloning sidebartool repository..."
      git clone https://github.com/andrewzirkel/sidebartool.git ~/sidebartool_src
      if [ $? -ne 0 ]; then
        show_error "Failed to clone sidebartool repository.";
        return 1
      fi

      show_info "Changing to sidebartool source directory: ~/sidebartool_src"
      cd ~/sidebartool_src
      if [ $? -ne 0 ]; then
        show_error "Failed to change directory to ~/sidebartool_src.";
        # Attempt to cd back to home and clean up if clone happened
        cd ~
        rm -rf ~/sidebartool_src
        return 1
      fi

      show_info "Running 'make clean'..."
      make clean
      if [ $? -ne 0 ]; then
        show_warning "sidebartool 'make clean' failed or not necessary. Proceeding with make..."
        # Not returning error here as 'make clean' might fail if nothing to clean
      fi

      show_info "Running 'make'..."
      make
      if [ $? -ne 0 ]; then
        show_error "sidebartool 'make' failed. Please check output.";
        cd ~ # Go back to home directory
        # rm -rf ~/sidebartool_src # Optionally leave for inspection
        return 1
      fi

      show_info "Running 'make install' with administrator privileges..."
      # run_with_admin_privileges will handle its own error messages for osascript part
      # The command string for osascript needs to be self-contained if it involves cd
      run_with_admin_privileges "cd ~/sidebartool_src && make install"
      MAKE_INSTALL_EXIT_CODE=$? # Get exit code from run_with_admin_privileges
      
      # Regardless of make install outcome, change back to home directory
      show_info "Changing back to home directory..."
      cd ~
      if [ $? -ne 0 ]; then show_warning "Failed to cd back to home directory, but continuing..."; fi

      if [ $MAKE_INSTALL_EXIT_CODE -ne 0 ]; then
          show_error "sidebartool 'make install' failed (exit code $MAKE_INSTALL_EXIT_CODE). Please check output.";
          # rm -rf ~/sidebartool_src # Optionally leave for inspection
          return 1
      fi
      
      # After successful installation attempt, check specifically for the hardcoded path
      if [ ! -x "$SIDEBARTOOL_CMD" ]; then
        show_error "$SIDEBARTOOL_CMD still not found or not executable after installation attempt. Please check manually."
        # rm -rf ~/sidebartool_src # Clean up source even if final check fails but install seemed to succeed
        return 1
      else
        show_success "sidebartool installed successfully! (Found at $SIDEBARTOOL_CMD)"
        show_info "Cleaning up source directory ~/sidebartool_src..."
        rm -rf ~/sidebartool_src
      fi
    else
      show_error "Installation skipped. Please install sidebartool manually to $SIDEBARTOOL_CMD to use the favorites management features."
      return 1
    fi
  # If sidebartool was found in PATH initially, or if it's at the hardcoded path
  elif ! command -v sidebartool &> /dev/null && [ -x "$SIDEBARTOOL_CMD" ]; then
     show_info "sidebartool found at $SIDEBARTOOL_CMD (not in PATH)."
  elif command -v sidebartool &> /dev/null; then
     show_info "sidebartool found in PATH. Will prefer $SIDEBARTOOL_CMD if available or after install."
     # If it's in path but not where we expect it after install, this logic is covered by the install block.
     # If it's already at SIDEBARTOOL_CMD and in path, that's fine.
  fi

  # Final check to ensure we can use it via SIDEBARTOOL_CMD
  if [ ! -x "$SIDEBARTOOL_CMD" ]; then
      show_warning "'sidebartool' is not available at the expected path: $SIDEBARTOOL_CMD."
      show_info "If you installed it elsewhere, please update SIDEBARTOOL_CMD in the script."
      # Check if it's in PATH as a last resort, though the script will try to use SIDEBARTOOL_CMD
      if command -v sidebartool &> /dev/null; then
          show_warning "A 'sidebartool' was found in PATH, but this script is configured to use $SIDEBARTOOL_CMD."
          show_info "Attempting to use the version in PATH for now, but this might not be the intended one."
          SIDEBARTOOL_CMD="sidebartool" # Fallback to PATH version
      else
          show_error "sidebartool is not available via PATH or at $SIDEBARTOOL_CMD. Cannot proceed with sidebar operations."
          return 1
      fi
  fi
  return 0
}

# Alias the check function for places where it was called check_mysides
alias check_mysides=check_sidebartool # SIDEBARTOOL_CMD will be used internally by the functions now

# Create necessary directories
create_directories() {
  BACKUP_DIR=~/Desktop/Google_Drive_Manager
  mkdir -p "$BACKUP_DIR/Backups"
  mkdir -p "$BACKUP_DIR/Shortcuts"
  show_success "Directories created: $BACKUP_DIR"
  return 0
}

# Function to backup favorites using mysides list output directly
backup_favorites() {
  show_info "Backing up important favorites..."
  
  # Create directory for backups
  create_directories
  
  BACKUP_FILE="$BACKUP_DIR/Backups/finder_favorites_$(date +%Y%m%d_%H%M%S).txt"
  
  # Create backup file
  echo "# Finder Favorites (generated on $(date))" > "$BACKUP_FILE"
  
  show_info "Getting favorites directly from the Finder sidebar..."
  
  # Use sidebartool list to get existing favorite names
  TEMP_SIDEBARTOOL_OUTPUT=$(mktemp)
  show_info "DEBUG: Created temporary file for sidebartool output: $TEMP_SIDEBARTOOL_OUTPUT"
  
  show_info "DEBUG: Attempting to run '$SIDEBARTOOL_CMD list'..."
  "$SIDEBARTOOL_CMD" list > "$TEMP_SIDEBARTOOL_OUTPUT" 2>/dev/null
  SIDEBARTOOL_EXIT_CODE=$?
  show_info "DEBUG: '$SIDEBARTOOL_CMD list' command finished with exit code: $SIDEBARTOOL_EXIT_CODE"
  
  if [ $SIDEBARTOOL_EXIT_CODE -ne 0 ]; then
    show_warning "$SIDEBARTOOL_CMD command failed with exit code $SIDEBARTOOL_EXIT_CODE."
    if [ -s "$TEMP_SIDEBARTOOL_OUTPUT" ]; then
        show_info "DEBUG: Contents of temp file (even on error):"
        cat "$TEMP_SIDEBARTOOL_OUTPUT"
    else
        show_info "DEBUG: Temp file is empty on error."
    fi
    rm -f "$TEMP_SIDEBARTOOL_OUTPUT"
    TEMP_SIDEBARTOOL_OUTPUT=""
  fi
  
  # Check if we were able to get the favorites list
  show_info "DEBUG: Checking if temp file exists and is not empty..."
  if [ -n "$TEMP_SIDEBARTOOL_OUTPUT" ] && [ -s "$TEMP_SIDEBARTOOL_OUTPUT" ]; then
    show_success "DEBUG: sidebartool list succeeded. Processing output..."
    show_info "DEBUG: Contents of temp file (list of names):"
    cat "$TEMP_SIDEBARTOOL_OUTPUT"
    
    # Write names to backup file (used for removal during restore)
    cp "$TEMP_SIDEBARTOOL_OUTPUT" "$BACKUP_FILE"
    show_success "Favorite names backed up for removal reference."
    
    # Clean up
    show_info "DEBUG: Removing temp file: $TEMP_SIDEBARTOOL_OUTPUT"
    [ -f "$TEMP_SIDEBARTOOL_OUTPUT" ] && rm -f "$TEMP_SIDEBARTOOL_OUTPUT"
  else
    show_warning "Could not get favorites list using $SIDEBARTOOL_CMD list (either failed or produced no output)."
    show_info "DEBUG: Proceeding with fallback method for path backup."
    [ -f "$TEMP_SIDEBARTOOL_OUTPUT" ] && rm -f "$TEMP_SIDEBARTOOL_OUTPUT" # Ensure cleanup
    
    # Fallback method: Use defined folders to create a backup with paths
    show_info "Using alternative method to identify important favorites..."
    
    # Find the Google Drive directory
    GOOGLE_DRIVE_DIR=""
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -n "$GOOGLE_DRIVE_DIR" ]; then
      show_info "Google Drive directory found: $GOOGLE_DRIVE_DIR"
      
      # Simple array of folders to check
      IMPORTANT_FOLDERS=(
        "Work_Documents"
        "Project_Files"
        "Shared_Team_Folder"
        "Media_Files"
        "Important_Resources"
        "Scripts"
        "Backups"
        "Applications"
        "Development_Projects"
        "Personal_Files"
        "Monitoring_Tools"
        "Reports"
        "Client_Projects"
        "Media_Library"
      )
      
      # Helper function to register found folder
      add_folder_to_backup() {
        local name="$1"
        local path="$2"
        echo "$name file://$path" >> "$BACKUP_FILE"
        show_success "Added to backup: $name ($3)"
      }
      
      # Add basic Google Drive folders
      if [ -d "$GOOGLE_DRIVE_DIR/My Drive" ]; then
        add_folder_to_backup "My Drive" "$GOOGLE_DRIVE_DIR/My Drive" "Google Drive"
      fi
      
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        add_folder_to_backup "Shared drives" "$GOOGLE_DRIVE_DIR/Shared drives" "Google Drive"
      fi
      
      # Array to track found folders
      FOLDERS_FOUND=()
      
      # Check folders in user's home directory
      for folder in "${IMPORTANT_FOLDERS[@]}"; do
        if [ -d ~/"$folder" ]; then
          add_folder_to_backup "$folder" "$HOME/$folder" "home folder"
          FOLDERS_FOUND+=("$folder")
        fi
      done
      
      # Check folders on Desktop
      for folder in "${IMPORTANT_FOLDERS[@]}"; do
        # Check if already found
        FOUND=0
        for p in "${FOLDERS_FOUND[@]}"; do
          if [ "$p" = "$folder" ]; then
            FOUND=1
            break
          fi
        done
        
        # If not found, look on the Desktop
        if [ $FOUND -eq 0 ] && [ -d ~/Desktop/"$folder" ]; then
          add_folder_to_backup "$folder" "/Users/$(whoami)/Desktop/$folder" "Desktop"
          FOLDERS_FOUND+=("$folder")
        fi
      done
      
      # Check folders in Shared Drives
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        for folder in "${IMPORTANT_FOLDERS[@]}"; do
          # Check if already found
          FOUND=0
          for p in "${FOLDERS_FOUND[@]}"; do
            if [ "$p" = "$folder" ]; then
              FOUND=1
              break
            fi
          done
          
          # If not found, look in Shared Drives
          if [ $FOUND -eq 0 ]; then
            # Search in depth in Shared Drives
            path_found=$(find "$GOOGLE_DRIVE_DIR/Shared drives" -maxdepth 5 -type d -name "$folder" -print -quit 2>/dev/null)
            if [ -n "$path_found" ]; then
              add_folder_to_backup "$folder" "$path_found" "Shared Drives"
              FOLDERS_FOUND+=("$folder")
              continue
            fi
          fi
        done
      fi
      
      # Add standard macOS folders (common)
      if [ -d ~/Desktop ]; then
        add_folder_to_backup "Desktop" "/Users/$(whoami)/Desktop" "system"
      fi
      
      if [ -d ~/Downloads ]; then
        add_folder_to_backup "Downloads" "/Users/$(whoami)/Downloads" "system"
      fi
      
      if [ -d ~/Documents ]; then
        add_folder_to_backup "Documents" "/Users/$(whoami)/Documents" "system"
      fi
      
      if [ -d /Applications ]; then
        add_folder_to_backup "Applications" "/Applications" "system"
      fi
    else
      show_error "Could not find the Google Drive directory."
    fi
  fi
  
  # Extract only the names of favorites for later use
  NAMES_FILE="$BACKUP_DIR/Backups/finder_favorites_names_$(date +%Y%m%d_%H%M%S).txt"
  # If the backup file contains paths (from fallback), extract names
  if grep -q " file://" "$BACKUP_FILE"; then
    grep -v "^#" "$BACKUP_FILE" | awk -F " file://" '{print $1}' > "$NAMES_FILE"
  else # Otherwise, assume it contains only names (from sidebartool list)
    grep -v "^#" "$BACKUP_FILE" > "$NAMES_FILE"
  fi
  
  # Check if backup was created successfully
  if [ -s "$BACKUP_FILE" ]; then
    show_success "Favorites backup created successfully!"
    echo ""
    cat "$BACKUP_FILE"
    echo ""
    show_info "The complete backup was saved to: $BACKUP_FILE"
    # Create a link to the most recent backup for easy restoration
    ln -sf "$BACKUP_FILE" "$BACKUP_DIR/Backups/latest_backup.txt"
    ln -sf "$NAMES_FILE" "$BACKUP_DIR/Backups/latest_backup_names.txt"
    show_success "Links to the latest backup created."
    
    # Debug information
    show_info "DEBUG: Verifying backup files exist:"
    ls -la "$BACKUP_DIR/Backups/latest_backup.txt" "$BACKUP_DIR/Backups/latest_backup_names.txt" 2>/dev/null || show_warning "Backup links not found!"
    ls -la "$BACKUP_FILE" "$NAMES_FILE" 2>/dev/null || show_warning "Original backup files not found!"
  else
    show_error "Could not create favorites backup or the list is empty."
  fi
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
}

# Function to clean Google Drive cache
clean_cache() {
  show_info "Preparing to clean Google Drive cache..."
  
  # Close Google Drive
  show_info "Closing Google Drive..."
  pkill -f "Google Drive"
  
  # Wait for shutdown
  COUNTER=0
  while pgrep -f "Google Drive" >/dev/null; do
    ((COUNTER++))
    echo "Still running... (attempt $COUNTER)"
    sleep 1
    if [ $COUNTER -ge 5 ]; then
      show_warning "Limit of 5 attempts reached."
      break
    fi
  done
  
  # Remove immutability attributes
  show_info "Removing immutability attributes..."
  run_with_admin_privileges "chflags -R nouchg ~/Library/CloudStorage"
  
  # Adjust permissions
  show_info "Adjusting permissions..."
  run_with_admin_privileges "chmod -R 777 ~/Library/CloudStorage"
  
  # Calculate cache folder size
  show_info "Calculating cache folder size:"
  run_with_admin_privileges "du -sh ~/Library/CloudStorage"
  
  # Remove cache folder
  show_info "Removing cache folder..."
  run_with_admin_privileges "rm -rf ~/Library/CloudStorage"
  show_success "Cache removed."
  
  # Reopen Google Drive
  show_info "Reopening Google Drive..."
  open -a "Google Drive"
  show_success "Google Drive reopened."
  
  show_info "Waiting for Google Drive to initialize (30 seconds)..."
  for i in {30..1}; do
    echo -ne "Waiting: $i seconds remaining\r"
    sleep 1
  done
  echo ""
  
  show_success "Google Drive cache cleared successfully!"
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Function to add Google Drive favorites
add_google_drive_favorites() {
  show_info "Adding Google Drive favorites..."
  
  # Check if sidebartool is installed
  check_sidebartool || return 1
  
  # Find Google Drive directory
  GOOGLE_DRIVE_DIR=""
  show_info "Looking for Google Drive directory (may take a few seconds)..."
  
  COUNTER=0
  while [ -z "$GOOGLE_DRIVE_DIR" ] && [ $COUNTER -lt 6 ]; do
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -z "$GOOGLE_DRIVE_DIR" ]; then
      ((COUNTER++))
      show_info "Waiting for Google Drive to create the directory... (attempt $COUNTER)"
      sleep 5
    fi
  done
  
  if [ -z "$GOOGLE_DRIVE_DIR" ]; then
    show_error "Could not find Google Drive directory."
    show_info "Wait a few minutes for Google Drive to sync and try again."
    return 1
  fi
  
  show_info "Google Drive directory found: $GOOGLE_DRIVE_DIR"
  
  # Create directory for shortcuts
  create_directories
  
  # List of important folders to check
  IMPORTANT_FOLDERS=(
    "Work_Documents"
    "Project_Files"
    "Shared_Team_Folder"
    "Media_Files"
    "Important_Resources"
    "Scripts"
    "Backups"
    "Applications"
    "Development_Projects"
    "Personal_Files"
    "Monitoring_Tools"
    "Reports"
    "Client_Projects"
    "Media_Library"
  )
  
  # First, remove existing duplicate or partial entries
  show_info "Removing existing duplicate or partial entries using sidebartool..."
  
  # Remove basic Google Drive entries (use actual names if known, otherwise this is speculative)
  "$SIDEBARTOOL_CMD" remove "My" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "My Drive" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "Shared" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "Shared drives" 2>/dev/null
  
  # Remove all potentially already existing important folders
  for folder in "${IMPORTANT_FOLDERS[@]}"; do
    "$SIDEBARTOOL_CMD" remove "$folder" 2>/dev/null
    echo "Removed (if existed): $folder"
  done
  
  # Also remove standard system folders if they exist
  "$SIDEBARTOOL_CMD" remove "Desktop" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "Downloads" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "Documents" 2>/dev/null
  "$SIDEBARTOOL_CMD" remove "Applications" 2>/dev/null
  
  # Wait a moment
  sleep 1
  
  # Function to add a favorite using sidebartool
  add_favorite_sidebartool() {
    local name="$1"
    local path="$2"
    
    if [ ! -d "$path" ]; then
      show_warning "Directory not found, cannot add favorite: $path"
      return 1
    fi
    
    show_info "Attempting to add favorite: '$name' -> '$path' using $SIDEBARTOOL_CMD..."
    "$SIDEBARTOOL_CMD" add "$name" "$path" # Use the direct path
    if [ $? -eq 0 ]; then
        show_success "Favorite added: $name"
        return 0
    else
        show_warning "$SIDEBARTOOL_CMD add failed for: $name. You may need to add it manually."
        return 1
    fi
  }
  
  # Recursive search to find specific folders
  find_and_add_folder() {
    local folder_name="$1"
    local base_directory="$2"
    local depth="${3:-3}"  # Default depth: 3 levels
    
    show_info "Looking for '$folder_name' in $base_directory (depth $depth)..."
    
    # Search using find with limited depth
    local path_found=$(find "$base_directory" -maxdepth "$depth" -type d -name "$folder_name" -print -quit 2>/dev/null)
    
    if [ -n "$path_found" ]; then
      show_info "Folder '$folder_name' found at: $path_found"
      add_favorite_sidebartool "$folder_name" "$path_found"
      return 0
    else
      # Don't show warning here, let the main loop handle it
      return 1
    fi
  }
  
  # Add basic Google Drive folders
  MY_DRIVE_PATH="$GOOGLE_DRIVE_DIR/My Drive"
  SHARED_DRIVES_PATH="$GOOGLE_DRIVE_DIR/Shared drives"
  
  if [ -d "$MY_DRIVE_PATH" ]; then
    add_favorite_sidebartool "My Drive" "$MY_DRIVE_PATH"
  fi
  
  if [ -d "$SHARED_DRIVES_PATH" ]; then
    add_favorite_sidebartool "Shared drives" "$SHARED_DRIVES_PATH"
  fi
  
  # Search and add important folders in various locations
  for folder in "${IMPORTANT_FOLDERS[@]}"; do
    show_info "Looking for folder: $folder..."
    FOUND=0
    
    # 1. Check in home folder root
    if [ -d ~/"$folder" ]; then
      add_favorite_sidebartool "$folder" ~/"$folder"
      FOUND=1
      continue
    fi
    
    # 2. Check in My Drive 
    if [ -d "$MY_DRIVE_PATH" ] && [ $FOUND -eq 0 ]; then
      find_and_add_folder "$folder" "$MY_DRIVE_PATH" 2
      if [ $? -eq 0 ]; then
        FOUND=1
        continue
      fi
    fi
    
    # 3. Search in Shared Drives with greater depth
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $FOUND -eq 0 ]; then
      # Deeper search in Shared Drives
      find_and_add_folder "$folder" "$SHARED_DRIVES_PATH" 3
      if [ $? -eq 0 ]; then
        FOUND=1
        continue
      fi
    fi
    
    # 4. Check directly in known Shared Drives (adjust if needed)
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $FOUND -eq 0 ]; then
      for drive in "$SHARED_DRIVES_PATH"/*; do
        if [ -d "$drive/$folder" ]; then
          add_favorite_sidebartool "$folder" "$drive/$folder"
          FOUND=1
          break
        # Remove specific subfolder checks unless necessary
        # elif [ -d "$drive/PUBLICIDADE/$folder" ]; then
        #   add_favorite_sidebartool "$folder" "$drive/PUBLICIDADE/$folder"
        #   FOUND=1
        #   break
        fi
      done
    fi
    
    if [ $FOUND -eq 0 ]; then
      show_warning "Folder '$folder' not found automatically."
    fi
  done
  
  # Add standard system folders
  add_favorite_sidebartool "Desktop" "$HOME/Desktop"
  add_favorite_sidebartool "Downloads" "$HOME/Downloads"
  add_favorite_sidebartool "Documents" "$HOME/Documents"
  add_favorite_sidebartool "Applications" "/Applications"
  
  show_success "Google Drive favorites added successfully!"
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Function to restore all favorites from a backup
restore_all_favorites() {
  show_info "Restoring all Finder sidebar favorites..."
  
  # Check if sidebartool is installed
  check_sidebartool || return 1
  
  # Check if the latest backup exists
  LATEST_BACKUP="$BACKUP_DIR/Backups/latest_backup.txt"
  LATEST_BACKUP_NAMES="$BACKUP_DIR/Backups/latest_backup_names.txt"
  
  # Debug information
  show_info "DEBUG: Looking for backup files:"
  show_info "Latest backup path: $LATEST_BACKUP"
  ls -la "$BACKUP_DIR/Backups/" 2>/dev/null || show_warning "Backup directory not found or empty!"
  
  if [ ! -f "$LATEST_BACKUP" ]; then
    # List all available backups
    show_info "Latest backup not found. Checking other backups..."
    BACKUPS=$(find "$BACKUP_DIR/Backups" -name "finder_favorites_*.txt" -type f 2>/dev/null)
    
    if [ -z "$BACKUPS" ]; then
      show_error "No backups found. Make a backup first."
      
      # Ask if user wants to return to menu
      echo ""
      read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
      if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
        return 0
      fi
      return 1
    fi
    
    show_info "Available backups:"
    echo "$BACKUPS"
    echo ""
    read -p "Enter the full path of the backup file to restore (or 'menu' to return to menu): " RESTORE_FILE
    
    if [[ "$RESTORE_FILE" == "menu" ]]; then
      return 0
    fi
    
    if [ ! -f "$RESTORE_FILE" ]; then
      show_error "File not found: $RESTORE_FILE"
      
      # Ask if user wants to return to menu
      echo ""
      read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
      if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
        return 0
      fi
      return 1
    fi
    
    # Generate names file from selected backup
    TEMP_NAMES_FILE="$BACKUP_DIR/Backups/temp_names.txt"
    grep -v "^#" "$RESTORE_FILE" | awk -F " file:" '{print $1}' > "$TEMP_NAMES_FILE"
  else
    show_info "Using the latest backup: $LATEST_BACKUP"
    RESTORE_FILE="$LATEST_BACKUP"
    TEMP_NAMES_FILE="$LATEST_BACKUP_NAMES"
    
    # Generate names file again to ensure it's correct
    grep -v "^#" "$RESTORE_FILE" | awk -F " file:" '{print $1}' > "$TEMP_NAMES_FILE"
  fi
  
  # Confirm restoration
  show_warning "WARNING: This will remove existing favorites and restore those from the backup."
  show_info "Favorites that will be restored:"
  grep -v "^#" "$RESTORE_FILE"
  echo ""
  read -p "Confirm restoration? (y/n, or 'menu' to return to menu): " CONFIRM_RESTORE
  
  if [[ "$CONFIRM_RESTORE" == "menu" ]]; then
    return 0
  fi
  
  if [[ "$CONFIRM_RESTORE" == "y" || "$CONFIRM_RESTORE" == "Y" ]]; then
    # Remove existing favorites (only those listed in the names file)
    show_info "Removing existing favorites listed in the backup names file..."
    while read -r name; do
      if [ -n "$name" ]; then
        show_info "Attempting to remove: $name"
        "$SIDEBARTOOL_CMD" remove "$name" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Removed: $name"
        else
            show_warning "Failed to remove (or didn't exist): $name"
        fi
      fi
    done < "$TEMP_NAMES_FILE"
    
    # Wait a moment
    sleep 1
    
    # Add favorites from backup
    show_info "Restoring favorites from backup file: $RESTORE_FILE..."
    
    # Check if the backup file contains paths (from fallback method)
    if grep -q " file://" "$RESTORE_FILE"; then
      show_info "DEBUG: Backup file contains paths. Restoring using name and path."
      # Use grep to avoid comment lines and correctly process names with spaces
      grep -v "^#" "$RESTORE_FILE" | while read -r line; do
        if [ -n "$line" ]; then
          # Extract name and path URL
          name=$(echo "$line" | awk -F " file://" '{print $1}')
          path_url=$(echo "$line" | awk -F " file://" '{print $2}')
          
          # Decode URL to get the filesystem path
          decoded_path=$(echo "$path_url" | 
            perl -pe 's/%20/ /g; s/%([0-9A-F]{2})/chr(hex($1))/gie' 2>/dev/null ||
            echo "$path_url" | sed 's/%20/ /g')
          
          # Check if path exists using decoded path
          if [ -d "$decoded_path" ]; then
            show_info "Adding: $name -> $decoded_path"
            "$SIDEBARTOOL_CMD" add "$name" "$decoded_path" 2>/dev/null
            if [ $? -ne 0 ]; then
                show_warning "$SIDEBARTOOL_CMD add failed for: $name"
            else
                echo "Added: $name -> $decoded_path"
            fi
          else
            show_warning "Path not found for $name: $decoded_path. Cannot add."
          fi
        fi
      done
    else
        show_warning "Backup file ($RESTORE_FILE) does not contain paths."
        show_info "This might happen if the backup was created using '$SIDEBARTOOL_CMD list' which only stores names."
        show_info "Cannot automatically restore paths. You may need to re-add favorites manually or use the 'Add only Google Drive favorites' option."
    fi
    
    show_success "Favorites restoration process completed!"
    
    # Ask if user wants to return to menu
    echo ""
    read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
    if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
      return 0
    fi
    return 0
  else
    show_info "Restoration cancelled by user."
    return 1
  fi
}

# Function to forcefully kill Google Drive processes
force_kill_google_drive() {
  show_warning "Attempting to forcefully kill all Google Drive processes..."
  show_warning "This may cause unsynced files or other issues. Use with caution!"
  
  # Try pkill -9 first
  run_with_admin_privileges "pkill -9 -f 'Google Drive'"
  sleep 1 # Give it a moment
  
  # Check if still running and try killall -9
  if pgrep -f "Google Drive" >/dev/null; then
      show_warning "pkill -9 might not have terminated all processes. Trying killall -9..."
      # Note the quoting for the command string within osascript
      run_with_admin_privileges "killall -9 'Google Drive' 2>/dev/null"
      sleep 1
  fi
  
  # Final check
  if pgrep -f "Google Drive" >/dev/null; then
    show_error "Failed to forcefully kill all Google Drive processes. Manual intervention might be required."
  else
    show_success "Google Drive processes forcefully terminated."
  fi
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
}

# Function to perform the complete process (backup, cleanup and restoration)
complete_process() {
  show_info "Starting the complete process (backup, cleanup and restoration)..."
  
  # Check if sidebartool is installed
  check_sidebartool || return 1
  
  # 1. Backup favorites
  show_info "Step 1: Backing up favorites..."
  backup_favorites
  
  # 2. Confirm continuation
  echo ""
  show_warning "WARNING: The next step will clear Google Drive cache."
  read -p "Do you want to continue with cache cleanup? (y/n): " CONTINUE_CLEANUP
  
  if [[ "$CONTINUE_CLEANUP" != "y" && "$CONTINUE_CLEANUP" != "Y" ]]; then
    show_info "Process interrupted by user after backup."
    return 0
  fi
  
  # 3. Clean cache
  show_info "Step 2: Cleaning Google Drive cache..."
  clean_cache
  
  # 4. Add Google Drive favorites
  show_info "Step 3: Restoring Google Drive favorites..."
  add_google_drive_favorites
  
  show_success "Complete process finished successfully!"
  show_info "If you want to restore all favorites (not just Google Drive ones), use option 4 in the main menu."
  
  # Ask if user wants to return to menu
  echo ""
  read -p "Return to main menu? (y/n, default: y): " RETURN_TO_MENU
  if [[ "$RETURN_TO_MENU" != "n" && "$RETURN_TO_MENU" != "N" ]]; then
    return 0
  fi
  return 0
}

# Main menu
display_menu() {
  show_header
  echo "Choose an option:"
  echo ""
  echo "1. Complete process (backup, cleanup and Google Drive restoration)"
  echo "2. Backup Finder favorites"
  echo "3. Clean Google Drive cache"
  echo "4. Restore all favorites from backup"
  echo "5. Add only Google Drive favorites"
  echo "6. Forcefully kill Google Drive processes"
  echo "7. Exit"
  echo ""
  read -p "Enter your choice (1-7): " OPTION
  
  case $OPTION in
    1)
      complete_process
      ;;
    2)
      backup_favorites
      ;;
    3)
      clean_cache
      ;;
    4)
      restore_all_favorites
      ;;
    5)
      add_google_drive_favorites
      ;;
    6)
      force_kill_google_drive
      ;;
    7)
      show_info "Exiting..."
      exit 0
      ;;
    *)
      show_error "Invalid option!"
      ;;
  esac
  
  echo ""
  read -p "Press Enter to return to the main menu..."
  display_menu
}

# Start the program
display_menu 
