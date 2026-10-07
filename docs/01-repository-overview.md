# 01 — Repository Overview

## Purpose

This repository is a **personal Linux system provisioning and configuration
framework**. It automates the complete setup of a Linux machine (or Android
device via Termux) from a fresh install to a fully configured development
environment, including:

- Package repository configuration and system updates
- Package installation, removal, and cleanup (native, Flatpak, AUR, Cargo)
- System configuration (kernel parameters, sysctl, modprobe, systemd)
- User environment configuration (shell, XDG directories, dotfiles)
- Desktop environment customisation (themes, fonts, launchers, autostart)
- Application permissions (Flatpak, GNOME)
- Hardware-specific integrations (Argon ONE UP, GPU, laptop power management)
- Boot configuration (GRUB multi-boot entries for Windows, Android, Bliss OS)
- Development tooling (Git, SSH, GPG, .NET, CMake, VS Code)

## Scope

The repository **owns**:

- All system-level configuration files under `/etc` (via `update-rcs.sh`,
  `configure-system.sh`, `configure-locale.sh`, `configure-time.sh`)
- All user-level configuration files under `$HOME` and `$XDG_CONFIG_HOME`
  (via `update-rcs.sh`, `update-resources.sh`)
- Package selection and management across all supported package managers
- Desktop environment theming and application launcher customisation
- GRUB boot entries for multi-boot scenarios
- SSH/GPG key generation and Git configuration

The repository **does not own**:

- Application source code (it installs and configures third-party software)
- Hardware firmware (except Argon ONE UP fan controller via external repo)
- Network infrastructure (configures local NetworkManager/netctl only)
- Container orchestration (installs Docker but does not manage containers)
- Secret management (generates SSH/GPG keys but does not store secrets)

## Supported Platforms

| Platform | Family | Architectures | Notes |
|----------|--------|---------------|-------|
| Arch Linux | Arch | x86_64, aarch64, armv7l | Primary target; uses pacman/paru/yay |
| Debian | Debian | x86_64, aarch64 | Uses apt |
| Ubuntu | Ubuntu | x86_64, aarch64 | Uses apt |
| Alpine Linux | Alpine | x86_64, aarch64 | Uses apk |
| Android (Termux) | Android | aarch64, armv7l | Uses pkg; limited GUI support |
| SteamOS | Arch | x86_64 | Special handling (no AUR helper) |
| LineageOS | Android | aarch64 | Mobile device support |
| WSL | Debian/Ubuntu | x86_64 | Early exit for most system config |

## High-Level Architecture

```
run.sh (entry point)
    │
    ├── Environment Detection (system-info.sh)
    │       ├── Device model, chassis type, GPU, display server, DE
    │       ├── Screen resolution, DPI, battery status
    │       └── Distro family, OS, architecture
    │
    ├── Privilege Model
    │       ├── run_script (user context)
    │       └── run_script_as_su (root context via sudo/su)
    │
    ├── Phase 1: Repository & Package Management
    │       ├── configure-repositories.sh (add repos, keys)
    │       ├── update-repositories.sh (refresh package databases)
    │       ├── uninstall-packages.sh (remove unwanted packages)
    │       ├── update-packages.sh (system, flatpak, cargo, gnome-extensions)
    │       ├── install-packages.sh (install selected packages)
    │       ├── uninstall-packages.sh (second pass for conflicts)
    │       └── clean-packages.sh (cache cleanup)
    │
    ├── Phase 2: Configuration Deployment
    │       ├── update-rcs.sh (shell, git, ssh, app configs)
    │       ├── update-profiles.sh (system profile.d scripts)
    │       └── update-resources.sh (firefox, git hooks, lxpanel, plank, neofetch, udev)
    │
    ├── Phase 3: System Configuration
    │       ├── configure-system.sh (kernel, sysctl, modprobe, fonts, themes, shell)
    │       ├── configure-launchers.sh (desktop entry modifications)
    │       ├── configure-autostart-apps.sh (user autostart .desktop files)
    │       ├── configure-default-apps.sh (mimetype associations)
    │       ├── configure-permissions.sh (Flatpak/GNOME app permissions)
    │       ├── configure-directories.sh (XDG dirs, hidden files, symlinks)
    │       ├── configure-locale.sh (locale.gen, locale.conf, vconsole, keymaps)
    │       ├── configure-time.sh (timezone, RTC sync)
    │       ├── configure-services-user.sh (mask/disable user services)
    │       ├── configure-services-system.sh (enable/disable system services)
    │       ├── configure-hardware-integration.sh (device-specific setup)
    │       └── update-grub.sh (GRUB config regeneration)
    │
    └── Git Setup (optional, separate scripts)
            ├── setup-gpg-key.sh
            └── setup-ssh-key.sh
```

## Key Design Principles

1. **Idempotency** — Scripts can be run multiple times safely; they use
   `update_file_if_distinct`, `does_bin_exist`, `is_package_installed` checks
2. **Privilege separation** — Clear distinction between user and root operations
3. **Platform abstraction** — `DISTRO_FAMILY` and `OS` variables drive conditional logic
4. **Declarative configuration** — Target state described in RC files and resources
5. **Hardware awareness** — Configuration adapts to chassis, GPU, screen, battery
6. **Desktop-environment awareness** — GNOME, KDE, MATE, LXDE, Phosh handled differently