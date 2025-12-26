#!/bin/bash

################################################################################
# lib/validation.sh - Input Validation Functions
# Author: R4yL
# Description: Validation utilities for user input
#
# This file should be sourced, not executed directly.
# Usage: source "$SCRIPT_DIR/lib/validation.sh"
################################################################################

################################################################################
# Email Validation
################################################################################

validate_email() {
    local email="$1"
    local param_name="$2"

    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Error: Invalid email format for $param_name: $email"
        echo "Email must be in format: user@domain.com"
        return 1
    fi
    return 0
}
