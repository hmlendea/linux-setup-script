# Package Management Component

This document provides a deep dive into the package management component,
which abstracts package installation, removal, and querying across multiple
package managers and platforms.

## Overview

**Location**: `scripts/common/package-management.sh`

**Purpose**: Unified package management interface supporting `pacman`,
`paru`, `yay`, `apt`, `apk`, and `pkg` (Termux) package managers.

**Consumers**: `install-packages.sh`, `uninstall-packages.sh`,
`update-packages.sh`, `clean-packages.sh`, `configure-repositories.sh`,
`update-repositories.sh`

## Core Functions

### 1. Package Manager Detection

```bash
# Detect available package manager
detect_package_manager
# Sets: PACKAGE_MANAGER, PACKAGE_MANAGER_INSTALL, PACKAGE_MANAGER_REMOVE,
#       PACKAGE_MANAGER_UPDATE, PACKAGE_MANAGER_UPGRADE, PACKAGE_MANAGER_SEARCH

# Check if a package is installed
is_package_installed <package_name>
# Returns 0 if installed, 1 if not

# Get installed package version
get_package_version <package_name>
# Returns version string or empty if not installed
```

### 2. Package Installation

```bash
# Install single package
install_package <package_name>

# Install multiple packages
install_packages <package1> [package2...]

# Install packages from file
install_packages_from_file <file_path>

# Install AUR package (if AUR helper available)
install_aur_package <package_name>
```

### 3. Package Removal

```bash
# Remove single package
remove_package <package_name>

# Remove multiple packages
remove_packages <package1> [package2...]

# Remove package and dependencies
remove_package_with_deps <package_name>

# Purge package (remove config files too)
purge_package <package_name>
```

### 4. Package Updates

```bash
# Update package database
update_package_database

# Upgrade all packages
upgrade_packages

# Check for upgradable packages
check_upgradable_packages
# Returns list of upgradable packages

# Hold package (prevent upgrade)
hold_package <package_name>

# Unhold package
unhold_package <package_name>
```

### 5. Package Queries

```bash
# Search for packages
search_packages <query>

# List all installed packages
list_installed_packages

# List available packages
list_available_packages

# Get package info
get_package_info <package_name>

# Check if package is in repositories
is_package_available <package_name>
```

## Supported Package Managers

### Pacman (Arch Linux)

```bash
PACKAGE_MANAGER="pacman"
PACKAGE_MANAGER_INSTALL="pacman -S --noconfirm --needed"
PACKAGE_MANAGER_REMOVE="pacman -Rns"
PACKAGE_MANAGER_UPDATE="pacman -Sy"
PACKAGE_MANAGER_UPGRADE="pacman -Su --noconfirm"
PACKAGE_MANAGER_SEARCH="pacman -Ss"
```

### Paru (Arch Linux AUR)

```bash
PACKAGE_MANAGER="paru"
PACKAGE_MANAGER_INSTALL="paru -S --noconfirm --needed"
PACKAGE_MANAGER_REMOVE="paru -Rns"
PACKAGE_MANAGER_UPDATE="paru -Sy"
PACKAGE_MANAGER_UPGRADE="paru -Su --noconfirm"
PACKAGE_MANAGER_SEARCH="paru -Ss"
```

### Yay (Arch Linux AUR)

```bash
PACKAGE_MANAGER="yay"
PACKAGE_MANAGER_INSTALL="yay -S --noconfirm --needed"
PACKAGE_MANAGER_REMOVE="yay -Rns"
PACKAGE_MANAGER_UPDATE="yay -Sy"
PACKAGE_MANAGER_UPGRADE="yay -Su --noconfirm"
PACKAGE_MANAGER_SEARCH="yay -Ss"
```

### APT (Debian/Ubuntu)

```bash
PACKAGE_MANAGER="apt"
PACKAGE_MANAGER_INSTALL="apt-get install -y"
PACKAGE_MANAGER_REMOVE="apt-get remove --purge -y"
PACKAGE_MANAGER_UPDATE="apt-get update"
PACKAGE_MANAGER_UPGRADE="apt-get upgrade -y"
PACKAGE_MANAGER_SEARCH="apt-cache search"
```

### APK (Alpine)

```bash
PACKAGE_MANAGER="apk"
PACKAGE_MANAGER_INSTALL="apk add"
PACKAGE_MANAGER_REMOVE="apk del"
PACKAGE_MANAGER_UPDATE="apk update"
PACKAGE_MANAGER_UPGRADE="apk upgrade"
PACKAGE_MANAGER_SEARCH="apk search"
```

### Pkg (Termux/Android)

```bash
PACKAGE_MANAGER="pkg"
PACKAGE_MANAGER_INSTALL="pkg install -y"
PACKAGE_MANAGER_REMOVE="pkg uninstall -y"
PACKAGE_MANAGER_UPDATE="pkg update"
PACKAGE_MANAGER_UPGRADE="pkg upgrade -y"
PACKAGE_MANAGER_SEARCH="pkg search"
```

