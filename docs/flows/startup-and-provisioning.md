# Startup and Provisioning Flow

This document describes the complete execution flow of `run.sh` from entry
point to completion.

## Overview

The main entry point `run.sh` orchestrates the entire system provisioning
process through 5 sequential phases.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        run.sh Entry Point                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 0: Pre-flight Checks                   │
│  • Validate repository structure                                │
│  • Check required tools (bash, git, curl, jq)                   │
│  • Detect platform (OS, distro, arch)                           │
│  • Detect privileges (root, sudo, su)                           │
│  • Load configuration                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 1: Foundation Layer                    │
│  • Source common modules                                        │
│    - common.sh (execution, logging, utils)                      │
│    - filesystem.sh (path constants, file ops)                   │
│    - system-info.sh (platform detection)                        │
│    - config.sh (config file manipulation)                       │
│    - package-management.sh (package abstraction)                │
│    - service-management.sh (service abstraction)                │
│    - apps.sh (application management)                           │
│    - github.sh (GitHub integration)                             │
│  • Export all constants and functions                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 2: System Configuration                │
│  • configure-repositories.sh                                    │
│    - Add package repositories                                   │
│    - Update package databases                                   │
│  • install-packages.sh                                          │
│    - Install base packages                                      │
│    - Install development packages                               │
│    - Install desktop packages                                   │
│    - Install gaming packages                                    │
│    - Install AUR/Flatpak packages                               │
│  • configure-system.sh                                          │
│    - Configure locale, time, GRUB                               │
│    - Configure kernel parameters                                │
│    - Configure systemd                                          │
│  • configure-services-system.sh                                 │
│    - Enable/start system services                               │
│  • configure-hardware-integration.sh                            │
│    - GPU, audio, power, thermal                                 │
│  • update-grub.sh                                               │
│    - Update GRUB configuration                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 3: User Configuration                  │
│  • configure-default-apps.sh                                    │
│    - Set default applications                                   │
│    - Configure MIME associations                                │
│  • configure-launchers.sh                                       │
│    - Create desktop launchers                                   │
│  • configure-autostart-apps.sh                                  │
│    - Configure autostart entries                                │
│  • update-rcs.sh                                                │
│    - Deploy RC files (bashrc, vimrc, etc.)                      │
│  • update-resources.sh                                          │
│    - Deploy resources (Firefox, themes, etc.)                   │
│  • update-profiles.sh                                           │
│    - Deploy profile scripts                                     │
│  • configure-git.sh                                             │
│    - Configure Git, SSH, GPG                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Phase 4: Post-Setup                          │
│  • clean-packages.sh                                            │
│    - Clean package caches                                       │
│  • clean-files.sh                                               │
│    - Clean temporary files                                      │
│  • verify-setup.sh                                              │
│    - Verify critical configurations                             │
│  • generate-summary.sh                                          │
│    - Generate setup summary                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Completion                               │
│  • Log success message                                          │
│  • Display summary                                              │
│  • Exit with status                                             │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 0: Pre-flight Checks

### Script: `run.sh` (lines 1-100)

```bash
#!/bin/bash
set -euo pipefail

# Repository root
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${REPO_DIR}/scripts/common/config.sh"

# Validate repository
validate_repository() {
    log_section "Pre-flight Checks"

    # Check required directories
    for dir in scripts common data rc profiles resources; do
        assert_directory "${REPO_DIR}/${dir}" "Missing directory: ${dir}"
    done

    # Check required tools
    for tool in bash git curl jq; do
        assert_command "${tool}" "Required tool not found: ${tool}"
    done

    # Detect platform
    source "${REPO_DIR}/scripts/common/system-info.sh"
    detect_platform

    # Detect privileges
    detect_privileges

    log_success "Pre-flight checks passed"
}
```

### Platform Detection

```bash
# scripts/common/system-info.sh

detect_platform() {
    detect_os
    detect_distro
    detect_distro_family
    detect_arch
    detect_device_model
    detect_chassis_type
    detect_gpu_family
    detect_has_gui
    detect_desktop_environment
    detect_display_server
    detect_is_battery_device
    detect_is_powerful_pc
    detect_is_development_device
    detect_is_gaming_device
    detect_is_general_purpose_device
    detect_has_su_privileges
}
```

