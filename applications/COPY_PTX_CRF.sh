#!/bin/bash

# Define the exclusion patterns for destination subfolder names
# If a destination subfolder's name (in the parent directory) contains any of these
# patterns within its first 10 characters, items will not be copied to it.
exclusion_patterns=("PE" "BA" "RS" "RN" "PB" "POA" "AL" "xx" "XX" )

# Arrays to track folders for summary
copied_folders=()
skipped_folders=()

# Ask the user for the working directory path, where they can drag the folder to the terminal
echo -n "ARRASTE A PASTA QUE CONTEM O TEMPLATE DE SAO PAULO: "
read -r WORK_DIR_RAW

# Process the path to handle escaped spaces correctly
# Remove any backslashes in the path (macOS adds these when dragging folders with spaces)
WORK_DIR=$(echo "$WORK_DIR_RAW" | sed 's/\\//g')

# Remove trailing slash if present (for consistent path handling)
WORK_DIR="${WORK_DIR%/}"

# Verify the path exists and is a directory
if [ ! -d "$WORK_DIR" ]; then
    echo "Erro: O caminho fornecido não é uma pasta válida: '$WORK_DIR'"
    echo "Caminho original: '$WORK_DIR_RAW'"
    exit 1
fi

echo "Script starting. Working directory: $WORK_DIR"
echo "Destination subfolders will be sought in the parent directory: $(dirname "$WORK_DIR")"
echo "-------------------------------------------------"

processed_any_item=false # Flag to track if any action is taken
WORK_DIR_BASENAME=$(basename "$WORK_DIR") # Get the name of the working directory

# --- 1. Process .ptx files in the working directory (WORK_DIR) ---
echo "Phase 1: Looking for .ptx files in '$WORK_DIR'..."
ptx_files_found_count=0

