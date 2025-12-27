#!/bin/bash

################################################################################
# lib/init.sh - Library Initialization
# Author: R4yL
# Description: Centralized initialization for all shared libraries
#
# This file should be sourced, not executed directly.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/init.sh"
################################################################################

# Initialize all shared libraries
# This function sources all required library files with error handling
init_libs() {
    # Determine script directory (works when called from any script)
    # If SCRIPT_DIR is already set, use it; otherwise, derive from caller
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
        export SCRIPT_DIR
    fi

    # Determine lib directory - handle both /dotfiles and /dotfiles/lib as SCRIPT_DIR
    local lib_dir
    if [[ "$SCRIPT_DIR" == */lib ]]; then
        # Already in lib directory (e.g., when testing)
        lib_dir="$SCRIPT_DIR"
    else
        # In main dotfiles directory
        lib_dir="$SCRIPT_DIR/lib"
    fi

    local libs=("common" "validation" "args")

    # Source each library with error handling
    for lib in "${libs[@]}"; do
        local lib_path="$lib_dir/${lib}.sh"
        if [ ! -f "$lib_path" ]; then
            echo "Error: Library file not found: $lib_path"
            echo "Make sure you're running from the dotfiles directory"
            exit 1
        fi

        if ! source "$lib_path" 2>/dev/null; then
            echo "Error: Failed to load ${lib} library"
            echo "Library path: $lib_path"
            exit 1
        fi
    done
}

# Auto-initialize when sourced
init_libs
