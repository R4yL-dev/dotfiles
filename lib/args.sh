#!/bin/bash

################################################################################
# lib/args.sh - Common Argument Parsing Utilities
# Author: R4yL
# Description: Shared argument parsing helpers
#
# This file should be sourced, not executed directly.
# Usage: source "$SCRIPT_DIR/lib/args.sh"
################################################################################

################################################################################
# Argument Parsing Functions
################################################################################

# Initialize common argument variables
init_common_args() {
    export VERBOSE=false
    export UNATTENDED=false
    export SKIP_CONFIRMATION=false
}

# Parse a single common argument
# Returns 0 if handled, 1 if unknown (caller should handle)
parse_common_arg() {
    case "$1" in
        -v|--verbose)
            export VERBOSE=true
            return 0
            ;;
        --unattended)
            export UNATTENDED=true
            return 0
            ;;
        --skip-confirmation)
            export SKIP_CONFIRMATION=true
            return 0
            ;;
        *)
            return 1  # Unknown argument, caller should handle
            ;;
    esac
}

# Validate that an argument has a value
# Usage: require_arg_value "--git-name" "$2"
require_arg_value() {
    local arg_name="$1"
    local value="$2"

    if [[ -z "$value" ]] || [[ "$value" == -* ]]; then
        echo "Error: $arg_name requires a value"
        exit 1
    fi
}

# Parse all common arguments for a script
# Usage: parse_all_common_args "$0" "$@"
parse_all_common_args() {
    local script_name="$1"
    shift

    init_common_args

    while [[ $# -gt 0 ]]; do
        if parse_common_arg "$1"; then
            shift
        else
            echo "Unknown option: $1"
            echo "Usage: $script_name [-v|--verbose] [--unattended] [--skip-confirmation]"
            exit 1
        fi
    done
}
