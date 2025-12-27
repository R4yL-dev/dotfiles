#!/bin/bash

################################################################################
# lib/common.sh - Shared Helper Functions and Constants
# Author: R4yL
# Description: Common utilities used across dotfiles installation scripts
#
# This file should be sourced, not executed directly.
# Usage: source "$SCRIPT_DIR/lib/common.sh"
################################################################################

# Colors for output (readonly to prevent accidental modification)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Symbols (readonly to prevent accidental modification)
readonly CHECK="${GREEN}✓${NC}"
readonly CROSS="${RED}✗${NC}"
readonly INFO="${BLUE}ℹ${NC}"
readonly WARN="${YELLOW}⚠${NC}"
readonly CIRCLE="${YELLOW}⊙${NC}"

# Exit codes (readonly constants)
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CANCELLED=2

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

# Execute command with output control based on VERBOSE flag
# Usage: run_cmd command arg1 arg2 ...
# If VERBOSE=true, shows command output; otherwise suppresses it
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

# Execute a script with automatic verbose flag handling
# Usage: run_script "setup-git.sh" --skip-confirmation --unattended
# Returns: The exit code of the executed script
run_script() {
    local script="$1"
    shift
    local args=("$@")

    local script_path="$SCRIPT_DIR/$script"

    if [ ! -x "$script_path" ]; then
        print_error "$script not found or not executable"
        return "$EXIT_ERROR"
    fi

    # Automatically add -v flag if VERBOSE is enabled
    if [ "$VERBOSE" = true ]; then
        "$script_path" "${args[@]}" -v
    else
        "$script_path" "${args[@]}"
    fi

    return $?
}

# Prompt user for input with an optional default value
# Usage: result=$(prompt_with_default "Enter name" "John Doe")
# Returns: User input or default value if input is empty
prompt_with_default() {
    local prompt_text="$1"
    local default_value="$2"
    local result

    if [ -n "$default_value" ]; then
        read -r -p "$prompt_text (default: $default_value): " result
        echo "${result:-$default_value}"
    else
        read -r -p "$prompt_text: " result
        echo "$result"
    fi
}

# Prompt user for input with validation loop
# Usage: result=$(prompt_with_validation "Enter email" "default@example.com" validate_email "email")
# Parameters:
#   $1: Prompt text
#   $2: Default value (optional, can be empty)
#   $3: Validation function name (must accept value and param_name)
#   $4: Parameter name for validation error messages
prompt_with_validation() {
    local prompt_text="$1"
    local default_value="$2"
    local validation_func="$3"
    local param_name="$4"
    local result

    while true; do
        if [ -n "$default_value" ]; then
            read -r -p "$prompt_text (default: $default_value): " result
            # If empty, use default value
            if [ -z "$result" ]; then
                result="$default_value"
                echo "$result"
                return 0
            fi
        else
            read -r -p "$prompt_text: " result
        fi

        # Check if empty (when no default)
        if [ -z "$result" ] && [ -z "$default_value" ]; then
            echo -e "${RED}${param_name^} cannot be empty${NC}" >&2
            continue
        fi

        # Run validation if provided
        if [ -n "$validation_func" ]; then
            if $validation_func "$result" "$param_name" 2>/dev/null; then
                echo "$result"
                return 0
            else
                echo -e "${RED}Invalid ${param_name}${NC}" >&2
                continue
            fi
        else
            echo "$result"
            return 0
        fi
    done
}
