# Package Management Flow

This document describes the package management abstraction layer and the
flow of package installation across supported platforms.

## Overview

The package management system provides a unified interface for installing,
removing, and querying packages across multiple package managers and
platforms.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Package Management Flow                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Detect Package Manager                       │
│  • pacman (Arch Linux)                                          │
│  • apt (Debian, Ubuntu)                                         │
│  • apk (Alpine)                                                 │
│  • pkg (Termux)                                                 │
│  • paru/yay (AUR helper)                                        │
│  • flatpak (Flatpak)                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Load Package Lists                           │
│  • data/packages/base.txt                                       │
│  • data/packages/development.txt                                │
│  • data/packages/desktop.txt                                    │
│  • data/packages/gaming.txt                                     │
│  • data/packages/media.txt                                      │
│  • data/packages/security.txt                                   │
│  • data/packages/network.txt                                    │
│  • data/packages/fonts.txt                                      │
│  • data/packages/themes.txt                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Install Packages                             │
│  • Check if already installed (idempotency)                     │
│  • Install via detected package manager                         │
│  • Handle AUR packages (paru/yay)                               │
│  • Handle Flatpak packages                                      │
│  • Handle Termux packages                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Post-Install                                 │
│  • Clean package caches                                         │
│  • Remove orphaned packages                                     │
│  • Log installed packages                                       │
└─────────────────────────────────────────────────────────────────┘
```

## Package Manager Detection

### Script: `scripts/common/package-management.sh`

```bash
detect_package_manager() {
    if command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        PACKAGE_MANAGER_INSTALL="pacman -S --noconfirm"
        PACKAGE_MANAGER_REMOVE="pacman -Rns"
        PACKAGE_MANAGER_UPDATE="pacman -Syu"
        PACKAGE_MANAGER_SEARCH="pacman -Ss"
        PACKAGE_MANAGER_LIST="pacman -Q"
    elif command_exists apt; then
        PACKAGE_MANAGER="apt"
        PACKAGE_MANAGER_INSTALL="apt install -y"
        PACKAGE_MANAGER_REMOVE="apt remove --purge -y"
        PACKAGE_MANAGER_UPDATE="apt update && apt upgrade -y"
        PACKAGE_MANAGER_SEARCH="apt search"
        PACKAGE_MANAGER_LIST="dpkg -l"
    elif command_exists apk; then
        PACKAGE_MANAGER="apk"
        PACKAGE_MANAGER_INSTALL="apk add"
        PACKAGE_MANAGER_REMOVE="apk del"
        PACKAGE_MANAGER_UPDATE="apk update && apk upgrade"
        PACKAGE_MANAGER_SEARCH="apk search"
        PACKAGE_MANAGER_LIST="apk list --installed"
    elif command_exists pkg; then
        PACKAGE_MANAGER="pkg"
        PACKAGE_MANAGER_INSTALL="pkg install -y"
        PACKAGE_MANAGER_REMOVE="pkg uninstall"
        PACKAGE_MANAGER_UPDATE="pkg update && pkg upgrade"
        PACKAGE_MANAGER_SEARCH="pkg search"
        PACKAGE_MANAGER_LIST="pkg list --installed"
    else
        log_error "No supported package manager found"
        return 1
    fi

    log_info "Detected package manager: ${PACKAGE_MANAGER}"
}
```

### AUR Helper Detection

```bash
detect_aur_helper() {
    if command_exists paru; then
        AUR_HELPER="paru"
    elif command_exists yay; then
        AUR_HELPER="yay"
    else
        AUR_HELPER=""
    fi

    if [ -n "${AUR_HELPER}" ]; then
        log_info "Detected AUR helper: ${AUR_HELPER}"
    fi
}
```

## Package Installation Flow

### Script: `scripts/install-packages.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/package-management.sh"

# Package categories
declare -a PACKAGE_CATEGORIES=(
    "base"
    "development"
    "desktop"
    "gaming"
    "media"
    "security"
    "network"
    "fonts"
    "themes"
)

