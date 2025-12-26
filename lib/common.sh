#!/bin/bash

################################################################################
# lib/common.sh - Shared Helper Functions and Constants
# Author: R4yL
# Description: Common utilities used across dotfiles installation scripts
#
# This file should be sourced, not executed directly.
# Usage: source "$SCRIPT_DIR/lib/common.sh"
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"
CIRCLE="${YELLOW}⊙${NC}"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${CHECK} $1"
}

print_error() {
    echo -e "${CROSS} $1"
}

print_info() {
    echo -e "${INFO} $1"
}

print_warn() {
    echo -e "${WARN} $1"
}

print_skip() {
    echo -e "${CIRCLE} $1"
}

run_cmd() {
    if [ "$VERBOSE" = true ]; then
        "$@"
    else
        "$@" &> /dev/null
    fi
}

backup_file() {
    local file="$1"
    local move_instead_of_copy="${2:-false}"  # Optional: true to move instead of copy
    local backup_dir="$HOME/.dotfiles-backups"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Get the base name without path (remove .config/ prefix if present)
    local basename
    basename=$(basename "$file")
    # Special handling for .config subdirectories
    if [[ "$file" == *".config/"* ]]; then
        basename="${file##*/.config/}"
    fi
    local backup_path="$backup_dir/${basename}.${timestamp}"

    # Backup the file or directory
    if [ "$move_instead_of_copy" = "true" ]; then
        mv "$file" "$backup_path"
    else
        if [ -d "$file" ]; then
            cp -r "$file" "$backup_path"
        else
            cp "$file" "$backup_path"
        fi
    fi

    echo "$backup_path"
}