### Privilege Detection

```bash
detect_privileges() {
    if [ "$(id -u)" -eq 0 ]; then
        HAS_SU_PRIVILEGES="true"
        RUN_AS_SU="true"
    elif command_exists sudo; then
        HAS_SU_PRIVILEGES="true"
        RUN_AS_SU="sudo"
    elif command_exists su; then
        HAS_SU_PRIVILEGES="true"
        RUN_AS_SU="su -c"
    else
        HAS_SU_PRIVILEGES="false"
        RUN_AS_SU=""
    fi
}
```

## Phase 1: Foundation Layer

### Script: `run.sh` (lines 100-150)

```bash
load_foundation() {
    log_section "Phase 1: Foundation Layer"

    # Source all common modules
    local modules=(
        "common.sh"
        "filesystem.sh"
        "system-info.sh"
        "config.sh"
        "package-management.sh"
        "service-management.sh"
        "apps.sh"
        "github.sh"
    )

    for module in "${modules[@]}"; do
        log_info "Loading ${module}..."
        source "${REPO_DIR}/scripts/common/${module}"
    done

    # Initialize package manager
    detect_package_manager

    # Initialize service manager
    detect_service_manager

    log_success "Foundation layer loaded"
}
```

## Phase 2: System Configuration

### Script: `run.sh` (lines 150-250)

```bash
run_system_configuration() {
    log_section "Phase 2: System Configuration"

    local scripts=(
        "configure-repositories.sh"
        "install-packages.sh"
        "configure-system.sh"
        "configure-services-system.sh"
        "configure-hardware-integration.sh"
        "update-grub.sh"
    )

    for script in "${scripts[@]}"; do
        log_subsection "Running ${script}"
        run_script "${REPO_DIR}/scripts/${script}"
    done

    log_success "System configuration complete"
}
```

### configure-repositories.sh

```bash
# Add package repositories
# Update package databases
# Configure AUR helper (paru/yay)
# Configure Flatpak remotes
```

### install-packages.sh

```bash
# Install packages by category:
# - base: git, vim, curl, wget, htop, tree, rsync, unzip, zip, p7zip
# - development: build-essential, cmake, gcc, g++, make, pkg-config
# - desktop: lxde, lxpanel, pcmanfm, openbox, network-manager
# - gaming: steam, lutris, wine, gamemode, gamescope
# - media: vlc, mpv, gimp, libreoffice
# - security: keepassxc, bitwarden, signal-desktop
```

### configure-system.sh

```bash
# Configure locale (en_US.UTF-8)
# Configure time (timezone, NTP)
# Configure GRUB (kernel parameters, timeout)
# Configure kernel (sysctl, modprobe)
# Configure systemd (journald, logind, resolved)
# Configure users and groups
```

### configure-services-system.sh

```bash
# Enable/start system services:
# - NetworkManager
# - lightdm
# - bluetooth
# - cups
# - pipewire
# - fstrim.timer
# - logrotate.timer
# - reflector.timer
```

### configure-hardware-integration.sh

```bash
# GPU configuration (Intel/AMD/NVIDIA/Broadcom)
# Power management (TLP, cpupower)
# Audio (PulseAudio/PipeWire)
# Input devices (keyboard, touchpad)
# Thermal management (thermald)
# Device-specific (Argon ONE UP)
```

### update-grub.sh

```bash
# Update GRUB configuration
# Apply kernel parameters
# Configure multi-boot entries
```

## Phase 3: User Configuration

### Script: `run.sh` (lines 250-350)

```bash
run_user_configuration() {
    log_section "Phase 3: User Configuration"

    local scripts=(
        "configure-default-apps.sh"
        "configure-launchers.sh"
        "configure-autostart-apps.sh"
        "update-rcs.sh"
        "update-resources.sh"
        "update-profiles.sh"
        "configure-git.sh"
    )

    for script in "${scripts[@]}"; do
        log_subsection "Running ${script}"
        run_script "${REPO_DIR}/scripts/${script}"
    done

    log_success "User configuration complete"
}
```

### configure-default-apps.sh