install_all_packages() {
    log_section "Installing Packages"

    for category in "${PACKAGE_CATEGORIES[@]}"; do
        log_subsection "Category: ${category}"
        install_packages_from_file "data/packages/${category}.txt"
    done

    # Install AUR packages
    install_aur_packages

    # Install Flatpak packages
    install_flatpak_packages

    log_success "All packages installed"
}
```

### Package Installation Function

```bash
install_packages_from_file() {
    local package_file="$1"
    local package_list

    if [ ! -f "${package_file}" ]; then
        log_warn "Package file not found: ${package_file}"
        return 0
    fi

    # Read packages, skipping comments and empty lines
    package_list=$(grep -v '^#' "${package_file}" | grep -v '^$')

    if [ -z "${package_list}" ]; then
        log_info "No packages to install from ${package_file}"
        return 0
    fi

    # Install each package
    while IFS= read -r package; do
        install_package "${package}"
    done <<< "${package_list}"
}
```

### Single Package Installation

```bash
install_package() {
    local package="$1"

    # Check if already installed (idempotency)
    if is_package_installed "${package}"; then
        log_info "Package already installed: ${package}"
        return 0
    fi

    log_info "Installing: ${package}"

    # Install via package manager
    if ! ${PACKAGE_MANAGER_INSTALL} "${package}"; then
        log_error "Failed to install: ${package}"
        return 1
    fi

    log_success "Installed: ${package}"
}
```

### Package Installation Check

```bash
is_package_installed() {
    local package="$1"

    case "${PACKAGE_MANAGER}" in
        pacman)
            pacman -Q "${package}" &>/dev/null
            ;;
        apt)
            dpkg -l "${package}" &>/dev/null
            ;;
        apk)
            apk info -e "${package}" &>/dev/null
            ;;
        pkg)
            pkg list --installed "${package}" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}
