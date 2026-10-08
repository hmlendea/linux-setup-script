# Integrations

This document describes external service integrations, platform integrations,
and third-party tool integrations in the linux-setup-script repository.

## Overview

The repository integrates with various external services and platforms to
provide a comprehensive system provisioning experience.

## Platform Integrations

### 1. Linux Distributions

| Distribution | Package Manager | Init System | Status |
|--------------|-----------------|-------------|--------|
| Arch Linux | pacman/paru/yay | systemd | Primary |
| Debian | apt | systemd | Supported |
| Ubuntu | apt | systemd | Supported |
| Alpine Linux | apk | OpenRC | Supported |
| Android/Termux | pkg | N/A | Supported |
| SteamOS | pacman | systemd | Supported |
| LineageOS | pkg | init | Supported |
| WSL | apt | systemd | Supported |

### 2. Desktop Environments

| Desktop Environment | Display Server | Status |
|---------------------|----------------|--------|
| GNOME | Wayland/X11 | Primary |
| KDE Plasma | Wayland/X11 | Supported |
| XFCE | X11 | Supported |
| LXDE | X11 | Supported |
| MATE | X11 | Supported |
| i3/Sway | X11/Wayland | Supported |
| Hyprland | Wayland | Supported |

### 3. Display Servers

| Display Server | Status |
|----------------|--------|
| X11 | Supported |
| Wayland | Supported |
| TTY | Supported |

## External Service Integrations

### 1. GitHub

**Purpose**: Repository management, GitHub CLI authentication, GPG/SSH key deployment

**Integration Points**:
- `scripts/common/github.sh` — GitHub API wrapper
- `scripts/git/setup-ssh-key.sh` — SSH key generation and GitHub deployment
- `scripts/git/setup-gpg-key.sh` — GPG key generation and GitHub deployment
- `configure-repositories.sh` — Repository cloning and syncing

**Authentication**: GitHub CLI (`gh`) with token from `GITHUB_TOKEN` environment variable

**Operations**:
- Repository creation/cloning/forking
- Pull request creation
- SSH/GPG key management
- Repository syncing

### 2. GitLab

**Purpose**: Repository management (alternative to GitHub)

**Integration Points**:
- SSH key deployment to GitLab
- Repository cloning and syncing

**Authentication**: SSH keys

### 3. AUR (Arch User Repository)

**Purpose**: Access to community-maintained packages

**Integration Points**:
- `scripts/common/package-management.sh` — AUR helper detection (paru, yay)
- `install-packages.sh` — AUR package installation

**Helpers Supported**: paru, yay

### 4. Flatpak

**Purpose**: Sandboxed application distribution

**Integration Points**:
- `scripts/common/apps.sh` — Flatpak installation
- `install-packages.sh` — Flatpak application installation
- Flathub repository (default)

### 5. Snap

**Purpose**: Sandboxed application distribution (Ubuntu)

**Integration Points**:
- `scripts/common/apps.sh` — Snap installation
- `install-packages.sh` — Snap application installation

### 6. AppImage

**Purpose**: Portable application distribution

**Integration Points**:
- `scripts/common/apps.sh` — AppImage download and installation

## Hardware Integrations

### 1. GPU Vendors

| Vendor | Kernel Module | Configuration |
|--------|---------------|---------------|
| Intel | i915 | enable_guc, enable_fbc, enable_psr |
| AMD | amdgpu | ppfeaturemask, si_support, cik_support |
| NVIDIA | nvidia | NVreg_UsePageAttributeTable, NVreg_EnableMSI |

### 2. Audio Systems

| System | Configuration |
|--------|---------------|
| PulseAudio | module-udev-detect tsched=0 |
| PipeWire | pipewire, pipewire-pulse, pipewire-jack services |
| ALSA | asound.conf |

### 3. Input Devices

| Device Type | Configuration |
|-------------|---------------|
| Keyboard | X11 keyboard layout, vconsole.conf |
| Mouse | libinput configuration |
| Touchpad | libinput gestures, tap-to-click |
| Gamepad | SDL gamecontrollerdb |

