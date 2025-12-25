# Dotfiles - Zsh, Tmux & Kitty Configuration

Personal configuration for Zsh, Tmux and Kitty with automatic plugin management and CascadiaCode font installation.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Structure](#structure)
- [Plugins](#plugins)
- [Features](#features)
- [Customization](#customization)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project contains my personal configurations for:
- **Zsh** with [Zinit](https://github.com/zdharma-continuum/zinit) (plugin manager)
- **Tmux** with [TPM](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager)
- **Kitty** (modern terminal emulator) with Dracula theme
- **Git** with custom aliases and configuration

The bootstrap script fully automates configuration deployment using [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks.

## 📦 Prerequisites

### Supported Systems
- **Fedora / RHEL** (package manager: `dnf`)
- **Debian / Ubuntu** (package manager: `apt`)

### Dependencies
The script will automatically install all dependencies:
- `git`, `tmux`, `zsh`, `stow` (required)
- `kitty` (optional, offered during installation)
- `CascadiaCode` font (automatically installed if Kitty is chosen)

**No manual installation required!**

## 🚀 Installation

### Quick Installation

```bash
# 1. Clone the repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# 2. Run the bootstrap script
./bootstrap.sh
```

The script will automatically:
1. ✅ Detect the system (dnf or apt)
2. ✅ Install base dependencies (git, tmux, zsh, stow)
3. ✅ **Offer to install Kitty** (recommended terminal emulator)
4. ✅ Backup existing configurations
5. ✅ Deploy dotfiles with Stow (zsh, tmux)
6. ✅ Deploy Kitty configuration (if installed)
7. ✅ **Automatically install CascadiaCode font** (if Kitty installed)
8. ✅ Install Zinit (Zsh plugin manager)
9. ✅ Install TPM (Tmux plugin manager)
10. ✅ **Install Tmux plugins automatically**
11. ✅ Configure default shell (zsh)
12. ✅ **Offer to install essential tools** (neovim, tldr, jq, curl)
13. ✅ **Offer to configure Git** (name, email, aliases)
14. ✅ **Offer to generate SSH key** (ed25519, ready for GitHub)

### Updating Configuration

The script is **idempotent** - you can rerun it to update:

```bash
cd ~/dotfiles
git pull  # Get latest changes
./bootstrap.sh  # Apply changes
```

### Security Features

- **Idempotent**: Script can be safely rerun
- **Automatic backup**: Existing configurations are backed up to `~/.dotfiles-backups/` with timestamp
- **Non-destructive**: No data is lost
- **Smart detection**: Skips already completed steps
- **Portable**: Works from any location
- **Centralized backups**: All backups are stored in `~/.dotfiles-backups/` for easy management

## 📂 Structure

```
dotfiles/
├── bootstrap.sh            # Bootstrap script (installation & update)
├── setup-git.sh            # Git configuration generator
├── setup-ssh.sh            # SSH key generator
├── README.md               # This documentation
├── zsh/
│   └── .zshrc             # Zsh configuration
├── tmux/
│   └── .tmux.conf         # Tmux configuration
├── git/
│   └── .gitconfig         # Git configuration template
└── kitty/
    └── .config/
        └── kitty/
            ├── kitty.conf      # Kitty configuration
            └── dracula.conf    # Dracula theme for Kitty
```

After installation, the following symlinks are created:
```
~/.zshrc → <path-to-dotfiles>/zsh/.zshrc
~/.tmux.conf → <path-to-dotfiles>/tmux/.tmux.conf
~/.gitconfig → <path-to-dotfiles>/git/.gitconfig (if configured)
~/.config/kitty/kitty.conf → <path-to-dotfiles>/kitty/.config/kitty/kitty.conf
~/.config/kitty/dracula.conf → <path-to-dotfiles>/kitty/.config/kitty/dracula.conf
```

## 🔌 Plugins

### Zsh (via Zinit)

| Plugin | Description |
|--------|-------------|
| [starship](https://starship.rs/) | Modern and fast prompt |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Command syntax highlighting |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | Advanced autocompletion |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | History-based suggestions |

**Oh-My-Zsh Snippets**:
- `git` - Git aliases and functions
- `sudo` - Prefix previous command with sudo (ESC ESC)
- `command-not-found` - Suggests installation of missing commands

### Tmux (via TPM)

| Plugin | Description |
|--------|-------------|
| [dracula/tmux](https://draculatheme.com/tmux) | Dracula theme with custom widgets |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Automatic session saving |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Session restoration after reboot |
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Sensible default configurations |

## ✨ Features

### Kitty (Terminal Emulator)

- **Theme**: Integrated Dracula with complete color palette
- **Font**: CascadiaCode (automatically installed)
  - Ligature support
  - Optimized for code
  - Variants: Regular, Bold, Italic, Light, etc.
- **Configuration**:
  - Zsh shell by default
  - Font size: 16pt
  - Hidden window decorations
  - RGB and 256 color support

### Zsh

- **Auto-launch Tmux**: Tmux automatically launches on terminal open
- **Smart history**:
  - 5000 commands memorized
  - Duplicate removal
  - Shared history between sessions
- **Custom keybindings**:
  - `Ctrl+F`: Accept suggestion
  - `Ctrl+P`: Backward history search
  - `Ctrl+N`: Forward history search

### Tmux

- **Theme**: Dracula with system widgets (CPU, GPU, RAM, network, time)
- **Pane navigation**: `Prefix (Ctrl+B)` then `h/j/k/l` to navigate
- **Config reload**: `Prefix (Ctrl+B)` then `r` to reload configuration
- **Status bar**: Positioned at the top of the screen
- **Colors**: 256 colors and RGB support

### Git

- **Interactive setup**: Configure your name and email during installation
- **Useful aliases**:
  - `git st` → `git status`
  - `git co` → `git checkout`
  - `git br` → `git branch`
  - `git ci` → `git commit`
  - `git lg` → Pretty log with graph
- **Auto-coloring**: Enabled for all git commands
- **Default branch**: `main`
- **Reconfigurable**: Run `./setup-git.sh` anytime to update your configuration

### Essential Tools

Optional installation of frequently used tools:
- **neovim**: Modern, extensible text editor
- **tldr**: Simplified man pages with practical examples (auto-updated after install)
- **jq**: Command-line JSON processor
- **curl**: Tool for transferring data with URLs
- **xclip**: X clipboard manager (auto-copies SSH public key when generated)

These tools are offered during installation - accept to install all, decline to skip.

### SSH Key

Automatic SSH key generation for seamless GitHub/GitLab access:
- **Type**: ed25519 (modern, secure, compact)
- **Auto-detection**: Checks if key already exists
- **Email validation**: Regex validation like Git config
- **Passphrase**: Optional (press Enter to skip)
- **Email integration**: Uses Git email if configured
- **Agent setup**: Automatically adds key to ssh-agent (prompts for passphrase if set)
- **Clipboard integration**: Auto-copies public key if xclip is installed
- **GitHub ready**: Displays public key with instructions to add on GitHub
- **Backup**: Existing keys are backed up before regeneration

After generation, the public key is displayed in the final message. If xclip is installed, it's automatically copied to your clipboard. Simply paste it to GitHub Settings → SSH Keys.

To regenerate or create a new key:
```bash
./setup-ssh.sh
```

## 🎨 Customization

### Modifying Configurations

Edit files directly in your dotfiles folder:

```bash
# Modify Zsh config
vim ~/dotfiles/zsh/.zshrc

# Modify Tmux config
vim ~/dotfiles/tmux/.tmux.conf

# Modify Kitty config
vim ~/dotfiles/kitty/.config/kitty/kitty.conf
```

Changes are **immediately active** thanks to symlinks!

### Adding Zsh Plugins

Edit `zsh/.zshrc` and add:

```bash
zinit light user-name/plugin-name
```

Then reload:
```bash
source ~/.zshrc
```

### Adding Tmux Plugins

Edit `tmux/.tmux.conf` and add:

```bash
set -g @plugin 'user-name/plugin-name'
```

Then rerun the bootstrap script to install the new plugins:
```bash
./bootstrap.sh
```

Or manually in Tmux:
- `Prefix (Ctrl+B)` then `I` (capital) to install

### Customizing Kitty

Edit `kitty/.config/kitty/kitty.conf`:

```bash
# Change font
font_family MonoLisa

# Change size
font_size 14.0

# Change theme (create a new .conf file)
include my-theme.conf
```

### Customizing Git

To reconfigure Git (change name, email):

```bash
./setup-git.sh
```

To add more aliases or settings, edit `git/.gitconfig` template:

```bash
vim ~/dotfiles/git/.gitconfig
```

Then regenerate your config:

```bash
./setup-git.sh
```

## 🗑️ Uninstallation

```bash
# 1. Remove symlinks
rm ~/.zshrc ~/.tmux.conf ~/.gitconfig
rm -rf ~/.config/kitty

# 2. Restore backups (if needed)
# All backups are stored in ~/.dotfiles-backups/
ls ~/.dotfiles-backups/  # List available backups
cp ~/.dotfiles-backups/zshrc.YYYYMMDD_HHMMSS ~/.zshrc
cp ~/.dotfiles-backups/tmux.conf.YYYYMMDD_HHMMSS ~/.tmux.conf
cp ~/.dotfiles-backups/gitconfig.YYYYMMDD_HHMMSS ~/.gitconfig
cp -r ~/.dotfiles-backups/kitty.YYYYMMDD_HHMMSS ~/.config/kitty

# 3. Remove plugin managers (optional)
rm -rf ~/.local/share/zinit
rm -rf ~/.tmux/plugins

# 4. Remove backups directory (optional)
rm -rf ~/.dotfiles-backups

# 5. Uninstall programs (optional)
# Fedora
sudo dnf remove kitty cascadia-code-fonts

# Debian
sudo apt remove kitty fonts-cascadia-code

# 6. Revert to default shell (optional)
chsh -s /bin/bash
```

## 🔧 Troubleshooting

### Tmux Plugins Don't Display

Tmux plugins are automatically installed by the bootstrap script. If they don't appear:

```bash
# Rerun the bootstrap script
./bootstrap.sh

# Or manually install:
~/.tmux/plugins/tpm/bin/install_plugins

# Or in Tmux, press:
Prefix (Ctrl+B) then I (capital)
```

### Starship Doesn't Display

```bash
# Verify that Zinit installed starship
ls ~/.local/share/zinit/plugins/starship---starship/

# Reload zsh
exec zsh
```

### Zsh Plugins Don't Work

```bash
# Update Zinit
zinit update --all

# Clear cache
zinit cclear
```

### "stow: conflicts" Error

This means a file already exists and is not a symlink.

```bash
# The script normally created a backup
# Remove the conflicting file:
rm ~/.zshrc  # or ~/.tmux.conf

# Rerun the script
./bootstrap.sh
```

### Script Can't Find Config Files

Make sure to run the script from the dotfiles folder:

```bash
cd ~/dotfiles  # or the path where you cloned
./bootstrap.sh
```

The script automatically detects its location and finds configs.

### Kitty Doesn't Use the Right Font

```bash
# Verify CascadiaCode is installed
fc-list | grep -i cascadia

# If missing, install manually:
# Fedora
sudo dnf install cascadia-code-fonts

# Debian
sudo apt install fonts-cascadia-code

# Refresh cache
fc-cache -f
```

### Default Terminal Isn't Zsh

If you're not using Kitty, some terminals have their own shell configuration:

**GNOME Terminal**:
- Edit → Preferences → Profile → Command
- Check "Run a login shell"

**Konsole**:
- Settings → Edit Current Profile → General
- Command: `/bin/zsh`

**Alternative**: Run `zsh` manually or add `exec zsh` to your `.bashrc`

## 📝 Notes

- Configurations are version controlled with Git for easy sharing between machines
- Uses Stow for clean symlink management
- Compatible with Fedora and Debian/Ubuntu
- The script is idempotent: can be safely rerun for updates
- The script auto-detects its location: you can clone anywhere
- Kitty and CascadiaCode are optional but highly recommended for full experience

## 🔄 Synchronization Between Machines

To use the same config on multiple machines:

```bash
# On machine 1 (initial creation)
cd ~/dotfiles
git init
git add .
git commit -m "Initial dotfiles"
git remote add origin <your-repo-url>
git push -u origin main

# On machine 2 (new installation)
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh

# Regular updates on any machine
cd ~/dotfiles
git pull
./bootstrap.sh  # Apply changes
```

## 🎨 Dracula Theme

All tools use the Dracula theme for visual consistency:
- **Kitty**: Complete palette (foreground, background, 16 colors)
- **Tmux**: Widgets and status bar
- **Starship**: Automatically adapts to terminal colors

**Dracula Palette**:
- Background: `#282a36`
- Foreground: `#f8f8f2`
- Selection: `#44475a`
- Comment: `#6272a4`
- Cyan: `#8be9fd`
- Green: `#50fa7b`
- Orange: `#ffb86c`
- Pink: `#ff79c6`
- Purple: `#bd93f9`
- Red: `#ff5555`
- Yellow: `#f1fa8c`

## 📄 License

Personal configuration - Free to use and modify

## 👤 Author

**R4yL**
- Creation date: 16/06/24
- Version: 2.0
- Last update: 25/12/24

---

**Happy shelling! 🚀**
