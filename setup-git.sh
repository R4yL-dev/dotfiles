#!/bin/bash

################################################################################
# Git Configuration Generator
# Author: R4yL
# Description: Interactive setup for git configuration
################################################################################

set -e

# Parse command line arguments
UNATTENDED=false
SKIP_CONFIRMATION=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --unattended)
            UNATTENDED=true
            shift
            ;;
        --skip-confirmation)
            SKIP_CONFIRMATION=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--unattended] [--skip-confirmation]"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"

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

backup_file() {
    local file="$1"
    local backup_dir="$HOME/.dotfiles-backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Get the base name without path
    local basename=$(basename "$file")
    local backup_path="$backup_dir/${basename}.${timestamp}"

    # Backup the file
    cp "$file" "$backup_path"

    echo "$backup_path"
}

################################################################################
# Main Setup
################################################################################

setup_git_config() {
    print_header "Configuration Git"

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_FILE="$SCRIPT_DIR/templates/gitconfig"
    TARGET_FILE="$SCRIPT_DIR/git/.gitconfig"

    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi

    # Check if git config already exists and read current values
    local config_exists=false
    local current_name=""
    local current_email=""

    if [ -f "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
        config_exists=true

        # Read current values BEFORE any modification
        current_name=$(git config --global user.name 2>/dev/null || echo "")
        current_email=$(git config --global user.email 2>/dev/null || echo "")

        # Only ask if not called with --skip-confirmation
        if [ "$SKIP_CONFIRMATION" = false ]; then
            if [ -L "$HOME/.gitconfig" ]; then
                echo -e "${YELLOW}Git est déjà configuré via dotfiles${NC}"
            else
                echo -e "${YELLOW}Un fichier .gitconfig existe déjà${NC}"
            fi
            read -p "Voulez-vous reconfigurer ? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
                print_info "Configuration Git annulée"
                exit 2
            fi
        fi

        # Backup existing config if it's a regular file
        if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
            local backup=$(backup_file "$HOME/.gitconfig")
            print_success "Backup créé: $backup"
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
        if [[ ! "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_error "Invalid email format in environment variable: $git_email"
            exit 1
        fi

        print_info "Using environment variables:"
        print_info "  Name: $git_name"
        print_info "  Email: $git_email"

    # Interactive mode: ask user (use environment variables as defaults if provided)
    else
        echo
        print_info "Entrez vos informations Git"
        echo

        # Determine default name: environment variable > current git config > none
        local default_name="${GIT_NAME:-${current_name}}"

        # Ask for name with default value if it exists
        if [ -n "$default_name" ]; then
            read -p "Nom complet (default: $default_name): " git_name
            # If empty, use default value
            if [ -z "$git_name" ]; then
                git_name="$default_name"
            fi
        else
            read -p "Nom complet (ex: John Doe): " git_name
            while [ -z "$git_name" ]; do
                echo -e "${RED}Le nom ne peut pas être vide${NC}"
                read -p "Nom complet (ex: John Doe): " git_name
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
                while [[ ! "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
                    echo -e "${RED}Format d'email invalide${NC}"
                    read -p "Email (default: $default_email): " git_email
                    # Allow user to press Enter to use default
                    if [ -z "$git_email" ]; then
                        git_email="$default_email"
                        break
                    fi
                done
            fi
        else
            read -p "Email (ex: john@example.com): " git_email
            while [ -z "$git_email" ] || [[ ! "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
                if [ -z "$git_email" ]; then
                    echo -e "${RED}L'email ne peut pas être vide${NC}"
                else
                    echo -e "${RED}Format d'email invalide${NC}"
                fi
                read -p "Email (ex: john@example.com): " git_email
            done
        fi
    fi

    # Generate gitconfig from template
    print_info "Génération de la configuration..."

    sed -e "s/__GIT_USER_NAME__/$git_name/" \
        -e "s/__GIT_USER_EMAIL__/$git_email/" \
        "$TEMPLATE_FILE" > "$TARGET_FILE"

    # Deploy with stow
    print_info "Déploiement avec stow..."

    # Remove existing file/symlink if any
    rm -f "$HOME/.gitconfig"

    cd "$SCRIPT_DIR"
    if stow -t "$HOME" git; then
        print_success "Configuration Git déployée"
        print_info "  ~/.gitconfig → $TARGET_FILE"
        echo
        print_success "Configuration terminée !"
        echo
        print_info "Utilisateur: $git_name"
        print_info "Email: $git_email"
        echo
        print_info "Aliases disponibles: git st, git co, git br, git ci, git lg"
        exit 0
    else
        print_error "Erreur lors du déploiement"
        exit 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    clear

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
