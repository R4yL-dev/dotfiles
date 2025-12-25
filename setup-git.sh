#!/bin/bash

################################################################################
# Git Configuration Generator
# Author: R4yL
# Description: Interactive setup for git configuration
################################################################################

set -e

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

################################################################################
# Main Setup
################################################################################

setup_git_config() {
    print_header "Configuration Git"

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TEMPLATE_FILE="$SCRIPT_DIR/git/.gitconfig"

    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi

    # Check if git config already exists
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
        echo -e "${YELLOW}Un fichier .gitconfig existe déjà${NC}"
        read -p "Voulez-vous le remplacer ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            print_info "Configuration Git annulée"
            exit 0
        fi
        # Backup existing config
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$timestamp"
        print_success "Backup créé: ~/.gitconfig.backup.$timestamp"
    fi

    # Ask for user information
    echo
    print_info "Entrez vos informations Git"
    echo

    read -p "Nom complet (ex: John Doe): " git_name
    while [ -z "$git_name" ]; do
        echo -e "${RED}Le nom ne peut pas être vide${NC}"
        read -p "Nom complet (ex: John Doe): " git_name
    done

    read -p "Email (ex: john@example.com): " git_email
    while [ -z "$git_email" ]; do
        echo -e "${RED}L'email ne peut pas être vide${NC}"
        read -p "Email (ex: john@example.com): " git_email
    done

    # Generate gitconfig from template
    print_info "Génération de la configuration..."

    sed -e "s/__GIT_USER_NAME__/$git_name/" \
        -e "s/__GIT_USER_EMAIL__/$git_email/" \
        "$TEMPLATE_FILE" > "$SCRIPT_DIR/git/.gitconfig.generated"

    # Deploy with stow
    print_info "Déploiement avec stow..."

    # Remove existing symlink if any
    [ -L "$HOME/.gitconfig" ] && rm "$HOME/.gitconfig"

    # Replace template with generated file temporarily
    mv "$TEMPLATE_FILE" "$TEMPLATE_FILE.bak"
    mv "$SCRIPT_DIR/git/.gitconfig.generated" "$TEMPLATE_FILE"

    cd "$SCRIPT_DIR"
    if stow -t "$HOME" git; then
        print_success "Configuration Git déployée"
        print_info "  ~/.gitconfig → $SCRIPT_DIR/git/.gitconfig"
        echo
        print_success "Configuration terminée !"
        echo
        print_info "Utilisateur: $git_name"
        print_info "Email: $git_email"
        echo
        print_info "Aliases disponibles: git st, git co, git br, git ci, git lg"
    else
        print_error "Erreur lors du déploiement"
        # Restore template
        mv "$TEMPLATE_FILE.bak" "$TEMPLATE_FILE"
        exit 1
    fi

    # Restore original template
    mv "$TEMPLATE_FILE.bak" "$TEMPLATE_FILE"
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
