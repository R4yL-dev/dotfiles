#!/bin/bash

################################################################################
# SSH Key Generation Script
# Author: R4yL
# Description: Interactive setup for SSH key generation
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

setup_ssh_key() {
    print_header "SSH Key Generation"

    # Check if SSH keys already exist
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        # Only ask if not called with --skip-confirmation
        if [ "$SKIP_CONFIRMATION" = false ]; then
            echo -e "${YELLOW}SSH key already exists${NC}"

            # Display the existing public key
            if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
                echo
                print_info "Your current public SSH key (ed25519):"
                echo
                cat "$HOME/.ssh/id_ed25519.pub"
                echo
            elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
                echo
                print_info "Your current public SSH key (RSA):"
                echo
                cat "$HOME/.ssh/id_rsa.pub"
                echo
            fi

            read -p "Do you want to generate a new SSH key? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
                print_info "SSH key generation cancelled"
                exit 2
            fi
        fi
    fi

    # Get email for the key
    local ssh_email=""
    local passphrase=""

    # Unattended mode: use environment variables
    if [ "$UNATTENDED" = true ]; then
        # Use environment variables with fallback pattern
        ssh_email="${SSH_EMAIL:-${EMAIL}}"
        passphrase=""  # No passphrase in unattended mode

        # Validate email format
        if ! validate_email "$ssh_email" "SSH email (environment variable)"; then
            exit 1
        fi

        print_info "Using environment variables:"
        print_info "  Email: $ssh_email"
        print_info "  Passphrase: None (unattended mode)"

    # Interactive mode: ask user (use environment variables as defaults if provided)
    else
        # Determine default email: environment variables > git config > none
        local git_config_email=""
        if [ -f "$HOME/.gitconfig" ]; then
            git_config_email=$(git config --global user.email 2>/dev/null || echo "")
        fi
        local default_email="${SSH_EMAIL:-${EMAIL:-${git_config_email}}}"

        if [ -n "$default_email" ]; then
            echo
            read -p "Email for SSH key (default: $default_email): " input_email
            if [ -n "$input_email" ]; then
                ssh_email="$input_email"
            else
                ssh_email="$default_email"
            fi
        else
            echo
            read -p "Email for SSH key: " ssh_email
        fi

        # Validate email
        while [ -z "$ssh_email" ] || ! validate_email "$ssh_email" "SSH email" 2>/dev/null; do
            if [ -z "$ssh_email" ]; then
                echo -e "${RED}Email cannot be empty${NC}"
            else
                echo -e "${RED}Invalid email format${NC}"
            fi
            read -p "Email for SSH key: " ssh_email
        done

        # Ask for passphrase
        echo
        print_info "Passphrase (press Enter for no passphrase):"
        read -s -p "Enter passphrase: " passphrase
        echo
    fi

    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Backup existing key if any
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        backup_file "$HOME/.ssh/id_ed25519" true > /dev/null
        backup_file "$HOME/.ssh/id_ed25519.pub" true > /dev/null
        print_success "Existing keys backed up to ~/.dotfiles-backups/"
    fi

    # Generate SSH key (ed25519 is more modern and secure)
    print_info "Generating SSH key (ed25519)..."

    if run_cmd ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N "$passphrase"; then
        print_success "SSH key generated successfully"

        # Start ssh-agent and add key
        print_info "Adding key to ssh-agent..."
        run_cmd eval "$(ssh-agent -s)"

        if [ -n "$passphrase" ]; then
            # If passphrase was set, ssh-add will ask for it interactively
            echo
            print_info "Enter your passphrase to add the key to ssh-agent:"
            if ssh-add "$HOME/.ssh/id_ed25519"; then  # Interactive - don't wrap
                print_success "Key added to ssh-agent"
            else
                print_warn "Failed to add key to ssh-agent (you can run 'ssh-add ~/.ssh/id_ed25519' later)"
            fi
        else
            run_cmd ssh-add "$HOME/.ssh/id_ed25519"
            print_success "Key added to ssh-agent"
        fi

        # Copy public key to clipboard if xclip is available
        if command -v xclip &> /dev/null; then
            if run_cmd sh -c "cat '$HOME/.ssh/id_ed25519.pub' | xclip -selection clipboard"; then
                print_success "Public key copied to clipboard"
            fi
        fi

        echo
        print_success "SSH key setup complete!"
        echo
        print_info "Email: $ssh_email"
        if [ -n "$passphrase" ]; then
            print_info "Passphrase: Set"
        else
            print_info "Passphrase: None"
        fi

        exit 0
    else
        print_error "Failed to generate SSH key"
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
    echo "  ____ ____  _   _  "
    echo " / ___/ ___|| | | | "
    echo " \___ \___ \| |_| | "
    echo "  ___) |__) |  _  | "
    echo " |____/____/|_| |_| "
    echo -e "${NC}"
    echo -e "${BLUE}  Key Generator${NC}\n"

    setup_ssh_key
}

main
