#!/bin/bash

################################################################################
# Dotfiles Installation Script
# Author: R4yL
# Description: Automated setup for zsh, tmux and kitty configurations
# Supports: Fedora (dnf) and Debian/Ubuntu (apt)
################################################################################

set -e  # Exit on error

# Parse command line arguments
VERBOSE=false
for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
    esac
done

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

# Get the directory where this script is located (once, at the beginning)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track what was actually done during this run
CONFIGS_DEPLOYED=false
KITTY_CONFIGURED=false
GIT_CONFIGURED=false
ZINIT_CHANGED=false
ZINIT_INSTALLED=false  # New installation (not update)
TPM_CHANGED=false
TPM_INSTALLED=false    # New installation (not update)
SHELL_CHANGED=false
TOOLS_INSTALLED=false  # Essential tools installed
SSH_KEY_GENERATED=false  # SSH key generated
BACKUPS_CREATED=false
declare -a BACKUPS_LIST

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

backup_file() {
    local file="$1"
    local move_instead_of_copy="${2:-false}"  # Optional: true to move instead of copy
    local backup_dir="$HOME/.dotfiles-backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # Get the base name without path (remove .config/ prefix if present)
    local basename=$(basename "$file")
    # Special handling for .config subdirectories
    if [[ "$file" == *".config/"* ]]; then
        basename=$(echo "$file" | sed 's|.*/\.config/||')
    fi
    local backup_path="$backup_dir/${basename}.${timestamp}"

    # Backup the file or directory
    if [ "$move_instead_of_copy" = "true" ]; then
        mv "$file" "$backup_path"
    else
        if [ -d "$file" ]; then
            cp -r "$file" "$backup_path"
        else
            cp "$file" "$backup_path"
        fi
    fi

    echo "$backup_path"
}

run_cmd() {
    if [ "$VERBOSE" = true ]; then
        "$@"
    else
        "$@" &> /dev/null
    fi
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
        run_cmd $UPDATE_CMD

        print_info "Installing: ${to_install[*]}"
        run_cmd $INSTALL_CMD "${to_install[@]}"
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
            run_cmd $INSTALL_CMD kitty
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

        # Check if the kitty directory symlink already exists and points to the right place
        local kitty_dir_target="$SCRIPT_DIR/kitty/.config/kitty"

        if [ -L "$HOME/.config/kitty" ] && \
           [ "$(readlink -f "$HOME/.config/kitty")" = "$kitty_dir_target" ]; then
            print_skip "Kitty configuration already deployed"
            return
        fi

        # Backup existing config if any
        if [ -d "$HOME/.config/kitty" ] && [ ! -L "$HOME/.config/kitty" ]; then
            local backup=$(backup_file "$HOME/.config/kitty" true)
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
                run_cmd $INSTALL_CMD cascadia-code-fonts
            elif [ "$PKG_MANAGER" = "apt" ]; then
                run_cmd $INSTALL_CMD fonts-cascadia-code
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
            local backup=$(backup_file "$config")
            print_success "Backup created: $backup"
            BACKUPS_CREATED=true
            BACKUPS_LIST+=("$backup")
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
        read -p "Do you want to update Zinit? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[OoYy]$ ]]; then
            cd "$ZINIT_HOME"
            run_cmd git pull
            print_success "Zinit updated"
            ZINIT_CHANGED=true
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
        print_info "Downloading Zsh plugins in background..."

        # Launch zsh interactively to trigger Zinit plugin installation
        # Use timeout to avoid hanging, and run in background
        if [ "$VERBOSE" = true ]; then
            timeout 30 zsh -i -c "sleep 2" 2>&1 || true
        else
            timeout 30 zsh -i -c "sleep 2" &>/dev/null || true
        fi

        print_success "Zinit plugins pre-loaded"
        print_info "Plugins will be ready on first zsh launch"
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

    read -p "Do you want to install these tools? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Essential tools installation skipped"
        return
    fi

    # Install missing tools
    print_info "Installing: ${to_install[*]}"

    if run_cmd $INSTALL_CMD "${to_install[@]}"; then
        print_success "Essential tools installed successfully"
        TOOLS_INSTALLED=true

        # Post-installation: Update tldr cache if tldr was just installed
        if [[ " ${to_install[@]} " =~ " tldr " ]]; then
            print_info "Updating tldr database..."
            if tldr -u &> /dev/null; then
                print_success "tldr database updated"
            else
                print_warn "Failed to update tldr database (you can run 'tldr -u' manually later)"
            fi
        fi
    else
        print_error "Failed to install some tools"
    fi
}

################################################################################
# Setup Git Configuration (Optional)
################################################################################

setup_git_prompt() {
    print_header "Git Configuration (optional)"

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
    if [ -x "$SCRIPT_DIR/setup-git.sh" ]; then
        "$SCRIPT_DIR/setup-git.sh" --skip-confirmation
        local git_exit_code=$?

        if [ $git_exit_code -eq 0 ]; then
            GIT_CONFIGURED=true
        elif [ $git_exit_code -eq 2 ]; then
            print_info "Git configuration cancelled by user"
        else
            print_error "Git configuration failed"
            print_warn "You can run ./setup-git.sh later to configure it"
        fi
    else
        print_error "setup-git.sh not found or not executable"
    fi
}

################################################################################
# Setup SSH Key (Optional)
################################################################################

setup_ssh_key() {
    print_header "SSH Key Generation (optional)"

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
    if [ -x "$SCRIPT_DIR/setup-ssh.sh" ]; then
        if [ "$VERBOSE" = true ]; then
            "$SCRIPT_DIR/setup-ssh.sh" --skip-confirmation -v
        else
            "$SCRIPT_DIR/setup-ssh.sh" --skip-confirmation
        fi
        local ssh_exit_code=$?

        if [ $ssh_exit_code -eq 0 ]; then
            SSH_KEY_GENERATED=true
        elif [ $ssh_exit_code -eq 2 ]; then
            print_info "SSH key generation cancelled by user"
        else
            print_error "SSH key generation failed"
            print_warn "You can run ./setup-ssh.sh later to generate it"
        fi
    else
        print_error "setup-ssh.sh not found or not executable"
    fi
}

################################################################################
# Final Message
################################################################################

print_final_message() {
    # Check if anything was actually done
    local anything_changed=false
    if [ "$CONFIGS_DEPLOYED" = true ] || [ "$KITTY_CONFIGURED" = true ] || \
       [ "$GIT_CONFIGURED" = true ] || [ "$ZINIT_CHANGED" = true ] || \
       [ "$TPM_CHANGED" = true ] || [ "$SHELL_CHANGED" = true ] || \
       [ "$TOOLS_INSTALLED" = true ] || [ "$SSH_KEY_GENERATED" = true ]; then
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

    if [ "$something_shown" = false ]; then
        echo -e "   ${INFO} Everything was already configured"
    fi

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
    preload_zinit_plugins
    install_essential_tools
    setup_git_prompt
    setup_ssh_key
    print_final_message
}

# Run main function
main