```bash
# Set default applications for MIME types
# Configure Firefox preferences
# Configure Flatpak permissions
# Configure GNOME app permissions
```

### configure-launchers.sh

```bash
# Create desktop launchers for applications
# Modify existing .desktop files
# Create custom launchers
```

### configure-autostart-apps.sh

```bash
# Configure user autostart entries
# Configure system autostart entries
# Manage autostart conditions
```

### update-rcs.sh

```bash
# Deploy RC files:
# - shell/bashrc, bash_profile, aliases, functions, prompt
# - vim/vimrc
# - git/gitconfig
# - inputrc
# - nanorc
# - profile
# - gimp/gimprc, sessionrc, toolrc
# - grub/25_windows, 29_android, etc.
```

### update-resources.sh

```bash
# Deploy resources:
# - Firefox: userChrome.css, containers.json, icons
# - neofetch: ascii art, configs
# - fastfetch: logos, configs
# - lxpanel: logout, panel configs
# - plank: theme, autostart
# - pcmanfm: desktop entries
# - templates: doc, file, odt
# - udev: rules
```

### update-profiles.sh

```bash
# Deploy profile scripts:
# - cmake.sh
# - dotnet.sh
```

### configure-git.sh

```bash
# Configure Git user
# Configure Git editor
# Configure Git aliases
# Setup SSH key
# Setup GPG key
# Configure GitHub CLI
```

## Phase 4: Post-Setup

### Script: `run.sh` (lines 350-400)

```bash
run_post_setup() {
    log_section "Phase 4: Post-Setup"

    local scripts=(
        "clean-packages.sh"
        "clean-files.sh"
        "verify-setup.sh"
        "generate-summary.sh"
    )

    for script in "${scripts[@]}"; do
        log_subsection "Running ${script}"
        run_script "${REPO_DIR}/scripts/${script}"
    done

    log_success "Post-setup complete"
}
```

### clean-packages.sh

```bash
# Clean package caches
# Remove orphaned packages
# Clean AUR build directories
```

### clean-files.sh

```bash
# Clean temporary files
# Clean build directories
# Clean download caches
```

### verify-setup.sh

```bash
# Verify critical configurations:
# - Package installation
# - Service status
# - Configuration files
# - User environment
```

### generate-summary.sh

```bash
# Generate setup summary:
# - Installed packages
# - Enabled services
# - Applied configurations
# - Next steps
```

## Error Handling

### Script Execution Wrapper

```bash
run_script() {
    local script="$1"

    if [ ! -f "${script}" ]; then
        log_error "Script not found: ${script}"
        return 1
    fi

    if [ ! -x "${script}" ]; then
        chmod +x "${script}"
    fi

    # Run with error handling
    if ! "${script}"; then
        log_error "Script failed: ${script}"
        return 1
    fi

    return 0
}
```

### Dry Run Mode

```bash
# Support for --dry-run flag
if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY RUN MODE - No changes will be made"
    RUN_AS_SU="echo [DRY RUN] sudo"
fi
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Pre-flight check failed |
| 3 | Foundation load failed |
| 4 | System configuration failed |
| 5 | User configuration failed |
| 6 | Post-setup failed |
| 124 | Timeout |
| 130 | Interrupted (SIGINT) |

## Logging

### Output Format

```
=== Phase 2: System Configuration ===
--- Running configure-repositories.sh ---
[INFO] Adding Arch Linux repositories
[SUCCESS] Repositories configured
--- Running install-packages.sh ---
[INFO] Installing base packages...
[SUCCESS] Base packages installed
...
=== Phase 3: User Configuration ===
...
=== Phase 4: Post-Setup ===
...
[SUCCESS] Setup complete!
```

## Performance

### Typical Execution Times

| Phase | Time (approx) |
|-------|---------------|
| Phase 0 | 2-5 seconds |
| Phase 1 | 1-2 seconds |
| Phase 2 | 5-30 minutes |
| Phase 3 | 1-5 minutes |
| Phase 4 | 30-60 seconds |
| **Total** | **7-36 minutes** |

### Optimisation Opportunities

1. Parallel package installation
2. Parallel script execution (where independent)
3. Cache package downloads
4. Skip already-configured items