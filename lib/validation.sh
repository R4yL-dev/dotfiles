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

# Validate email format
# Usage: validate_email "user@example.com" "git email"
# Returns: 0 if valid, 1 if invalid
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

# Validate email format and exit on failure
# Usage: validate_email_or_exit "user@example.com" "git email"
validate_email_or_exit() {
    local email="$1"
    local param_name="$2"

    if ! validate_email "$email" "$param_name"; then
        exit 1
    fi
}

################################################################################
# Email Fallback Helpers
################################################################################

# Get email with fallback to global EMAIL variable
# Usage: final_email=$(get_email_with_fallback "GIT_EMAIL")
# Returns: Value of specific variable, or EMAIL if specific is unset
get_email_with_fallback() {
    local specific_var="$1"  # Name of specific variable (e.g., "GIT_EMAIL" or "SSH_EMAIL")
    local specific_value="${!specific_var}"  # Indirect expansion to get value

    echo "${specific_value:-${EMAIL}}"
}
