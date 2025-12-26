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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/args.sh"

################################################################################
# Parse Command Line Arguments
################################################################################

init_common_args
while [[ $# -gt 0 ]]; do
    if parse_common_arg "$1"; then
        shift
    else
        echo "Unknown option: $1"
        echo "Usage: $0 [-v|--verbose] [--unattended] [--skip-confirmation]"
        exit 1
    fi
done

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
            local backup=$(backup_file "$HOME/.gitconfig")
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
        git_email="${GIT_EMAIL:-${EMAIL}}"

        # Validate name is not empty
        if [[ -z "$git_name" ]]; then
            print_error "GIT_NAME environment variable is required in unattended mode"
            exit 1
        fi

        # Validate email format
        if ! validate_email "$git_email" "git email (environment variable)"; then
            exit 1
        fi

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

        # Ask for name with default value if it exists
        if [ -n "$default_name" ]; then
            read -p "Full name (default: $default_name): " git_name
            # If empty, use default value
            if [ -z "$git_name" ]; then
                git_name="$default_name"
            fi
        else
            read -p "Full name (e.g. John Doe): " git_name
            while [ -z "$git_name" ]; do
                echo -e "${RED}Name cannot be empty${NC}"
                read -p "Full name (e.g. John Doe): " git_name
            done
        fi

        # Determine default email: environment variables > current git config > none
        local default_email="${GIT_EMAIL:-${EMAIL:-${current_email}}}"

        # Ask for email with default value if it exists
        if [ -n "$default_email" ]; then
            read -p "Email (default: $default_email): " git_email
            # If empty, use default value
            if [ -z "$git_email" ]; then
                git_email="$default_email"
            else
                # Validate the new email
                while ! validate_email "$git_email" "git email" 2>/dev/null; do
                    echo -e "${RED}Invalid email format${NC}"
                    read -p "Email (default: $default_email): " git_email
                    # Allow user to press Enter to use default
                    if [ -z "$git_email" ]; then
                        git_email="$default_email"
                        break
                    fi
                done
            fi
        else
            read -p "Email (e.g. john@example.com): " git_email
            while [ -z "$git_email" ] || ! validate_email "$git_email" "git email" 2>/dev/null; do
                if [ -z "$git_email" ]; then
                    echo -e "${RED}Email cannot be empty${NC}"
                else
                    echo -e "${RED}Invalid email format${NC}"
                fi
                read -p "Email (e.g. john@example.com): " git_email
            done
        fi
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
