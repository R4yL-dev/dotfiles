#!/bin/bash

################################################################################
# Git Configuration Generator
# Author: R4yL
# Description: Interactive setup for git configuration
################################################################################

set -e

################################################################################
# Source Shared Libraries
################################################################################

# Source all libraries using centralized initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/init.sh"

################################################################################
# Parse Command Line Arguments
################################################################################

parse_all_common_args "$0" "$@"

################################################################################
# Main Setup
################################################################################

setup_git_config() {
    print_header "Git Configuration"

    TEMPLATE_FILE="$SCRIPT_DIR/templates/gitconfig"
    TARGET_FILE="$SCRIPT_DIR/git/.gitconfig"

    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi

    # Check if git config already exists and read current values
    local current_name=""
    local current_email=""

    if [ -f "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
        # Read current values BEFORE any modification
        current_name=$(git config --global user.name 2>/dev/null || echo "")
        current_email=$(git config --global user.email 2>/dev/null || echo "")

        # Only ask if not called with --skip-confirmation
        if [ "$SKIP_CONFIRMATION" = false ]; then
            if [ -L "$HOME/.gitconfig" ]; then
                echo -e "${YELLOW}Git is already configured via dotfiles${NC}"
            else
                echo -e "${YELLOW}A .gitconfig file already exists${NC}"
            fi
            read -p "Do you want to reconfigure? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
                print_info "Git configuration cancelled"
                exit 2
            fi
        fi

        # Backup existing config if it's a regular file
        if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
            local backup
            backup=$(backup_file "$HOME/.gitconfig")
            print_success "Backup created: $backup"
        fi

        # Remove the file/symlink
        rm "$HOME/.gitconfig"
    fi

    # Ask for user information
    local git_name=""
    local git_email=""

    # Unattended mode: use environment variables
    if [ "$UNATTENDED" = true ]; then
        # Use environment variables with fallback pattern
        git_name="$GIT_NAME"
        git_email=$(get_email_with_fallback "GIT_EMAIL")

        # Validate name is not empty
        if [[ -z "$git_name" ]]; then
            print_error "GIT_NAME environment variable is required in unattended mode"
            exit 1
        fi

        # Validate email format
        validate_email_or_exit "$git_email" "git email (environment variable)"

        print_info "Using environment variables:"
        print_info "  Name: $git_name"
        print_info "  Email: $git_email"

    # Interactive mode: ask user (use environment variables as defaults if provided)
    else
        echo
        print_info "Enter your Git information"
        echo

        # Determine default name: environment variable > current git config > none
        local default_name="${GIT_NAME:-${current_name}}"

        # Ask for name with validation
        git_name=$(prompt_with_validation "Full name (e.g. John Doe)" "$default_name" "" "name")

        # Determine default email: environment variables > current git config > none
        local default_email
        default_email=$(get_email_with_fallback "GIT_EMAIL")
        default_email="${default_email:-${current_email}}"

        # Ask for email with validation
        git_email=$(prompt_with_validation "Email (e.g. john@example.com)" "$default_email" "validate_email" "git email")
    fi

    # Generate gitconfig from template
    print_info "Generating configuration..."

    sed -e "s/__GIT_USER_NAME__/$git_name/" \
        -e "s/__GIT_USER_EMAIL__/$git_email/" \
        "$TEMPLATE_FILE" > "$TARGET_FILE"

    # Deploy with stow
    print_info "Deploying with stow..."

    # Remove existing file/symlink if any
    rm -f "$HOME/.gitconfig"

    cd "$SCRIPT_DIR"
    if run_cmd stow -t "$HOME" git; then
        print_success "Git configuration deployed"
        print_info "  ~/.gitconfig → $TARGET_FILE"
        echo
        print_success "Configuration complete!"
        echo
        print_info "User: $git_name"
        print_info "Email: $git_email"
        echo
        print_info "Available aliases: git st, git co, git br, git ci, git lg"
        exit 0
    else
        print_error "Deployment failed"
        exit 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    # Only clear screen if no flags were passed (preserve history when automated)
    if [ "$VERBOSE" = false ] && [ "$UNATTENDED" = false ] && [ "$SKIP_CONFIRMATION" = false ]; then
        clear
    fi

    echo -e "${BLUE}"
    echo "   ____ _ _    "
    echo "  / ___(_) |_  "
    echo " | |  _| | __| "
    echo " | |_| | | |_  "
    echo "  \____|_|\__| "
    echo -e "${NC}"
    echo -e "${BLUE}  Configuration Generator${NC}\n"

    setup_git_config
}

main
