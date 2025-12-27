#!/bin/bash

################################################################################
# Dotfiles Installation Script
# Author: R4yL
# Description: Automated setup for zsh, tmux and kitty configurations
# Supports: Fedora (dnf) and Debian/Ubuntu (apt)
################################################################################

set -e  # Exit on error

################################################################################
# Source Shared Libraries
################################################################################

# Source all libraries using centralized initialization
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/init.sh"

################################################################################
# Parse Command Line Arguments
################################################################################

VERBOSE=false
UNATTENDED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -y|--yes)
            UNATTENDED=true
            shift
            ;;
        --git-name)
            require_arg_value "--git-name" "$2"
            # Check if value is only whitespace
            if [[ "$2" =~ ^[[:space:]]*$ ]]; then
                echo "Error: --git-name cannot be only whitespace"
                exit 1
            fi
            export GIT_NAME="$2"
            shift 2
            ;;
        --git-email)
            require_arg_value "--git-email" "$2"
            validate_email_or_exit "$2" "--git-email"
            export GIT_EMAIL="$2"
            shift 2
            ;;
        --ssh-email)
            require_arg_value "--ssh-email" "$2"
            validate_email_or_exit "$2" "--ssh-email"
            export SSH_EMAIL="$2"
            shift 2
            ;;
        --email)
            require_arg_value "--email" "$2"
            validate_email_or_exit "$2" "--email"
            export EMAIL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--verbose] [-y|--yes] [--git-name \"Name\"] [--git-email \"email\"] [--ssh-email \"email\"] [--email \"email\"]"
            exit 1
            ;;
    esac
done

################################################################################
# Validate Environment Variables
################################################################################

# Validate environment variables if they were set (not from CLI args)
# This catches variables set via: GIT_NAME="test" EMAIL="test@mail" ./bootstrap.sh
if [[ -n "$GIT_NAME" ]] && [[ "$GIT_NAME" =~ ^[[:space:]]*$ ]]; then
    echo "Error: GIT_NAME environment variable cannot be only whitespace"
    exit 1
fi

# Validate email environment variables
[[ -n "$EMAIL" ]] && validate_email_or_exit "$EMAIL" "EMAIL (environment variable)"
[[ -n "$GIT_EMAIL" ]] && validate_email_or_exit "$GIT_EMAIL" "GIT_EMAIL (environment variable)"
[[ -n "$SSH_EMAIL" ]] && validate_email_or_exit "$SSH_EMAIL" "SSH_EMAIL (environment variable)"

# Global variables
KITTY_INSTALLED=false

# Track what was actually done during this run
CONFIGS_DEPLOYED=false
KITTY_CONFIGURED=false
GIT_CONFIGURED=false
GIT_SKIPPED=false  # Git skipped in unattended mode
ZINIT_CHANGED=false
ZINIT_INSTALLED=false  # New installation (not update)
TPM_CHANGED=false
TPM_INSTALLED=false    # New installation (not update)
SHELL_CHANGED=false
TOOLS_INSTALLED=false  # Essential tools installed
SSH_KEY_GENERATED=false  # SSH key generated
SSH_SKIPPED=false  # SSH skipped in unattended mode
BACKUPS_CREATED=false
declare -a BACKUPS_LIST

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
        run_cmd "$UPDATE_CMD"

        print_info "Installing: ${to_install[*]}"
        run_cmd "$INSTALL_CMD" "${to_install[@]}"
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
        if [ "$UNATTENDED" = true ]; then
            # Unattended mode: install Kitty automatically
            print_info "Installing Kitty..."
            run_cmd "$INSTALL_CMD" kitty
            KITTY_INSTALLED=true
            print_success "Kitty installed"
        else
            # Interactive mode: ask user
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
                run_cmd "$INSTALL_CMD" kitty
                KITTY_INSTALLED=true
                print_success "Kitty installed"
            else
                KITTY_INSTALLED=false
                print_info "Kitty installation skipped"
                print_warn "Default shell will be configured but some terminals may ignore it"
            fi
        fi
    fi
}

################################################################################
# Deploy Kitty Configuration
################################################################################

