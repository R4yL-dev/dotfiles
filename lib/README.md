# Dotfiles Shared Library

This directory contains shared code used across all dotfiles installation scripts.

## Overview

The library eliminates code duplication and ensures consistency across:
- `bootstrap.sh` - Main installation orchestrator
- `setup-git.sh` - Git configuration
- `setup-ssh.sh` - SSH key generation

## Files

### `common.sh`
Core helper functions and UI constants.

**Usage:**
```bash
source "$SCRIPT_DIR/lib/common.sh"
```

**Colors:**
- `RED` - Red color code
- `GREEN` - Green color code
- `YELLOW` - Yellow color code
- `BLUE` - Blue color code
- `NC` - No color (reset)

**Symbols:**
- `CHECK` - Success symbol (✓)
- `CROSS` - Error symbol (✗)
- `INFO` - Info symbol (ℹ)
- `WARN` - Warning symbol (⚠)
- `CIRCLE` - Skip symbol (⊙)

**Functions:**

#### `print_header(message)`
Print a formatted section header.
```bash
print_header "Installing Dependencies"
```

#### `print_success(message)`
Print a success message with green checkmark.
```bash
print_success "Installation complete"
```

#### `print_error(message)`
Print an error message with red cross.
```bash
print_error "Failed to install package"
```

#### `print_info(message)`
Print an informational message with blue icon.
```bash
print_info "Downloading files..."
```

#### `print_warn(message)`
Print a warning message with yellow icon.
```bash
print_warn "This may take a while"
```

#### `print_skip(message)`
Print a skip message with yellow circle.
```bash
print_skip "Package already installed"
```

#### `run_cmd(command...)`
Run a command, respecting the `$VERBOSE` flag.
```bash
run_cmd apt install package
```
- If `VERBOSE=true`: Shows command output
- If `VERBOSE=false`: Suppresses output

#### `backup_file(file, [move_instead_of_copy])`
Backup a file or directory to `~/.dotfiles-backups/` with timestamp.
```bash
# Copy backup (default)
backup_path=$(backup_file "$HOME/.zshrc")

# Move backup
backup_path=$(backup_file "$HOME/.config/kitty" true)
```

**Returns:** Path to the backup file

---

### `validation.sh`
Input validation functions.

**Usage:**
```bash
source "$SCRIPT_DIR/lib/validation.sh"
```

**Functions:**

#### `validate_email(email, param_name)`
Validate email format using regex pattern.
```bash
if validate_email "user@example.com" "email parameter"; then
    echo "Valid email"
else
    echo "Invalid email"
    exit 1
fi
```

**Returns:**
- `0` if valid
- `1` if invalid (also prints error message)

---

### `args.sh`
Common argument parsing utilities.

**Usage:**
```bash
source "$SCRIPT_DIR/lib/args.sh"
```

**Functions:**

#### `init_common_args()`
Initialize common argument variables to their default values.
```bash
init_common_args
# Sets: VERBOSE=false, UNATTENDED=false, SKIP_CONFIRMATION=false
```

#### `parse_common_arg(arg)`
Parse a single common argument.
```bash
while [[ $# -gt 0 ]]; do
    if parse_common_arg "$1"; then
        shift
    else
        echo "Unknown option: $1"
        exit 1
    fi
done
```

**Recognized arguments:**
- `-v` or `--verbose` - Enable verbose output
- `--unattended` - Non-interactive mode
- `--skip-confirmation` - Skip confirmation prompts

**Returns:**
- `0` if argument was recognized and handled
- `1` if argument is unknown (caller should handle)

---

## Usage Example

Complete example of using all libraries:

```bash
#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries with error handling
if ! source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null; then
    echo "Error: Failed to load common library"
    exit 1
fi

if ! source "$SCRIPT_DIR/lib/validation.sh" 2>/dev/null; then
    echo "Error: Failed to load validation library"
    exit 1
fi

if ! source "$SCRIPT_DIR/lib/args.sh" 2>/dev/null; then
    echo "Error: Failed to load args library"
    exit 1
fi

# Parse arguments
init_common_args
while [[ $# -gt 0 ]]; do
    if parse_common_arg "$1"; then
        shift
    else
        echo "Unknown option: $1"
        exit 1
    fi
done

# Use helper functions
print_header "My Script"
print_info "Starting process..."

# Validate input
if ! validate_email "$USER_EMAIL" "user email"; then
    exit 1
fi

# Run commands
if run_cmd some-command; then
    print_success "Command succeeded"
else
    print_error "Command failed"
fi
```

---

## Error Handling

All library files should be sourced with error handling:

```bash
if ! source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null; then
    echo "Error: Failed to load common library"
    echo "Make sure you're running from the dotfiles directory"
    exit 1
fi
```

This ensures clear error messages if:
- Library files are missing
- Permission issues occur
- Script is run from wrong directory

---

## Maintenance

When modifying library functions:

1. **Update all usage locations** - Functions are used in multiple scripts
2. **Test thoroughly** - Changes affect all scripts
3. **Maintain backwards compatibility** - Don't break existing callers
4. **Update this documentation** - Keep README.md in sync

---

## Contributing

When adding new shared functionality:

1. Determine which library file it belongs in:
   - `common.sh` - UI helpers and utilities
   - `validation.sh` - Input validation
   - `args.sh` - Argument parsing

2. Add comprehensive documentation in this README

3. Update all scripts that could benefit from the new function

4. Test in all three scripts (bootstrap.sh, setup-git.sh, setup-ssh.sh)
