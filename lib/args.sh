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
    VERBOSE=false
    UNATTENDED=false
    SKIP_CONFIRMATION=false
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