## Package Installation Patterns

### Pattern 1: Base System Packages

```bash
#!/bin/bash
source "scripts/common/package-management.sh"

# Install base packages
install_packages \
    "git" \
    "vim" \
    "curl" \
    "wget" \
    "htop" \
    "tree" \
    "rsync" \
    "unzip" \
    "zip" \
    "p7zip" \
    "bash-completion" \
    "man-db" \
    "man-pages"
```

### Pattern 2: Development Tools

```bash
#!/bin/bash
source "scripts/common/package-management.sh"

# Install development packages
install_packages \
    "build-essential" \
    "cmake" \
    "gcc" \
    "g++" \
    "make" \
    "pkg-config" \
    "autoconf" \
    "automake" \
    "libtool" \
    "nasm" \
    "yasm"

# Install language-specific tools
if is_package_installed "python3"; then
    install_packages "python3-pip" "python3-venv"
fi

if is_package_installed "nodejs"; then
    install_packages "npm"
fi
```

### Pattern 3: Desktop Environment

```bash
#!/bin/bash
source "scripts/common/package-management.sh"

# Install desktop packages
install_packages \
    "lxde" \
    "lxappearance" \
    "lxsession" \
    "openbox" \
    "pcmanfm" \
    "lxpanel" \
    "obconf" \
    "lxinput" \
    "lxrandr" \
    "lxtask" \
    "leafpad" \
    "lxmusic" \
    "lximage" \
    "lxterminal"

# Install additional utilities
install_packages \
    "network-manager" \
    "network-manager-applet" \
    "pulseaudio" \
    "pavucontrol" \
    "lightdm" \
    "lightdm-gtk-greeter"
```

### Pattern 4: Gaming Packages

```bash
#!/bin/bash
source "scripts/common/package-management.sh"

# Install gaming packages
install_packages \
    "steam" \
    "lutris" \
    "wine" \
    "winetricks" \
    "gamemode" \
    "gamescope" \
    "mangoapp" \
    "vulkan-radeon" \
    "vulkan-intel" \
    "vulkan-icd-loader" \
    "lib32-vulkan-radeon" \
    "lib32-vulkan-intel" \
    "lib32-vulkan-icd-loader"

# Install AUR packages if available
if [ "${PACKAGE_MANAGER}" = "paru" ] || [ "${PACKAGE_MANAGER}" = "yay" ]; then
    install_aur_package "steam-native-runtime"
    install_aur_package "heroic-games-launcher-bin"
fi
```

## Package Management Invariants

1. **Idempotency** — `is_package_installed` check before install
2. **Platform abstraction** — Same interface across all package managers
3. **Non-interactive** — All installs use `--noconfirm` / `-y` flags
4. **Dependency resolution** — Package manager handles dependencies
5. **Error propagation** — Failures in package ops are reported
6. **Cache management** — Package caches cleaned after operations

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `install_package` | Package not found | Error message, returns 1 |
| `install_package` | Network error | Error message, returns 1 |
| `install_package` | Permission denied | Error message, returns 1 |
| `remove_package` | Package not installed | Warning, returns 0 |
| `is_package_installed` | Package manager error | Returns 1 |
| `detect_package_manager` | No package manager | Error, exits |

## Performance Considerations

- **Batch installs** — Install multiple packages in one call
- **Cache reuse** — Package database updated once per session
- **Parallel downloads** — Package managers handle parallel downloads
- **Skip installed** — `is_package_installed` check avoids redundant work

## Security Considerations

- **Package verification** — Package managers verify signatures
- **Repository trust** — Only trusted repositories configured
- **No arbitrary code** — Package installation is declarative
- **Privilege separation** — Package ops via `run_as_su`

## Testing

### Unit Tests

```bash
function test_is_package_installed() {
    # Test with known installed package
    assertTrue "bash is installed" "is_package_installed bash"

    # Test with known non-installed package
    assertFalse "fake-package is not installed" "is_package_installed fake-package-12345"
}

function test_install_package() {
    # Test installation of a small package
    install_package "tree"
    assertTrue "tree installed successfully" "is_package_installed tree"
}
```

### Integration Tests

```bash
function test_package_manager_detection() {
    detect_package_manager
    assertNotNull "PACKAGE_MANAGER is set" "${PACKAGE_MANAGER}"
    assertTrue "PACKAGE_MANAGER_INSTALL is set" "[ -n '${PACKAGE_MANAGER_INSTALL}' ]"
    assertTrue "PACKAGE_MANAGER_REMOVE is set" "[ -n '${PACKAGE_MANAGER_REMOVE}' ]"
}
```

## Future Enhancements

1. **Package groups** — Install/remove package groups
2. **Version pinning** — Pin specific package versions
3. **Repository management** — Add/remove repositories programmatically
4. **Package cache management** — Configurable cache cleanup policies
5. **Offline mode** — Install from local package cache
6. **Delta packages** — Use delta packages for faster updates
7. **Package signing** — Verify package signatures explicitly