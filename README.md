# Dotfiles Manager

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/yourusername/dotfiles/releases/tag/v1.0)
[![Fedora](https://img.shields.io/badge/Fedora-supported-51A2DA.svg?logo=fedora)](https://getfedora.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-supported-E95420.svg?logo=ubuntu)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-supported-A81D33.svg?logo=debian)](https://www.debian.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A production-ready, automated dotfiles management system that streamlines development environment setup across multiple machines. One command to install and configure your entire terminal workspace.

## Overview

This dotfiles manager automates the complete setup of a modern, feature-rich development environment. It handles dependency installation, configuration deployment, plugin management, and even generates your Git and SSH configurations — all with automatic backups and idempotent execution.

### Key Features

- **One-Command Installation** - Complete setup in a single command
- **Automatic Backups** - Timestamped backups before any modifications
- **Multi-Platform Support** - Works on Fedora, RHEL, Debian, and Ubuntu
- **Idempotent & Safe** - Can be safely rerun without side effects
- **Three Execution Modes** - Interactive, verbose, or fully unattended
- **Plugin Management** - Auto-installs and configures Zinit (Zsh) and TPM (Tmux)
- **Modern Theme** - Beautiful Dracula theme across all tools
- **Modular Design** - Standalone scripts for Git and SSH setup
- **CI/CD Ready** - Environment variable support for automation
- **Smart Deployment** - GNU Stow for clean symlink management

## Quick Start

### Prerequisites

- Linux system (Fedora/RHEL with `dnf` or Debian/Ubuntu with `apt`)
- Sudo access
- Internet connection
- Git (will be installed if missing)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the bootstrap script
./bootstrap.sh
```

That's it! The script will:
1. Detect your system and package manager
2. Install required dependencies (git, tmux, zsh, stow)
3. Optionally install Kitty terminal and CascadiaCode font
4. Backup any existing configurations
5. Deploy dotfiles using GNU Stow
6. Install and configure plugin managers (Zinit, TPM)
7. Pre-load all plugins automatically
8. Change your default shell to Zsh
9. Optionally configure Git and generate SSH keys

### First Steps After Installation

```bash
# Logout and login (or reboot) to activate Zsh as default shell
# Then launch a new terminal

# Your environment is ready!
# Tmux will auto-launch when you open a terminal
# All plugins are pre-loaded and ready to use
```

## What's Included

### Zsh Configuration

A powerful Zsh setup with modern plugins and features:

**Plugin Manager:**
- [Zinit](https://github.com/zdharma-continuum/zinit) - Fast, feature-rich plugin manager

**Plugins:**
- [Starship](https://starship.rs/) - Modern, fast, customizable prompt
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Fish-like syntax highlighting
- [zsh-completions](https://github.com/zsh-users/zsh-completions) - Additional completion definitions
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions

**Oh-My-Zsh Snippets:**
- Git plugin (aliases and functions)
- Sudo plugin (ESC ESC to prefix with sudo)
- Command-not-found (suggests package installation)

**Features:**
- 5,000 command history
- Shared history between sessions
- Case-insensitive completion
- Custom keybindings (Ctrl+F, Ctrl+P, Ctrl+N)
- Auto-launch Tmux on terminal start

**Aliases:**
```bash
ls='ls --color'
la='ls -a'
lla='ls -la'
c='clear'
```

### Tmux Configuration

Professional Tmux setup with monitoring and aesthetics:

**Plugin Manager:**
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager

**Plugins:**
- [Dracula Theme](https://draculatheme.com/tmux) - Beautiful dark theme
- CPU, GPU, RAM monitoring widgets
- Network bandwidth display
- Time and date display

**Features:**
- 256 colors + RGB support
- Zsh as default shell
- Vim-style pane navigation (Prefix + h/j/k/l)
- Easy config reload (Prefix + r)
- Status bar with system monitoring
- Custom icon: 👽 with hostname

### Kitty Terminal

Modern GPU-accelerated terminal emulator (optional):

**Configuration:**
- CascadiaCode font family (all variants)
- Font size: 16pt
- Dracula color scheme
- Hidden window decorations
- Audio bell disabled

**Features:**
- GPU-accelerated rendering
- Ligature support
- Multiple windows and tabs
- Image display in terminal

### Git Configuration

Sensible Git defaults and useful aliases:

**Settings:**
- Default branch: `main`
- Auto-coloring enabled
- User name and email (configured during setup)

**Aliases:**
```bash
git st   # status
git co   # checkout
git br   # branch
git ci   # commit
git lg   # pretty log with graph
```

### SSH Key Generation

Automated SSH key creation (optional):

**Features:**
- Modern ed25519 keys (secure, fast, compact)
- Optional passphrase support
- Automatic ssh-agent integration
- Auto-copy public key to clipboard (if xclip available)
- Automatic backup of existing keys

## Installation Options

### Interactive Mode (Default)

```bash
./bootstrap.sh
```

Prompts for decisions at each step. Perfect for first-time setup.

### Verbose Mode

```bash
./bootstrap.sh -v
# or
./bootstrap.sh --verbose
```

Shows detailed command output. Useful for debugging.

### Unattended Mode

```bash
./bootstrap.sh -y
# or
./bootstrap.sh --yes
```

Fully automated installation with no prompts. Uses defaults for all decisions.

### Command-Line Arguments

```bash
# Specify Git configuration
./bootstrap.sh --git-name "Your Name" --git-email "you@example.com"

# Specify SSH email
./bootstrap.sh --ssh-email "you@example.com"

# Use same email for both Git and SSH
./bootstrap.sh --email "you@example.com"

# Combine options
./bootstrap.sh -v -y --git-name "Developer" --email "dev@example.com"
```

### Environment Variables

Perfect for CI/CD and automation:

```bash
# Full unattended setup
GIT_NAME="Your Name" \
GIT_EMAIL="you@example.com" \
SSH_EMAIL="you@example.com" \
./bootstrap.sh -y

# Use EMAIL as fallback for both
EMAIL="you@example.com" ./bootstrap.sh -y
```

### What Gets Backed Up

All existing configurations are backed up to `~/.dotfiles-backups/` with timestamps:

```
~/.dotfiles-backups/
├── zshrc.20251226_143022
├── tmux.conf.20251226_143022
├── gitconfig.20251226_153045
├── kitty.20251226_143022/
└── id_ed25519.20251226_160115
```

Backup format: `filename.YYYYMMDD_HHMMSS`

## Customization

### Modifying Zsh Configuration

The Zsh config is located at `zsh/.zshrc`.

**Adding Aliases:**
```bash
# Edit the file
vim ~/dotfiles/zsh/.zshrc

# Add your aliases at the end
alias myalias='command'

# Redeploy
cd ~/dotfiles
stow -R zsh

# Reload Zsh
source ~/.zshrc
```

**Adding Plugins:**
```bash
# Edit zsh/.zshrc and add to the Zinit section
zinit light user/plugin-name

# Reload
source ~/.zshrc
```

**Changing Prompt:**
```bash
# The prompt is managed by Starship
# Configure it via ~/.config/starship.toml
# See: https://starship.rs/config/
```

### Modifying Tmux Configuration

The Tmux config is located at `tmux/.tmux.conf`.

**Adding Plugins:**
```bash
# Edit tmux/.tmux.conf
vim ~/dotfiles/tmux/.tmux.conf

# Add plugin
set -g @plugin 'user/plugin-name'

# Redeploy
cd ~/dotfiles
stow -R tmux

# Reload Tmux (inside Tmux session)
tmux source-file ~/.tmux.conf

# Install new plugins: Prefix + I (capital i)
```

**Changing Keybindings:**
```bash
# Edit tmux/.tmux.conf
bind-key C-a send-prefix  # Example: change prefix

# Redeploy and reload (see above)
```

### Modifying Kitty Configuration

Kitty configs are in `kitty/.config/kitty/`.

**Changing Theme:**
```bash
# Edit kitty/.config/kitty/kitty.conf
# Comment out current theme and add new one
include new-theme.conf

# Redeploy
cd ~/dotfiles
stow -R kitty

# Kitty reloads automatically or Ctrl+Shift+F5
```

**Changing Font:**
```bash
# Edit kitty/.config/kitty/kitty.conf
font_family      New Font Name
font_size        14.0

# Redeploy (see above)
```

### Adding Your Own Dotfiles

```bash
# 1. Create a directory for your application
cd ~/dotfiles
mkdir -p app/.config/app

# 2. Add your configuration file
cp ~/.config/app/config.conf app/.config/app/

# 3. Remove or backup original
rm ~/.config/app/config.conf

# 4. Deploy with Stow
stow app

# 5. (Optional) Add to bootstrap.sh for automatic deployment
# Edit bootstrap.sh and add:
# run_cmd "stow -t \"$HOME\" app" "Deploying app configuration"
```

### Syncing Across Machines

```bash
# On machine 1: Commit your customizations
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push

# On machine 2: Pull and redeploy
cd ~/dotfiles
git pull
./bootstrap.sh  # Redeploy with latest changes
```

## Standalone Scripts

### Git Configuration Script

Use `setup-git.sh` independently to configure Git:

```bash
# Interactive mode
./setup-git.sh

# Unattended mode
./setup-git.sh --unattended --skip-confirmation

# With environment variables
GIT_NAME="Your Name" GIT_EMAIL="you@example.com" ./setup-git.sh --unattended
```

**What it does:**
- Generates `.gitconfig` from template
- Validates email format
- Backs up existing configuration
- Deploys via GNU Stow

### SSH Key Generation Script

Use `setup-ssh.sh` independently to generate SSH keys:

```bash
# Interactive mode
./setup-ssh.sh

# Unattended mode
SSH_EMAIL="you@example.com" ./setup-ssh.sh --unattended --skip-confirmation
```

**What it does:**
- Generates ed25519 SSH key pair
- Optional passphrase protection
- Backs up existing keys
- Adds key to ssh-agent
- Copies public key to clipboard (if xclip available)

## Troubleshooting

### Permission Denied

```bash
# Ensure scripts are executable
chmod +x bootstrap.sh setup-git.sh setup-ssh.sh

# Ensure you have sudo access
sudo -v
```

### Stow Conflicts

If Stow reports conflicts:

```bash
# Files already exist and aren't symlinks
# The bootstrap script backs these up automatically
# If running Stow manually, use -R to restow
cd ~/dotfiles
stow -R zsh  # Restow a specific package
```

### Plugin Installation Fails

```bash
# Zsh plugins
# Delete and reinstall Zinit
rm -rf ~/.local/share/zinit
./bootstrap.sh  # Reinstalls Zinit

# Tmux plugins
# Delete and reinstall TPM
rm -rf ~/.tmux/plugins/tpm
./bootstrap.sh  # Reinstalls TPM
# Then: Prefix + I to install plugins
```

### Shell Didn't Change

```bash
# Verify Zsh is installed
which zsh

# Change shell manually
chsh -s $(which zsh)

# Logout and login for changes to take effect
```

### Kitty Not Found

```bash
# The package name varies by distribution
# Fedora/RHEL
sudo dnf install kitty

# Debian/Ubuntu
sudo apt install kitty

# Then redeploy
cd ~/dotfiles && stow kitty
```

## Advanced Usage

### Unattended Mode for CI/CD

Perfect for Docker containers or automated deployments:

```dockerfile
# In Dockerfile
RUN git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
RUN EMAIL="dev@example.com" ~/dotfiles/bootstrap.sh -y
```

Or in shell scripts:

```bash
#!/bin/bash
export GIT_NAME="CI User"
export EMAIL="ci@example.com"
cd ~/dotfiles && ./bootstrap.sh -y
```

### Environment Variables Reference

| Variable | Description | Fallback |
|----------|-------------|----------|
| `EMAIL` | Global email for Git and SSH | None |
| `GIT_NAME` | Git user name | Prompt/skip |
| `GIT_EMAIL` | Git user email | `$EMAIL` |
| `SSH_EMAIL` | SSH key comment | `$EMAIL` → Git email |

**Priority:** Specific variable → `EMAIL` → Prompt (interactive) / Skip (unattended)

### Re-running the Script

The bootstrap script is **idempotent** and can be safely rerun:

```bash
# Update plugins
./bootstrap.sh -y

# Redeploy after making changes
./bootstrap.sh

# Fix broken installation
./bootstrap.sh -v  # Verbose mode to see what's happening
```

The script intelligently:
- Skips already-installed packages
- Updates existing plugin managers
- Respects existing symlinks
- Creates backups only when needed

## Uninstallation

### Removing Dotfiles

```bash
# Unstow configurations (removes symlinks)
cd ~/dotfiles
stow -D zsh tmux git kitty

# Restore from backups if needed
cp ~/.dotfiles-backups/zshrc.* ~/.zshrc
cp ~/.dotfiles-backups/tmux.conf.* ~/.tmux.conf
# etc.

# Change shell back to bash
chsh -s /bin/bash

# Remove the repository
rm -rf ~/dotfiles
```

### Cleaning Up Completely

```bash
# Remove plugin managers and plugins
rm -rf ~/.local/share/zinit
rm -rf ~/.tmux/plugins

# Remove backups
rm -rf ~/.dotfiles-backups

# Remove Kitty config (if you don't want it)
rm -rf ~/.config/kitty
```

## Project Structure

```
dotfiles/
├── bootstrap.sh              # Main installation script
├── setup-git.sh              # Git configuration generator
├── setup-ssh.sh              # SSH key generator
├── lib/                      # Shared libraries
│   ├── common.sh            # UI helpers and utilities
│   ├── validation.sh        # Input validation functions
│   └── args.sh              # Argument parsing
├── templates/
│   └── gitconfig            # Git config template
├── zsh/
│   └── .zshrc               # Zsh configuration
├── tmux/
│   └── .tmux.conf           # Tmux configuration
├── kitty/
│   └── .config/kitty/       # Kitty terminal configuration
│       ├── kitty.conf
│       └── dracula.conf
└── git/
    └── .gitconfig           # Generated Git config (deployed here)
```

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Author

**R4yL**
- Email: luca.ray@protonmail.ch
- GitHub: [@yourusername](https://github.com/yourusername)

## Contributing

Contributions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests
- Share your customizations
- Improve documentation

---

**Happy coding!** 🚀
