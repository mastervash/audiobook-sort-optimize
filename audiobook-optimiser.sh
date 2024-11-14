#!/bin/bash

# Audiobook Organizer Script
# Directory to organize
LIBRARY_DIR="/mnt/audiobooks"
DRY_RUN=true # Set to false to actually move files after testing

# Function to log actions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to extract metadata using `mediainfo`
extract_metadata() {
    local file="$1"
    local metadata=$(mediainfo --Output=JSON "$file")
    author=$(echo "$metadata" | jq -r '.media.track[0].Performer // empty')
    title=$(echo "$metadata" | jq -r '.media.track[0].Title // empty')
    album=$(echo "$metadata" | jq -r '.media.track[0].Album // empty')
    year=$(echo "$metadata" | jq -r '.media.track[0].Recorded_Date // empty')
    narrator=$(echo "$metadata" | jq -r '.media.track[0].Comment // empty')
}

# Function to construct the target directory based on metadata
construct_directory() {
    local author="$1"
    local title="$2"
    local series="$3"
    local year="$4"
    local narrator="$5"

    author="${author:-Unknown Author}"
    title="${title:-Unknown Title}"
    series="${series:-Standalone}"
    year="${year:-Unknown Year}"
    narrator="${narrator:-Unknown Narrator}"

    if [[ "$series" == "Standalone" ]]; then
        echo "$LIBRARY_DIR/$author/$year - $title"
    else
        echo "$LIBRARY_DIR/$author/$series/Vol $year - $title {$narrator}"
    fi
}

# Function to organize a single file
organize_file() {
    local file="$1"
    extract_metadata "$file"

    # Define series if part of a series (this is inferred or can be extended later)
    local series="Standalone"
    if [[ "$album" && "$album" != "$title" ]]; then
        series="$album"
    fi

    local target_dir
    target_dir=$(construct_directory "$author" "$title" "$series" "$year" "$narrator")

    # Ensure target directory exists
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY RUN] Would create directory: $target_dir"
    else
        mkdir -p "$target_dir"
    fi

    # Determine target file path
    local filename=$(basename "$file")
    local target_file="$target_dir/$filename"

    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY RUN] Would move: $file -> $target_file"
    else
        mv -v "$file" "$target_file"
        log "Moved: $file -> $target_file"
    fi
}

# Function to scan the library for unorganized files
scan_library() {
    log "Scanning library at $LIBRARY_DIR"
    find "$LIBRARY_DIR" -type f \( -iname "*.mp3" -o -iname "*.m4b" -o -iname "*.m4a" \) | while read -r file; do
        if [[ "$file" != */Author/* && "$file" != */Series/* ]]; then
            log "Found unorganized file: $file"
            organize_file "$file"
        fi
    done
}

# Main function
main() {
    log "Starting audiobook organizer (Dry Run: $DRY_RUN)"
    scan_library
    log "Completed audiobook organization (Dry Run: $DRY_RUN)"
}

# Execute main function
main
