#!/bin/bash

################################################################################
# Dotfiles Installation Script
# Author: R4yL
# Description: Automated setup for zsh, tmux and kitty configurations
# Supports: Fedora (dnf) and Debian/Ubuntu (apt)
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"
CIRCLE="${YELLOW}⊙${NC}"

# Global variables
KITTY_INSTALLED=false

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

################################################################################
# System Detection
################################################################################

detect_package_manager() {
    print_header "System Detection"

    if command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update || true"
        print_info "Detected system: Fedora/RHEL (dnf)"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        UPDATE_CMD="sudo apt update"
        print_info "Detected system: Debian/Ubuntu (apt)"
    else
        print_error "Unsupported package manager"
        print_info "This script only supports dnf (Fedora/RHEL) and apt (Debian/Ubuntu)"
        exit 1
    fi

    print_success "Package manager: $PKG_MANAGER"
}

################################################################################
# Package Installation
################################################################################

install_packages() {
    print_header "Installing Dependencies"

    local packages=("git" "tmux" "zsh" "stow")
    local to_install=()

    # Check which packages need to be installed
    for pkg in "${packages[@]}"; do
        if command -v "$pkg" &> /dev/null; then
            print_skip "$pkg already installed"
        else
            print_info "$pkg needs to be installed"
            to_install+=("$pkg")
        fi
    done

    # Install missing packages
    if [ ${#to_install[@]} -gt 0 ]; then
        print_info "Updating package list..."
        $UPDATE_CMD

        print_info "Installing: ${to_install[*]}"
        $INSTALL_CMD "${to_install[@]}"
        print_success "Packages installed successfully"
    else
        print_success "All dependencies are already installed"
    fi
}

################################################################################
# Install Kitty (Optional Terminal Emulator)
################################################################################

install_kitty() {
    print_header "Installing Kitty (optional)"

    if command -v kitty &> /dev/null; then
        print_skip "Kitty is already installed"
        KITTY_INSTALLED=true
    else
        print_info "Kitty is not installed"
        echo
        print_info "Kitty is the recommended terminal emulator for this configuration"
        print_info "  - Integrated Dracula theme"
        print_info "  - CascadiaCode font"
        print_info "  - Zsh shell by default"
        echo
        read -p "Do you want to install Kitty? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Installing Kitty..."
            $INSTALL_CMD kitty
            KITTY_INSTALLED=true
            print_success "Kitty installed"
        else
            KITTY_INSTALLED=false
            print_info "Kitty installation skipped"
            print_warn "Default shell will be configured but some terminals may ignore it"
        fi
    fi
}

################################################################################
# Deploy Kitty Configuration
################################################################################

deploy_kitty_config() {
    if [ "$KITTY_INSTALLED" = true ]; then
        print_header "Deploying Kitty Configuration"

        # Backup existing config if any
        if [ -d "$HOME/.config/kitty" ] && [ ! -L "$HOME/.config/kitty" ]; then
            local timestamp=$(date +"%Y%m%d_%H%M%S")
            mv "$HOME/.config/kitty" "$HOME/.config/kitty.backup.$timestamp"
            print_success "Backup: ~/.config/kitty.backup.$timestamp"
        fi

        # Deploy with stow
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR"

        if stow -t "$HOME" kitty; then
            print_success "Kitty configuration deployed"
            print_info "  ~/.config/kitty/kitty.conf → $SCRIPT_DIR/kitty/.config/kitty/kitty.conf"
            print_info "  ~/.config/kitty/dracula.conf → $SCRIPT_DIR/kitty/.config/kitty/dracula.conf"
        else
            print_error "Failed to deploy Kitty configuration"
        fi
    fi
}

################################################################################
# Install CascadiaCode Font
################################################################################

install_cascadia_font() {
    if [ "$KITTY_INSTALLED" = true ]; then
        print_header "Installing CascadiaCode Font"

        # Check if CascadiaCode is already installed
        if fc-list | grep -qi "cascadia"; then
            print_skip "CascadiaCode is already installed"
        else
            print_info "Installing CascadiaCode..."

            # Install based on package manager
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $INSTALL_CMD cascadia-code-fonts
            elif [ "$PKG_MANAGER" = "apt" ]; then
                $INSTALL_CMD fonts-cascadia-code
            fi

            # Verify installation
            if fc-list | grep -qi "cascadia"; then
                print_success "CascadiaCode font installed"
            else
                print_error "Failed to install CascadiaCode"
                print_warn "Kitty will work but with the default font"
            fi
        fi
    fi
}

################################################################################
# Backup Existing Configurations
################################################################################

backup_configs() {
    print_header "Backing Up Existing Configurations"

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backed_up=0

    for config in "$HOME/.zshrc" "$HOME/.tmux.conf"; do
        if [ -f "$config" ] && [ ! -L "$config" ]; then
            local backup="${config}.backup.${timestamp}"
            cp "$config" "$backup"
            print_success "Backup created: $backup"
            backed_up=1
        elif [ -L "$config" ]; then
            local target=$(readlink -f "$config")
            if [[ "$target" == *"dotfiles"* ]] || [[ "$target" == *"init_script"* ]]; then
                print_skip "$(basename $config) is already a symlink to dotfiles"
            else
                print_warn "$(basename $config) is a symlink to: $target"
            fi
        fi
    done

    if [ $backed_up -eq 0 ]; then
        print_skip "No existing configuration to backup"
    fi
}

################################################################################
# Deploy Dotfiles with Stow
################################################################################

deploy_dotfiles() {
    print_header "Deploying Dotfiles with Stow"

    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cd "$SCRIPT_DIR"

    # Remove existing symlinks if they exist
    [ -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
    [ -L "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf"

    # Deploy with stow
    print_info "Creating symlinks..."
    if stow -t "$HOME" zsh tmux; then
        print_success "Symlinks created with Stow"
        print_info "  ~/.zshrc → $SCRIPT_DIR/zsh/.zshrc"
        print_info "  ~/.tmux.conf → $SCRIPT_DIR/tmux/.tmux.conf"

        # Verify symlinks were actually created
        if [ ! -L "$HOME/.zshrc" ] || [ ! -L "$HOME/.tmux.conf" ]; then
            print_error "Error: symlinks were not created correctly"
            exit 1
        fi
    else
        print_error "Failed to create symlinks with Stow"
        exit 1
    fi
}

################################################################################
# Install Zinit (Zsh Plugin Manager)
################################################################################

install_zinit() {
    print_header "Installing Zinit (zsh plugin manager)"

    ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    if [ -d "$ZINIT_HOME" ]; then
        print_skip "Zinit already installed"
        read -p "Do you want to update Zinit? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[OoYy]$ ]]; then
            cd "$ZINIT_HOME"
            git pull
            print_success "Zinit updated"
        fi
    else
        print_info "Cloning Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        print_success "Zinit installed"
    fi
}

################################################################################
# Install TPM (Tmux Plugin Manager)
################################################################################

install_tpm() {
    print_header "Installing TPM (tmux plugin manager)"

    TPM_HOME="${HOME}/.tmux/plugins/tpm"

    if [ -d "$TPM_HOME" ]; then
        print_skip "TPM already installed"
        read -p "Do you want to update TPM? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[OoYy]$ ]]; then
            cd "$TPM_HOME"
            git pull
            print_success "TPM updated"

            # Install/update plugins automatically
            if [ -f "$TPM_HOME/bin/install_plugins" ]; then
                print_info "Updating tmux plugins..."
                "$TPM_HOME/bin/install_plugins"
                print_success "Tmux plugins updated"
            fi
        fi
    else
        print_info "Cloning TPM..."
        mkdir -p "${HOME}/.tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"
        print_success "TPM installed"

        # Install plugins automatically
        if [ -f "$TPM_HOME/bin/install_plugins" ]; then
            print_info "Installing tmux plugins automatically..."
            "$TPM_HOME/bin/install_plugins"
            print_success "Tmux plugins installed"
        fi
    fi
}

################################################################################
# Install Plugins
################################################################################

install_plugins() {
    print_header "Plugin Installation Summary"

    # Tmux plugins already installed by TPM
    print_success "Tmux plugins have been installed automatically"

    # Zsh plugins will be installed on first shell launch
    print_info "Zsh plugins will install automatically on first zsh launch"
}

################################################################################
# Change Default Shell
################################################################################

change_default_shell() {
    print_header "Configuring Default Shell"

    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

    if [ "$CURRENT_SHELL" = "/bin/zsh" ] || [ "$CURRENT_SHELL" = "/usr/bin/zsh" ]; then
        print_skip "Zsh is already the default shell"
    else
        print_info "Current shell: $CURRENT_SHELL"
        print_info "Changing default shell to zsh..."
        if [ -x /bin/zsh ]; then
            chsh -s /bin/zsh
            print_success "Default shell changed to zsh"
        elif [ -x /usr/bin/zsh ]; then
            chsh -s /usr/bin/zsh
            print_success "Default shell changed to zsh"
        else
            print_error "Unable to find zsh binary"
            exit 1
        fi
    fi
}

################################################################################
# Setup Git Configuration (Optional)
################################################################################

setup_git_prompt() {
    print_header "Git Configuration (optional)"

    if [ -L "$HOME/.gitconfig" ]; then
        print_skip "Git configuration already deployed"
        read -p "Do you want to reconfigure Git? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            print_info "Git configuration skipped"
            return
        fi
    else
        print_info "Git is not yet configured"
        echo
        print_info "The setup-git.sh script will help you configure:"
        print_info "  - Your name and email"
        print_info "  - Basic aliases (st, co, br, ci, lg)"
        print_info "  - Color settings"
        echo
        read -p "Do you want to configure Git now? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Git configuration skipped"
            print_info "You can run ./setup-git.sh later to configure it"
            return
        fi
    fi

    # Run the git setup script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -x "$SCRIPT_DIR/setup-git.sh" ]; then
        "$SCRIPT_DIR/setup-git.sh"
    else
        print_error "setup-git.sh not found or not executable"
    fi
}

################################################################################
# Final Message
################################################################################

print_final_message() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}║      Installation completed successfully! 🎉          ║${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}📝 Next Steps:${NC}"
    echo

    # Detect if we're in Kitty
    if [ -n "$KITTY_WINDOW_ID" ]; then
        # Scenario 1: User IS in Kitty
        echo -e "${YELLOW}You are currently in Kitty:${NC}"
        echo -e "   ${INFO} Simply run ${BLUE}exec zsh${NC}"
        echo -e "           ${INFO} This will reload zsh, auto-launch tmux, and install Zsh plugins"
        echo -e "           ${CHECK} Tmux plugins are already installed!"
    elif [ "$KITTY_INSTALLED" = true ]; then
        # Scenario 2: Kitty installed but not currently used
        echo -e "${YELLOW}Recommended - Launch Kitty for the full experience:${NC}"
        echo -e "   ${INFO} Simply run ${BLUE}kitty${NC}"
        echo -e "           ${INFO} This will auto-launch zsh and tmux, install Zsh plugins automatically"
        echo -e "           ${CHECK} Tmux plugins are already installed!"
        echo
        echo -e "${YELLOW}Alternative - Continue in this terminal (without Kitty theme):${NC}"
        echo -e "   ${INFO} Close and reopen terminal OR run ${BLUE}exec zsh${NC}"
        echo -e "           ${INFO} This will auto-launch tmux and install Zsh plugins"
        echo -e "           ${CHECK} Tmux plugins are already installed!"
    else
        # Scenario 3: No Kitty
        echo -e "${YELLOW}Complete the setup:${NC}"
        echo -e "   ${INFO} Close and reopen terminal OR run ${BLUE}exec zsh${NC}"
        echo -e "           ${INFO} This will auto-launch tmux and install Zsh plugins automatically"
        echo -e "           ${CHECK} Tmux plugins are already installed!"
        echo
        echo -e "   ${WARN} Note: Some terminals may not respect the default shell setting"
    fi
    echo
    echo -e "${YELLOW}Git Synchronization (Optional):${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo -e "   ${BLUE}To update from the repository:${NC}"
    echo -e "   ${INFO} cd $SCRIPT_DIR"
    echo -e "   ${INFO} git pull"
    echo -e "   ${INFO} ./bootstrap.sh"
    echo
    echo -e "   ${BLUE}To propose modifications (if authorized):${NC}"
    echo -e "   ${INFO} Modify files in $SCRIPT_DIR"
    echo -e "   ${INFO} git add ."
    echo -e "   ${INFO} git commit -m \"Description of changes\""
    echo -e "   ${INFO} git push"
    echo

    # Show backup files if any exist
    if ls "$HOME"/.zshrc.backup.* >/dev/null 2>&1 || ls "$HOME"/.tmux.conf.backup.* >/dev/null 2>&1; then
        echo -e "${YELLOW}📂 Backup files created:${NC}"
        ls -1 "$HOME"/.zshrc.backup.* 2>/dev/null | while read file; do
            echo -e "   ${INFO} $file"
        done
        ls -1 "$HOME"/.tmux.conf.backup.* 2>/dev/null | while read file; do
            echo -e "   ${INFO} $file"
        done
        echo
    fi

    echo -e "${BLUE}✨ Configuration applied:${NC}"
    if [ "$KITTY_INSTALLED" = true ]; then
        echo -e "   ${CHECK} Kitty installed and configured (Dracula theme + CascadiaCode)"
    fi
    echo -e "   ${CHECK} Symlinks created with Stow"
    echo -e "   ${CHECK} Plugin managers installed (Zinit + TPM)"
    echo -e "   ${CHECK} Tmux plugins installed (ready to use)"
    echo -e "   ${CHECK} Zsh plugins ready to install on first launch"
    echo -e "   ${CHECK} Default shell configured to zsh"
    echo
}

################################################################################
# Main Execution
################################################################################

main() {
    clear

    echo -e "${BLUE}"
    echo "  ____        _    __ _ _            "
    echo " |  _ \  ___ | |_ / _(_) | ___  ___  "
    echo " | | | |/ _ \| __| |_| | |/ _ \/ __| "
    echo " | |_| | (_) | |_|  _| | |  __/\__ \ "
    echo " |____/ \___/ \__|_| |_|_|\___||___/ "
    echo -e "${NC}"
    echo -e "${BLUE}  Automated Installation - Zsh & Tmux${NC}\n"

    detect_package_manager
    install_packages
    install_kitty
    backup_configs
    deploy_dotfiles
    deploy_kitty_config
    install_cascadia_font
    install_zinit
    install_tpm
    install_plugins
    change_default_shell
    setup_git_prompt
    print_final_message
}

# Run main function
main