### 4. Power Management

| Tool | Configuration |
|------|---------------|
| TLP | CPU scaling, battery thresholds |
| systemd | logind.conf, sleep.conf |
| CPU frequency | cpufrequtils, intel_pstate |

### 5. Thermal Management

| Tool | Configuration |
|------|---------------|
| thermald | Thermal zones, trip points |
| fancontrol | Fan curves |
| lm-sensors | Sensor detection |

## Development Tool Integrations

### 1. Language Runtimes

| Language | Installation Method | Version Management |
|----------|---------------------|-------------------|
| Python | Package manager + pyenv | pyenv |
| Node.js | Package manager + nvm | nvm |
| Rust | rustup | rustup |
| Go | Package manager + gvm | gvm |
| Java | Package manager + sdkman | sdkman |
| .NET | Package manager | dotnet CLI |

### 2. Container Tools

| Tool | Installation | Configuration |
|------|--------------|---------------|
| Docker | Package manager | daemon.json, user group |
| Podman | Package manager | containers.conf |
| Buildah | Package manager | buildah.conf |
| Kubernetes | kubectl, helm, kind | kubeconfig |

### 3. IDE/Editor Integrations

| Editor | Configuration |
|--------|---------------|
| VS Code | settings.json, extensions, keybindings |
| Vim/Neovim | vimrc, plugins, LSP |
| Emacs | init.el, packages |

## Cloud/Remote Integrations

### 1. SSH

**Purpose**: Remote access, Git over SSH

**Configuration**:
- SSH key generation (ed25519)
- SSH agent integration
- SSH config for hosts
- Known hosts management

### 2. VPN

**Purpose**: Secure network access

**Supported**:
- WireGuard
- OpenVPN
- Tailscale

### 3. Cloud CLIs

| Provider | CLI | Configuration |
|----------|-----|---------------|
| AWS | awscli | ~/.aws/config, credentials |
| GCP | gcloud | gcloud config |
| Azure | az | az config |
| DigitalOcean | doctl | doctl auth |

## Gaming Integrations

### 1. Steam

**Purpose**: Game distribution and Proton compatibility

**Configuration**:
- Steam native runtime
- Proton-GE custom builds
- Steam Input configuration
- Steam Cloud sync

### 2. Lutris

**Purpose**: Game manager for non-Steam games

**Configuration**:
- Wine runners
- DXVK/VKD3D versions
- Game-specific scripts

### 3. Heroic Games Launcher

**Purpose**: Epic Games/GOG game manager

**Configuration**:
- Wine runners
- Legendary backend

## Integration Invariants

1. **Platform detection first** — All integrations conditional on `system-info.sh` exports
2. **Graceful degradation** — Missing tools don't break the setup
3. **Credential isolation** — Secrets from environment, never hardcoded
4. **Idempotent operations** — Safe to re-run integrations
5. **Privilege separation** — System integrations via `run_as_su`
6. **Single source of truth** — Each integration configured in one place

## Error Handling

| Integration | Failure Mode | Handling |
|-------------|--------------|----------|
| GitHub CLI | Not installed | Skip GitHub integration |
| AUR helper | Not installed | Skip AUR packages |
| Flatpak | Not installed | Skip Flatpak apps |
| Docker | Not installed | Skip container setup |
| GPU driver | Not loaded | Log warning, continue |

## Security Considerations

- **Token handling** — All tokens from environment variables
- **Key management** — SSH/GPG keys generated locally, never transmitted
- **Repository trust** — Only trusted repositories added
- **Package verification** — Package signatures verified by package managers
- **Network access** — Only required network connections made

## Future Integrations

1. **1Password CLI** — Secret management
2. **Bitwarden CLI** — Secret management
3. **Vault** — Secret management
4. **Ansible** — Configuration management
5. **Terraform** — Infrastructure as code
6. **Nix** — Reproducible builds
7. **Homebrew** — macOS package management