# Use find for safe handling of filenames and to ensure they are files in the WORK_DIR
while IFS= read -r -d $'\0' ptx_filepath; do
    if [ -z "$ptx_filepath" ]; then continue; fi # Skip if empty

    ptx_files_found_count=$((ptx_files_found_count + 1))
    ptx_filename=$(basename "$ptx_filepath") # e.g., mySession.ptx

    echo ""
    echo "Found .ptx file: '$ptx_filename' (in $WORK_DIR)"
    echo "Attempting to copy '$ptx_filename' to relevant subfolders in parent directory ('$(dirname "$WORK_DIR")')..."

    all_destination_subfolders_in_parent=()
    # Find directories directly under the parent directory
    # -maxdepth 1: only look at items directly in parent dir
    # -mindepth 1: don't include parent dir itself
    while IFS= read -r -d $'\0' dir_in_parent; do
        if [ -z "$dir_in_parent" ]; then continue; fi
        all_destination_subfolders_in_parent+=("$dir_in_parent")
    done < <(find "$(dirname "$WORK_DIR")" -maxdepth 1 -mindepth 1 -type d -print0)

    if [ ${#all_destination_subfolders_in_parent[@]} -eq 0 ]; then
        echo "  No destination subfolders found in the parent directory ('$(dirname "$WORK_DIR")') for '$ptx_filename'."
    else
        copied_this_ptx_to_any=false
        for dest_candidate_path_in_parent in "${all_destination_subfolders_in_parent[@]}"; do
            # dest_candidate_path_in_parent will be like /path/to/parent/folderA
            dest_candidate_basename=$(basename "$dest_candidate_path_in_parent") # e.g., folderA

            # CRITICAL CHECK: Do not copy into the WORK_DIR itself if it's listed as a subdir of parent
            if [ "$dest_candidate_basename" == "$WORK_DIR_BASENAME" ]; then
                echo "  Skipping copy of '$ptx_filename' to '$dest_candidate_path_in_parent' (this is the working directory)."
                
                # If not already in skipped_folders array, add it with reason "working directory"
                if [[ ! " ${skipped_folders[*]} " =~ " ${dest_candidate_path_in_parent}:working directory " ]]; then
                    skipped_folders+=("${dest_candidate_path_in_parent}:working directory")
                fi
                
                continue
            fi

            first_10_chars_dest_name="${dest_candidate_basename:0:10}"
            should_exclude=false

            for pattern in "${exclusion_patterns[@]}"; do
                if [[ "$first_10_chars_dest_name" == *"$pattern"* ]]; then
                    should_exclude=true
                    echo "  Skipping copy of '$ptx_filename' to '$dest_candidate_path_in_parent' (destination name '$dest_candidate_basename' contains '$pattern' in first 10 chars: '$first_10_chars_dest_name')"
                    
                    # If not already in skipped_folders array, add it with reason "contains $pattern"
                    if [[ ! " ${skipped_folders[*]} " =~ " ${dest_candidate_path_in_parent}:contains ${pattern} " ]]; then
                        skipped_folders+=("${dest_candidate_path_in_parent}:contains ${pattern}")
                    fi
                    
                    break
                fi
            done

            if [[ "$should_exclude" == "false" ]]; then
                # Construct the final destination path for the .ptx file
                # e.g., /path/to/parent/folderA/folderA.ptx
                destination_ptx_path="${dest_candidate_path_in_parent}/${dest_candidate_basename}.ptx"
                
                # Source is the .ptx file in the WORK_DIR
                source_ptx_path="${WORK_DIR}/${ptx_filename}"

                cp "$source_ptx_path" "$destination_ptx_path" && {
                    echo "  Successfully copied '$ptx_filename' to '$destination_ptx_path'"
                    copied_this_ptx_to_any=true
                    processed_any_item=true
                    
                    # If not already in copied_folders array, add it
                    if [[ ! " ${copied_folders[*]} " =~ " ${dest_candidate_path_in_parent} " ]]; then
                        copied_folders+=("$dest_candidate_path_in_parent")
                    fi
                    
                } || {
                    echo "  ERROR: Failed to copy '$ptx_filename' to '$destination_ptx_path'"
                }
            fi
        done
        if [[ "$copied_this_ptx_to_any" == "false" ]]; then
            echo "  No suitable subfolders found in parent directory for copying '$ptx_filename' based on exclusion criteria (and avoiding self-copy)."
        fi
    fi
done < <(find "$WORK_DIR" -maxdepth 1 -type f -name "*.ptx" -print0) # Find .ptx files in WORK_DIR

if [ "$ptx_files_found_count" -eq 0 ]; then
    echo "No .ptx files found in the working directory ('$WORK_DIR')."
fi
echo "-------------------------------------------------"

# --- 2. Process "Audio Files" folder if it exists in the working directory (WORK_DIR) ---
echo "Phase 2: Looking for 'Audio Files' folder in '$WORK_DIR'..."
audio_folder_name="Audio Files"
source_audio_folder_path="${WORK_DIR}/${audio_folder_name}" # Path relative to WORK_DIR

if [ -d "$source_audio_folder_path" ]; then
    echo ""
    echo "Found folder: '$audio_folder_name' (in $WORK_DIR)"
    echo "Attempting to copy folder '$audio_folder_name' to relevant subfolders in parent directory ('$(dirname "$WORK_DIR")')..."

    all_destination_subfolders_in_parent=()
    while IFS= read -r -d $'\0' dir_in_parent; do
        if [ -z "$dir_in_parent" ]; then continue; fi
        all_destination_subfolders_in_parent+=("$dir_in_parent")
    done < <(find "$(dirname "$WORK_DIR")" -maxdepth 1 -mindepth 1 -type d -print0)

    if [ ${#all_destination_subfolders_in_parent[@]} -eq 0 ]; then
        echo "  No destination subfolders found in the parent directory ('$(dirname "$WORK_DIR")') for '$audio_folder_name'."
    else
        copied_audio_folder_to_any=false

        for dest_candidate_path_in_parent in "${all_destination_subfolders_in_parent[@]}"; do
            dest_candidate_basename=$(basename "$dest_candidate_path_in_parent")

            # CRITICAL CHECK: Do not copy into the WORK_DIR itself
            if [ "$dest_candidate_basename" == "$WORK_DIR_BASENAME" ]; then
                echo "  Skipping copy of '$audio_folder_name' to '$dest_candidate_path_in_parent' (this is the working directory)."
                
                # If not already in skipped_folders array, add it with reason "working directory"
                if [[ ! " ${skipped_folders[*]} " =~ " ${dest_candidate_path_in_parent}:working directory " ]]; then
                    skipped_folders+=("${dest_candidate_path_in_parent}:working directory")
                fi
                
                continue
            fi

            first_10_chars_dest_name="${dest_candidate_basename:0:10}"
            should_exclude=false

            for pattern in "${exclusion_patterns[@]}"; do
                if [[ "$first_10_chars_dest_name" == *"$pattern"* ]]; then
                    should_exclude=true
                    echo "  Skipping copy of '$audio_folder_name' to '$dest_candidate_path_in_parent' (destination name '$dest_candidate_basename' contains '$pattern' in first 10 chars: '$first_10_chars_dest_name')"
                    
                    # If not already in skipped_folders array, add it with reason "contains $pattern"
                    if [[ ! " ${skipped_folders[*]} " =~ " ${dest_candidate_path_in_parent}:contains ${pattern} " ]]; then
                        skipped_folders+=("${dest_candidate_path_in_parent}:contains ${pattern}")
                    fi
                    
                    break
                fi
            done

            if [[ "$should_exclude" == "false" ]]; then
                # The destination for cp -r is the parent directory of where "Audio Files" will land
                # e.g., if dest_candidate_path_in_parent is /path/to/parent/folderA,
                # cp -r "/path/to/work_dir/Audio Files" /path/to/parent/folderA/
                # This will create /path/to/parent/folderA/Audio Files/
                destination_for_audio_folder_parent="${dest_candidate_path_in_parent}/"

                cp -r "$source_audio_folder_path" "$destination_for_audio_folder_parent" && {
                    echo "  Successfully copied folder '$audio_folder_name' to '$destination_for_audio_folder_parent'"
                    copied_audio_folder_to_any=true
                    processed_any_item=true
                    
                    # If not already in copied_folders array, add it
                    if [[ ! " ${copied_folders[*]} " =~ " ${dest_candidate_path_in_parent} " ]]; then
                        copied_folders+=("$dest_candidate_path_in_parent")
                    fi
                    
                } || {
                    echo "  ERROR: Failed to copy folder '$audio_folder_name' to '$destination_for_audio_folder_parent'"
                }
            fi
        done
        if [[ "$copied_audio_folder_to_any" == "false" ]]; then
            echo "  No suitable subfolders found in parent directory for copying '$audio_folder_name' based on exclusion criteria (and avoiding self-copy)."
        fi
    fi
else
    echo "'$audio_folder_name' folder not found in the working directory ('$WORK_DIR')."
fi
echo "-------------------------------------------------"

# --- Detailed Summary ---
echo ""
echo "DETAILED SUMMARY:"

echo ""
echo "FOLDERS THAT WERE SKIPPED:"
if [ ${#skipped_folders[@]} -eq 0 ]; then
    echo "  No folders were skipped."
else
    # Sort the skipped folders list to make output consistent
    IFS=$'\n' sorted_skipped=($(sort <<<"${skipped_folders[*]}"))
    unset IFS
    
    for skipped_folder_entry in "${sorted_skipped[@]}"; do
        # Extract folder path and reason from the entry (format: "path:reason")
        folder_path="${skipped_folder_entry%%:*}"
        reason="${skipped_folder_entry#*:}"
        folder_name=$(basename "$folder_path")
        
        echo "  - $folder_name (Reason: $reason)"
    done
fi

echo ""
echo "SUMMARY OF RESULTS:"
copied_count=${#copied_folders[@]}
skipped_count=${#skipped_folders[@]}

echo "  Folders that received files: $copied_count"
if [ $copied_count -gt 0 ]; then
    # Sort the copied folders list to make output consistent
    IFS=$'\n' sorted_copied=($(sort <<<"${copied_folders[*]}"))
    unset IFS
    
    for copied_folder in "${sorted_copied[@]}"; do
        folder_name=$(basename "$copied_folder")
        echo "  - $folder_name"
    done
fi

echo ""
echo "  Folders that were skipped: $skipped_count"
if [ $skipped_count -gt 0 ]; then
    # We use the sorted array from before to list just the folder names
    for skipped_folder_entry in "${sorted_skipped[@]}"; do
        folder_path="${skipped_folder_entry%%:*}"
        folder_name=$(basename "$folder_path")
        echo "  - $folder_name"
    done
fi

echo ""
if [[ "$processed_any_item" == "false" ]]; then
    echo "Final Result: No .ptx files were processed and/or the 'Audio Files' folder was not found or not processed into any subdirectories in the parent folder."
else
    echo "Final Result: Script has finished processing items. Successfully copied to $copied_count folders and skipped $skipped_count folders."
fi

echo "Script complete."