deploy_kitty_config() {
    if [ "$KITTY_INSTALLED" = true ]; then
        print_header "Deploying Kitty Configuration"

        # Check if the kitty directory symlink already exists and points to the right place
        local kitty_dir_target="$SCRIPT_DIR/kitty/.config/kitty"

        if [ -L "$HOME/.config/kitty" ] && \
           [ "$(readlink -f "$HOME/.config/kitty")" = "$kitty_dir_target" ]; then
            print_skip "Kitty configuration already deployed"
            return
        fi

        # Backup existing config if any
        if [ -d "$HOME/.config/kitty" ] && [ ! -L "$HOME/.config/kitty" ]; then
            local backup
            backup=$(backup_file "$HOME/.config/kitty" true)
            print_success "Backup: $backup"
            BACKUPS_CREATED=true
            BACKUPS_LIST+=("$backup")
        fi

        # Deploy with stow
        cd "$SCRIPT_DIR"

        if run_cmd stow -t "$HOME" kitty; then
            print_success "Kitty configuration deployed"
            print_info "  ~/.config/kitty/kitty.conf → $SCRIPT_DIR/kitty/.config/kitty/kitty.conf"
            print_info "  ~/.config/kitty/dracula.conf → $SCRIPT_DIR/kitty/.config/kitty/dracula.conf"
            KITTY_CONFIGURED=true
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
                run_cmd "$INSTALL_CMD" cascadia-code-fonts
            elif [ "$PKG_MANAGER" = "apt" ]; then
                run_cmd "$INSTALL_CMD" fonts-cascadia-code
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

    local backed_up=0

    for config in "$HOME/.zshrc" "$HOME/.tmux.conf"; do
        if [ -f "$config" ] && [ ! -L "$config" ]; then
            local backup
            backup=$(backup_file "$config")
            print_success "Backup created: $backup"
            BACKUPS_CREATED=true
            BACKUPS_LIST+=("$backup")
            backed_up=1
        elif [ -L "$config" ]; then
            local target
            target=$(readlink -f "$config")
            if [[ "$target" == *"dotfiles"* ]] || [[ "$target" == *"init_script"* ]]; then
                print_skip "$(basename "$config") is already a symlink to dotfiles"
            else
                print_warn "$(basename "$config") is a symlink to: $target"
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

    # Check if symlinks already exist and point to the right place
    local zshrc_target="$SCRIPT_DIR/zsh/.zshrc"
    local tmux_target="$SCRIPT_DIR/tmux/.tmux.conf"

    if [ -L "$HOME/.zshrc" ] && [ "$(readlink -f "$HOME/.zshrc")" = "$zshrc_target" ] && \
       [ -L "$HOME/.tmux.conf" ] && [ "$(readlink -f "$HOME/.tmux.conf")" = "$tmux_target" ]; then
        print_skip "Zsh and Tmux configurations already deployed"
        return
    fi

    cd "$SCRIPT_DIR"

    # Remove existing files/symlinks (backups were already created in backup_configs)
    rm -f "$HOME/.zshrc"
    rm -f "$HOME/.tmux.conf"

    # Deploy with stow
    print_info "Creating symlinks..."
    if run_cmd stow -t "$HOME" zsh tmux; then
        print_success "Symlinks created with Stow"
        print_info "  ~/.zshrc → $SCRIPT_DIR/zsh/.zshrc"
        print_info "  ~/.tmux.conf → $SCRIPT_DIR/tmux/.tmux.conf"
        CONFIGS_DEPLOYED=true

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
        if [ "$UNATTENDED" = true ]; then
            # Unattended mode: skip update prompt
            print_info "Skipping Zinit update"
        else
            # Interactive mode: ask user
            read -p "Do you want to update Zinit? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[OoYy]$ ]]; then
                cd "$ZINIT_HOME"
                run_cmd git pull
                print_success "Zinit updated"
                ZINIT_CHANGED=true
            fi
        fi
    else
        print_info "Cloning Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        run_cmd git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        print_success "Zinit installed"
        ZINIT_CHANGED=true
        ZINIT_INSTALLED=true  # First time installation
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
        if [ "$UNATTENDED" = true ]; then
            # Unattended mode: skip update prompt
            print_info "Skipping TPM update"
        else
            # Interactive mode: ask user
            read -p "Do you want to update TPM? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[OoYy]$ ]]; then
                cd "$TPM_HOME"
                run_cmd git pull
                print_success "TPM updated"
                TPM_CHANGED=true

                # Install/update plugins automatically
                if [ -f "$TPM_HOME/bin/install_plugins" ]; then
                    print_info "Updating tmux plugins..."
                    run_cmd "$TPM_HOME/bin/install_plugins"
                    print_success "Tmux plugins updated"
                fi
            fi
        fi
    else
        print_info "Cloning TPM..."
        mkdir -p "${HOME}/.tmux/plugins"
        run_cmd git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"
        print_success "TPM installed"
        TPM_CHANGED=true
        TPM_INSTALLED=true  # First time installation

        # Install plugins automatically
        if [ -f "$TPM_HOME/bin/install_plugins" ]; then
            print_info "Installing tmux plugins automatically..."
            run_cmd "$TPM_HOME/bin/install_plugins"
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

    # Refresh sudo cache in case it expired during interactive prompts
    sudo -v &>/dev/null || true

    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

    if [ "$CURRENT_SHELL" = "/bin/zsh" ] || [ "$CURRENT_SHELL" = "/usr/bin/zsh" ]; then
        print_skip "Zsh is already the default shell"
    else
        print_info "Current shell: $CURRENT_SHELL"
        print_info "Changing default shell to zsh..."
        if [ -x /bin/zsh ]; then
            run_cmd sudo chsh -s /bin/zsh "$USER"
            print_success "Default shell changed to zsh"
            SHELL_CHANGED=true
        elif [ -x /usr/bin/zsh ]; then
            run_cmd sudo chsh -s /usr/bin/zsh "$USER"
            print_success "Default shell changed to zsh"
            SHELL_CHANGED=true
        else
            print_error "Unable to find zsh binary"
            exit 1
        fi
    fi
}

