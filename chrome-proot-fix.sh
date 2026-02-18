#!/bin/bash

# Chrome/Chromium Proot Fix Script for Andronix/XFCE Ubuntu 22.04
# This script modifies .desktop files to add --no-sandbox flag for Chrome/Chromium
# browsers to work properly in proot environments on Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup a file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    print_info "Backed up: $backup"
}

# Function to fix a desktop file
fix_desktop_file() {
    local desktop_file="$1"
    local modified=0
    
    # Check if file exists and is readable
    if [ ! -f "$desktop_file" ]; then
        print_warn "File not found: $desktop_file"
        return 1
    fi
    
    if [ ! -r "$desktop_file" ]; then
        print_error "Cannot read file: $desktop_file"
        return 1
    fi
    
    # Check if file is writable
    if [ ! -w "$desktop_file" ]; then
        print_error "Cannot write to file: $desktop_file (try running with sudo)"
        return 1
    fi
    
    print_info "Processing: $desktop_file"
    
    # Create backup
    backup_file "$desktop_file"
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Process the file line by line
    while IFS= read -r line; do
        # Check if line starts with Exec= and contains chrome/chromium
        if [[ $line =~ ^Exec=.*(chrome|chromium) ]]; then
            # Check if --no-sandbox is already present
            if [[ ! $line =~ --no-sandbox ]]; then
                # Add --no-sandbox before %U, %F, or at the end
                if [[ $line =~ %[UuFf] ]]; then
                    # Replace %U, %u, %F, %f with --no-sandbox %U, etc.
                    line=$(echo "$line" | sed 's/ %\([UuFf]\)/ --no-sandbox %\1/')
                else
                    # Append --no-sandbox at the end
                    line="${line} --no-sandbox"
                fi
                modified=1
                print_info "Modified Exec line: $line"
            else
                print_info "Already has --no-sandbox: $line"
            fi
        fi
        echo "$line" >> "$temp_file"
    done < "$desktop_file"
    
    # Replace original file with modified version if changes were made
    if [ $modified -eq 1 ]; then
        mv "$temp_file" "$desktop_file"
        print_info "Successfully updated: $desktop_file"
        return 0
    else
        rm "$temp_file"
        print_info "No changes needed for: $desktop_file"
        return 0
    fi
}

# Main script
main() {
    print_info "Chrome/Chromium Proot Fix Script"
    print_info "================================="
    echo ""
    
    # Array to store desktop files
    declare -a desktop_files
    
    # Common locations for desktop files
    locations=(
        "/usr/share/applications"
        "$HOME/.local/share/applications"
    )
    
    # Search for Chrome/Chromium desktop files
    print_info "Searching for Chrome/Chromium desktop files..."
    
    for location in "${locations[@]}"; do
        if [ -d "$location" ]; then
            # Find all Chrome/Chromium related desktop files
            while IFS= read -r -d '' file; do
                desktop_files+=("$file")
            done < <(find "$location" -maxdepth 1 -type f \( -name "*chrome*.desktop" -o -name "*chromium*.desktop" \) -print0 2>/dev/null)
        fi
    done
    
    # Check if any files were found
    if [ ${#desktop_files[@]} -eq 0 ]; then
        print_warn "No Chrome/Chromium desktop files found!"
        print_info "Chrome/Chromium may not be installed, or desktop files may be in a non-standard location."
        exit 0
    fi
    
    print_info "Found ${#desktop_files[@]} desktop file(s)"
    echo ""
    
    # Process each desktop file
    local success_count=0
    local fail_count=0
    
    for file in "${desktop_files[@]}"; do
        if fix_desktop_file "$file"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
        echo ""
    done
    
    # Summary
    echo ""
    print_info "================================="
    print_info "Summary:"
    print_info "  Successfully processed: $success_count"
    if [ $fail_count -gt 0 ]; then
        print_warn "  Failed to process: $fail_count"
    fi
    echo ""
    
    if [ $success_count -gt 0 ]; then
        print_info "Chrome/Chromium should now work in proot environment!"
        print_info "You may need to restart your desktop session for changes to take effect."
    fi
    
    # Check for mimeapps.list and suggest update-desktop-database
    if command -v update-desktop-database &> /dev/null; then
        print_info "Updating desktop database..."
        for location in "${locations[@]}"; do
            if [ -d "$location" ] && [ -w "$location" ]; then
                update-desktop-database "$location" 2>/dev/null || true
            fi
        done
    fi
}

# Run main function
main

exit 0