```

## AUR Package Installation

```bash
install_aur_packages() {
    local aur_file="data/packages/aur.txt"

    if [ -z "${AUR_HELPER}" ]; then
        log_warn "No AUR helper found, skipping AUR packages"
        return 0
    fi

    if [ ! -f "${aur_file}" ]; then
        log_warn "AUR package file not found: ${aur_file}"
        return 0
    fi

    log_subsection "Installing AUR Packages"

    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "${package}" =~ ^#.*$ ]] && continue
        [[ -z "${package}" ]] && continue

        if is_package_installed "${package}"; then
            log_info "AUR package already installed: ${package}"
            continue
        fi

        log_info "Installing AUR package: ${package}"
        ${AUR_HELPER} -S --noconfirm "${package}"
    done < "${aur_file}"
}
```

## Flatpak Package Installation

```bash
install_flatpak_packages() {
    local flatpak_file="data/packages/flatpak.txt"

    if ! command_exists flatpak; then
        log_warn "Flatpak not installed, skipping Flatpak packages"
        return 0
    fi

    if [ ! -f "${flatpak_file}" ]; then
        log_warn "Flatpak package file not found: ${flatpak_file}"
        return 0
    fi

    log_subsection "Installing Flatpak Packages"

    # Ensure Flathub is configured
    if ! flatpak remote-ls &>/dev/null; then
        log_info "Adding Flathub remote"
        flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi

    while IFS= read -r package; do
        # Skip comments and empty lines
        [[ "${package}" =~ ^#.*$ ]] && continue
        [[ -z "${package}" ]] && continue

        if flatpak list | grep -q "${package}"; then
            log_info "Flatpak package already installed: ${package}"
            continue
        fi

        log_info "Installing Flatpak package: ${package}"
        flatpak install -y flathub "${package}"
    done < "${flatpak_file}"
}
```

## Package Categories

### Base Packages

```
# data/packages/base.txt
git
vim
curl
wget
htop
tree
rsync
unzip
zip
p7zip
neofetch
fastfetch
```

### Development Packages

```
# data/packages/development.txt
base-devel
cmake
gcc
g++
make
pkg-config
python
python-pip
nodejs
npm
docker
docker-compose
```

### Desktop Packages

```
# data/packages/desktop.txt
lxde
lxpanel
pcmanfm
openbox
network-manager
network-manager-applet
```

### Gaming Packages

```
# data/packages/gaming.txt
steam
lutris
wine
gamemode
gamescope
mangoapp
```

### Media Packages

```
# data/packages/media.txt
vlc
mpv
gimp
libreoffice
ffmpeg
```

### Security Packages

```
# data/packages/security.txt
keepassxc
bitwarden
signal-desktop
```

### Network Packages

```
# data/packages/network.txt
openssh
nmap
net-tools
wireguard-tools
```

### Fonts Packages

```
# data/packages/fonts.txt
noto-fonts
noto-fonts-emoji
ttf-dejavu
ttf-liberation
```

### Themes Packages

```
# data/packages/themes.txt
arc-theme
papirus-icon-theme
```

## Platform-Specific Package Mapping

### Arch Linux

```bash
# Uses pacman + paru/yay for AUR
# Package names are native
```

### Debian/Ubuntu

```bash
# Uses apt
# Package names may differ from Arch
# Example: base-devel -> build-essential
```

### Alpine

```bash
# Uses apk
# Package names may differ
# Example: git -> git
```

### Termux

```bash
# Uses pkg
# Package names may differ
# Example: vim -> vim
```

## Package Removal Flow

```bash
uninstall_packages() {
    local package_file="$1"

    log_section "Uninstalling Packages"

    while IFS= read -r package; do
        [[ "${package}" =~ ^#.*$ ]] && continue
        [[ -z "${package}" ]] && continue

        if is_package_installed "${package}"; then
            log_info "Removing: ${package}"
            ${PACKAGE_MANAGER_REMOVE} "${package}"
        else
            log_info "Package not installed: ${package}"
        fi
    done < "${package_file}"
}
```

## Package Cache Management

```bash
clean_package_cache() {
    log_section "Cleaning Package Cache"

    case "${PACKAGE_MANAGER}" in
        pacman)
            pacman -Sc --noconfirm
            ;;
        apt)
            apt clean
            apt autoremove -y
            ;;
        apk)
            apk cache clean
            ;;
        pkg)
            pkg autoclean
            ;;
    esac

    log_success "Package cache cleaned"
}
```

## Error Handling

### Package Installation Failures

```bash
# Retry mechanism
install_package_with_retry() {
    local package="$1"
    local max_retries=3
    local retry=0

    while [ ${retry} -lt ${max_retries} ]; do
        if install_package "${package}"; then
            return 0
        fi

        retry=$((retry + 1))
        log_warn "Retry ${retry}/${max_retries} for ${package}"
        sleep 2
    done

    log_error "Failed to install ${package} after ${max_retries} retries"
    return 1
}
```

### Platform Compatibility

```bash
# Skip packages not available on current platform
is_package_available() {
    local package="$1"

    case "${PACKAGE_MANAGER}" in
        pacman)
            pacman -Si "${package}" &>/dev/null
            ;;
        apt)
            apt-cache show "${package}" &>/dev/null
            ;;
        apk)
            apk info "${package}" &>/dev/null
            ;;
        pkg)
            pkg search "${package}" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}
```

## Logging

### Package Installation Log

```
[INFO] Detected package manager: pacman
[INFO] Detected AUR helper: paru
[INFO] Category: base
[INFO] Package already installed: git
[INFO] Installing: vim
[SUCCESS] Installed: vim
[INFO] Installing: curl
[SUCCESS] Installed: curl
...
[INFO] Category: development
[INFO] Package already installed: base-devel
[INFO] Installing: cmake
[SUCCESS] Installed: cmake
...
[SUCCESS] All packages installed
```

## Performance Optimisation

### Parallel Installation

```bash
# Install packages in parallel where possible
install_packages_parallel() {
    local packages=("$@")
    local pids=()

    for package in "${packages[@]}"; do
        install_package "${package}" &
        pids+=($!)
    done

    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done
}
```

### Batch Installation

```bash
# Install multiple packages in a single transaction
install_packages_batch() {
    local packages=("$@")
    local to_install=()

    for package in "${packages[@]}"; do
        if ! is_package_installed "${package}"; then
            to_install+=("${package}")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        ${PACKAGE_MANAGER_INSTALL} "${to_install[@]}"
    fi
}
```