################################################################################
# Pre-load Zinit Plugins
################################################################################

preload_zinit_plugins() {
    # Only run if Zinit was just installed (first time)
    if [ "$ZINIT_INSTALLED" = true ] && [ -f "$HOME/.zshrc" ]; then
        print_header "Pre-loading Zinit Plugins"
        print_info "Downloading Zsh plugins..."

        # Use zinit update to download all plugins synchronously (waits until complete)
        # This ensures all downloads finish before the script exits
        if [ "$VERBOSE" = true ]; then
            zsh -c "source ~/.zshrc; zinit update --all" 2>&1 || true
        else
            zsh -c "source ~/.zshrc; zinit update --all" &>/dev/null || true
        fi

        print_success "Zinit plugins downloaded"
        print_info "All plugins are ready"
    fi
}

################################################################################
# Install Essential Tools (Optional)
################################################################################

install_essential_tools() {
    # Map of package names to command names
    declare -A tool_commands=(
        ["neovim"]="nvim"
        ["tldr"]="tldr"
        ["jq"]="jq"
        ["curl"]="curl"
        ["xclip"]="xclip"
    )

    local tools=("neovim" "tldr" "jq" "curl" "xclip")

    # Check which tools need to be installed FIRST
    local to_install=()
    for tool in "${tools[@]}"; do
        local cmd="${tool_commands[$tool]}"
        if ! command -v "$cmd" &> /dev/null; then
            to_install+=("$tool")
        fi
    done

    # If all tools are already installed, skip this section entirely
    if [ ${#to_install[@]} -eq 0 ]; then
        return
    fi

    # Show header only if there are tools to install
    print_header "Essential Tools Installation (optional)"

    # Display the list of missing tools
    print_info "The following tools are not installed:"
    for tool in "${to_install[@]}"; do
        echo -e "   ${INFO} $tool"
    done
    echo

    if [ "$UNATTENDED" = true ]; then
        # Unattended mode: install automatically
        print_info "Installing automatically..."
    else
        # Interactive mode: ask user
        read -p "Do you want to install these tools? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Essential tools installation skipped"
            return
        fi
    fi

    # Refresh sudo cache before installation
    sudo -v &>/dev/null || true

    # Install missing tools
    print_info "Installing: ${to_install[*]}"

    if run_cmd "$INSTALL_CMD" "${to_install[@]}"; then
        print_success "Essential tools installed successfully"
        TOOLS_INSTALLED=true

        # Post-installation: Update tldr cache if tldr was just installed
        for pkg in "${to_install[@]}"; do
            if [[ "$pkg" == "tldr" ]]; then
                print_info "Updating tldr database..."
                if tldr -u &> /dev/null; then
                    print_success "tldr database updated"
                else
                    print_warn "Failed to update tldr database (you can run 'tldr -u' manually later)"
                fi
                break
            fi
        done
    else
        print_error "Failed to install some tools"
    fi
}

################################################################################
# Setup Git Configuration (Optional)
################################################################################

setup_git_prompt() {
    print_header "Git Configuration (optional)"

    # Unattended mode: check environment variables
    if [ "$UNATTENDED" = true ]; then
        # Calculate final git email with fallback pattern
        local final_git_email
        final_git_email=$(get_email_with_fallback "GIT_EMAIL")

        # Check if required environment variables are set
        if [ -z "$GIT_NAME" ] || [ -z "$final_git_email" ]; then
            print_skip "Git configuration skipped (environment variables not set)"
            GIT_SKIPPED=true
            return
        fi

        # Variables are set, configure Git
        print_info "Configuring Git with environment variables..."
        if run_script "setup-git.sh" --skip-confirmation --unattended; then
            GIT_CONFIGURED=true
        else
            print_error "Git configuration failed"
        fi
        return
    fi

    # Interactive mode
    # Case 1: Symlink exists (already managed by dotfiles)
    if [ -L "$HOME/.gitconfig" ]; then
        print_skip "Git already managed by dotfiles"
        read -p "Do you want to reconfigure Git? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            print_info "Git configuration skipped"
            return
        fi

    # Case 2: Regular file exists (user's existing config)
    elif [ -f "$HOME/.gitconfig" ]; then
        print_warn "You already have a .gitconfig file"
        echo
        print_info "The setup-git.sh script will:"
        print_info "  - Create a backup of your current .gitconfig"
        print_info "  - Replace it with our template (name, email, aliases)"
        print_info "  - Manage it with Stow (symlink)"
        echo
        read -p "Do you want to replace it with our template? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
            print_info "Git configuration skipped"
            print_info "You can run ./setup-git.sh later to configure it"
            return
        fi

    # Case 3: No config exists
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
    local git_exit_code
    run_script "setup-git.sh" --skip-confirmation
    git_exit_code=$?

    if [ $git_exit_code -eq 0 ]; then
        GIT_CONFIGURED=true
    elif [ $git_exit_code -eq 2 ]; then
        print_info "Git configuration cancelled by user"
    else
        print_error "Git configuration failed"
        print_warn "You can run ./setup-git.sh later to configure it"
    fi
}

################################################################################
# Setup SSH Key (Optional)
################################################################################

setup_ssh_key() {
    print_header "SSH Key Generation (optional)"

    # Unattended mode: check environment variables
    if [ "$UNATTENDED" = true ]; then
        # Calculate final ssh email with fallback pattern
        local final_ssh_email
        final_ssh_email=$(get_email_with_fallback "SSH_EMAIL")

        # Check if required environment variable is set
        if [ -z "$final_ssh_email" ]; then
            print_skip "SSH key generation skipped (EMAIL not set)"
            SSH_SKIPPED=true
            return
        fi

        # Check if SSH key already exists
        if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
            print_skip "SSH key already exists"
            return
        fi

        # Generate SSH key
        print_info "Generating SSH key with environment variables..."
        if run_script "setup-ssh.sh" --skip-confirmation --unattended; then
            SSH_KEY_GENERATED=true
        else
            print_error "SSH key generation failed"
        fi
        return
    fi

    # Interactive mode
    # Case 1: SSH key already exists
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        print_skip "SSH key already exists"

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
            print_info "SSH key generation skipped"
            return
        fi

    # Case 2: No SSH key exists
    else
        print_info "No SSH key found"
        echo
        print_info "Generating an SSH key will allow you to:"
        print_info "  - Push/pull from GitHub/GitLab without passwords"
        print_info "  - Connect to remote servers securely"
        echo
        read -p "Do you want to generate an SSH key? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "SSH key generation skipped"
            return
        fi
    fi

    # Run the SSH setup script
    local ssh_exit_code
    run_script "setup-ssh.sh" --skip-confirmation
    ssh_exit_code=$?

    if [ $ssh_exit_code -eq 0 ]; then
        SSH_KEY_GENERATED=true
    elif [ $ssh_exit_code -eq 2 ]; then
        print_info "SSH key generation cancelled by user"
    else
        print_error "SSH key generation failed"
        print_warn "You can run ./setup-ssh.sh later to generate it"
    fi
}

################################################################################
# Final Message
################################################################################

print_final_message() {
    # Check if anything was actually done (including skipped sections)
    local anything_changed=false
    if [ "$CONFIGS_DEPLOYED" = true ] || [ "$KITTY_CONFIGURED" = true ] || \
       [ "$GIT_CONFIGURED" = true ] || [ "$GIT_SKIPPED" = true ] || \
       [ "$ZINIT_CHANGED" = true ] || [ "$TPM_CHANGED" = true ] || \
       [ "$SHELL_CHANGED" = true ] || [ "$TOOLS_INSTALLED" = true ] || \
       [ "$SSH_KEY_GENERATED" = true ] || [ "$SSH_SKIPPED" = true ]; then
        anything_changed=true
    fi

    # Check if shell reload is needed (only on first installation)
    local reload_needed=false
    if [ "$ZINIT_INSTALLED" = true ] || [ "$TPM_INSTALLED" = true ]; then
        reload_needed=true
    fi

    echo
    if [ "$anything_changed" = true ]; then
        # Check if this is a first installation or an update
        if [ "$ZINIT_INSTALLED" = true ] || [ "$TPM_INSTALLED" = true ]; then
            # First installation
            echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║                                                        ║${NC}"
            echo -e "${GREEN}║      Installation completed successfully! 🎉           ║${NC}"
            echo -e "${GREEN}║                                                        ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        else
            # Update/reconfiguration
            echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║                                                        ║${NC}"
            echo -e "${GREEN}║         Update completed successfully! ✓               ║${NC}"
            echo -e "${GREEN}║                                                        ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        fi
    else
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                                                        ║${NC}"
        echo -e "${BLUE}║      No changes made - Already up to date! ✓           ║${NC}"
        echo -e "${BLUE}║                                                        ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    fi
    echo

    # Show SSH key if it was just generated
    if [ "$SSH_KEY_GENERATED" = true ]; then
        echo -e "${YELLOW}🔑 Your SSH Public Key (copy this):${NC}"
        echo
        cat "$HOME/.ssh/id_ed25519.pub"
        echo
        echo -e "${YELLOW}📋 Add this key to GitHub:${NC}"
        echo -e "   ${INFO} 1. Copy the key above"
        echo -e "   ${INFO} 2. Go to: ${BLUE}https://github.com/settings/keys${NC}"
        echo -e "   ${INFO} 3. Click 'New SSH key'"
        echo -e "   ${INFO} 4. Paste your key and save"
        echo
    fi

    # Show how to configure skipped components
    if [ "$GIT_SKIPPED" = true ] || [ "$SSH_SKIPPED" = true ]; then
        echo -e "${YELLOW}⚙️  Manual Configuration Required:${NC}"
        echo

        if [ "$GIT_SKIPPED" = true ]; then
            echo -e "${YELLOW}Git Configuration:${NC}"
            echo -e "   ${INFO} Run manually: ${BLUE}./setup-git.sh${NC}"
            echo -e "   ${INFO} Or rerun with arguments:"
            echo -e "       ${BLUE}./bootstrap.sh -y --git-name \"Your Name\" --git-email \"you@example.com\"${NC}"
            echo -e "   ${INFO} Or use ${BLUE}--email${NC} as default for both Git and SSH:"
            echo -e "       ${BLUE}./bootstrap.sh -y --git-name \"Your Name\" --email \"you@example.com\"${NC}"
            echo
        fi

        if [ "$SSH_SKIPPED" = true ]; then
            echo -e "${YELLOW}SSH Key Generation:${NC}"
            echo -e "   ${INFO} Run manually: ${BLUE}./setup-ssh.sh${NC}"
            echo -e "   ${INFO} Or rerun with argument:"
            echo -e "       ${BLUE}./bootstrap.sh -y --ssh-email \"you@example.com\"${NC}"
            echo -e "   ${INFO} Or use ${BLUE}--email${NC} as default for both Git and SSH:"
            echo -e "       ${BLUE}./bootstrap.sh -y --email \"you@example.com\"${NC}"
            echo
        fi
    fi

    # Only show "Next Steps" if shell reload is needed
    if [ "$reload_needed" = true ]; then
        echo -e "${BLUE}📝 Next Steps:${NC}"
        echo

        # Detect if we're in Kitty
        if [ -n "$KITTY_WINDOW_ID" ]; then
            # Scenario 1: User IS in Kitty
            echo -e "${YELLOW}You are currently in Kitty:${NC}"
            echo -e "   ${INFO} Simply run ${BLUE}exec zsh${NC}"
            echo -e "           ${INFO} This will reload zsh and apply the changes"
        elif [ "$KITTY_CONFIGURED" = true ]; then
            # Scenario 2: Kitty was just configured
            echo -e "${YELLOW}Recommended - Launch Kitty for the full experience:${NC}"
            echo -e "   ${INFO} Simply run ${BLUE}kitty${NC}"
            echo -e "           ${INFO} This will auto-launch zsh and tmux with your new configuration"
            echo
            echo -e "${YELLOW}Alternative - Continue in this terminal:${NC}"
            echo -e "   ${INFO} Close and reopen terminal OR run ${BLUE}exec zsh${NC}"
        else
            # Scenario 3: No Kitty or not configured
            echo -e "${YELLOW}Apply the changes:${NC}"
            echo -e "   ${INFO} Close and reopen terminal OR run ${BLUE}exec zsh${NC}"
        fi
        echo
    fi

    # Show backup files only if created during this run
    if [ "$BACKUPS_CREATED" = true ]; then
        echo -e "${YELLOW}📂 Backup files created during this run:${NC}"
        for backup in "${BACKUPS_LIST[@]}"; do
            echo -e "   ${INFO} $backup"
        done
        echo
    fi

    # Show what was actually done
    echo -e "${BLUE}✨ Changes applied:${NC}"
    local something_shown=false

    if [ "$CONFIGS_DEPLOYED" = true ]; then
        echo -e "   ${CHECK} Zsh and Tmux configurations deployed"
        something_shown=true
    fi

    if [ "$KITTY_CONFIGURED" = true ]; then
        echo -e "   ${CHECK} Kitty configuration deployed (Dracula theme + CascadiaCode)"
        something_shown=true
    fi

    if [ "$GIT_CONFIGURED" = true ]; then
        echo -e "   ${CHECK} Git configuration deployed"
        something_shown=true
    fi

    if [ "$ZINIT_INSTALLED" = true ]; then
        echo -e "   ${CHECK} Zinit (Zsh plugin manager) installed"
        something_shown=true
    elif [ "$ZINIT_CHANGED" = true ]; then
        echo -e "   ${CHECK} Zinit (Zsh plugin manager) updated"
        something_shown=true
    fi

    if [ "$TPM_INSTALLED" = true ]; then
        echo -e "   ${CHECK} TPM (Tmux plugin manager) installed"
        something_shown=true
    elif [ "$TPM_CHANGED" = true ]; then
        echo -e "   ${CHECK} TPM (Tmux plugin manager) updated"
        something_shown=true
    fi

    if [ "$SHELL_CHANGED" = true ]; then
        echo -e "   ${CHECK} Default shell changed to zsh"
        something_shown=true
    fi

    if [ "$TOOLS_INSTALLED" = true ]; then
        echo -e "   ${CHECK} Essential tools installed (neovim, tldr, jq, curl)"
        something_shown=true
    fi

    if [ "$SSH_KEY_GENERATED" = true ]; then
        echo -e "   ${CHECK} SSH key generated (ed25519)"
        something_shown=true
    fi

    if [ "$GIT_SKIPPED" = true ]; then
        echo -e "   ${CIRCLE} Git configuration skipped"
        something_shown=true
    fi

    if [ "$SSH_SKIPPED" = true ]; then
        echo -e "   ${CIRCLE} SSH key generation skipped"
        something_shown=true
    fi

    if [ "$something_shown" = false ]; then
        echo -e "   ${INFO} Everything was already configured"
    fi

    echo
}

################################################################################
# Main Execution
################################################################################

main() {
    # Only clear screen if no flags were passed (preserve history when automated)
    if [ "$VERBOSE" = false ] && [ "$UNATTENDED" = false ]; then
        clear
    fi

    echo -e "${BLUE}"
    echo "  ____        _    __ _ _            "
    echo " |  _ \  ___ | |_ / _(_) | ___  ___  "
    echo " | | | |/ _ \| __| |_| | |/ _ \/ __| "
    echo " | |_| | (_) | |_|  _| | |  __/\__ \ "
    echo " |____/ \___/ \__|_| |_|_|\___||___/ "
    echo -e "${NC}"
    echo -e "${BLUE}  Automated Installation - Zsh & Tmux${NC}\n"

    # Request sudo access upfront to avoid timeout during interactive prompts
    print_info "This script requires sudo privileges for package installation and shell configuration"
    sudo -v || { print_error "Sudo access required"; exit 1; }

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
    preload_zinit_plugins
    install_essential_tools
    setup_git_prompt
    setup_ssh_key
    print_final_message
}

# Run main function
main
