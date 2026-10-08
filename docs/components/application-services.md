# Application Services Component

This document provides a deep dive into the application services component,
which handles application installation, configuration, and management.

## Overview

**Location**: `scripts/common/apps.sh`, `scripts/install-packages.sh`,
`scripts/configure-default-apps.sh`, `scripts/configure-launchers.sh`

**Purpose**: Application lifecycle management including installation,
configuration, default application associations, and launcher creation.

**Consumers**: `run.sh` (Phase 2, 3), `install-packages.sh`,
`configure-default-apps.sh`, `configure-launchers.sh`

## Core Functions

### 1. Application Installation

```bash
# Install application
install_application <app_name>

# Install applications from list
install_applications <app1> [app2...]

# Install application from file
install_applications_from_file <file_path>

# Install Flatpak application
install_flatpak <flatpak_id>

# Install Snap application
install_snap <snap_name>

# Install AppImage
install_appimage <url> <destination>
```

### 2. Application Configuration

```bash
# Configure application
configure_application <app_name>

# Configure default applications
configure_default_applications

# Set default application for MIME type
set_default_application <mime_type> <desktop_file>

# Get default application for MIME type
get_default_application <mime_type>
```

### 3. Launcher Management

```bash
# Create desktop launcher
create_launcher <name> <command> [icon] [categories]

# Create application launcher
create_application_launcher <desktop_file> <destination>

# Remove launcher
remove_launcher <name>

# Update launcher
update_launcher <name> <command> [icon] [categories]
```

### 4. Application State

```bash
# Check if application is installed
is_application_installed <app_name>

# Get application version
get_application_version <app_name>

# Get application path
get_application_path <app_name>

# List installed applications
list_installed_applications
```

## Application Installation Patterns

### Pattern 1: Base Applications

```bash
#!/bin/bash
source "scripts/common/apps.sh"
source "scripts/common/package-management.sh"

# Install base applications
install_applications \
    "firefox" \
    "thunderbird" \
    "libreoffice" \
    "gimp" \
    "vlc" \
    "mpv" \
    "keepassxc" \
    "bitwarden" \
    "signal-desktop" \
    "discord" \
    "telegram-desktop" \
    "element-desktop"
```

### Pattern 2: Development Applications

```bash
#!/bin/bash
source "scripts/common/apps.sh"
source "scripts/common/package-management.sh"

# Install development applications
install_applications \
    "code" \
    "code-insiders" \
    "vim" \
    "neovim" \
    "git" \
    "gitg" \
    "meld" \
    "dbeaver" \
    "postman" \
    "insomnia" \
    "docker" \
    "docker-compose" \
    "podman" \
    "kubernetes-cli" \
    "helm"
```

### Pattern 3: Gaming Applications

```bash
#!/bin/bash
source "scripts/common/apps.sh"
source "scripts/common/package-management.sh"

# Install gaming applications
install_applications \
    "steam" \
    "lutris" \
    "heroic-games-launcher" \
    "bottles" \
    "wine" \
    "winetricks" \
    "gamemode" \
    "gamescope" \
    "mangoapp" \
    "vkbasalt" \
    "goverlay"
```

### Pattern 4: Flatpak Applications

```bash
#!/bin/bash
source "scripts/common/apps.sh"

# Install Flatpak applications
install_flatpak "org.mozilla.firefox"
install_flatpak "org.libreoffice.LibreOffice"
install_flatpak "org.gimp.GIMP"
install_flatpak "org.videolan.VLC"
install_flatpak "com.valvesoftware.Steam"
install_flatpak "net.lutris.Lutris"
install_flatpak "com.heroicgameslauncher.hgl"
install_flatpak "com.bitwarden.desktop"
install_flatpak "org.signal.Signal"
install_flatpak "com.discordapp.Discord"
```

## Default Application Configuration

### Pattern 1: MIME Type Associations

```bash
#!/bin/bash
source "scripts/common/apps.sh"
source "scripts/common/config.sh"

# Set default applications
set_default_application "text/plain" "code.desktop"
set_default_application "text/x-python" "code.desktop"
set_default_application "text/x-shellscript" "code.desktop"
set_default_application "application/json" "code.desktop"
set_default_application "application/x-shellscript" "code.desktop"

set_default_application "image/png" "org.gnome.eog.desktop"
set_default_application "image/jpeg" "org.gnome.eog.desktop"
set_default_application "image/gif" "org.gnome.eog.desktop"
set_default_application "image/webp" "org.gnome.eog.desktop"

set_default_application "video/mp4" "vlc.desktop"
set_default_application "video/x-matroska" "vlc.desktop"
set_default_application "audio/mpeg" "vlc.desktop"
set_default_application "audio/flac" "vlc.desktop"

set_default_application "application/pdf" "org.gnome.Evince.desktop"
set_default_application "application/x-pdf" "org.gnome.Evince.desktop"

set_default_application "x-scheme-handler/http" "firefox.desktop"
set_default_application "x-scheme-handler/https" "firefox.desktop"
```

### Pattern 2: Desktop File Creation

```bash
#!/bin/bash
source "scripts/common/apps.sh"
source "scripts/common/filesystem.sh"

# Create custom launcher
create_launcher \
    "My Application" \
    "/opt/myapp/myapp" \
    "/opt/myapp/icon.png" \
    "Development;IDE;"

# Deploy desktop file
update_file_if_distinct \
    "${REPO_RESOURCES_DIR}/applications/myapp.desktop" \
    "${XDG_DATA_HOME}/applications/myapp.desktop"
```

## Application Services Invariants

1. **Idempotency** — `is_application_installed` check before install
2. **Platform abstraction** — Same interface across package managers
3. **Non-interactive** — All installs use `--noconfirm` / `-y` flags
4. **Dependency resolution** — Package manager handles dependencies
5. **Error propagation** — Failures in app ops are reported
6. **Cache management** — Package caches cleaned after operations

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `install_application` | Package not found | Error message, returns 1 |
| `install_application` | Network error | Error message, returns 1 |
| `install_application` | Permission denied | Error message, returns 1 |
| `set_default_application` | MIME type invalid | Error message, returns 1 |
| `create_launcher` | Invalid desktop file | Error message, returns 1 |

## Performance Considerations

- **Batch installs** — Install multiple applications in one call
- **Cache reuse** — Package database updated once per session
- **Parallel downloads** — Package managers handle parallel downloads
- **Skip installed** — `is_application_installed` check avoids redundant work

## Security Considerations

- **Package verification** — Package managers verify signatures
- **Repository trust** — Only trusted repositories configured
- **No arbitrary code** — Application installation is declarative
- **Privilege separation** — App ops via `run_as_su`

## Testing

### Unit Tests

```bash
function test_is_application_installed() {
    # Test with known installed application
    assertTrue "firefox is installed" "is_application_installed firefox"

    # Test with known non-installed application
    assertFalse "fake-app is not installed" "is_application_installed fake-app-12345"
}

function test_set_default_application() {
    # Test setting default application
    set_default_application "text/plain" "code.desktop"
    assertEquals "code.desktop" "$(get_default_application "text/plain")"
}
```

### Integration Tests

```bash
function test_application_installation() {
    # Test installation of a small application
    install_application "tree"
    assertTrue "tree installed successfully" "is_application_installed tree"
}
```

## Future Enhancements

1. **Application groups** — Install/remove application groups
2. **Version pinning** — Pin specific application versions
3. **Repository management** — Add/remove repositories programmatically
4. **Application cache management** — Configurable cache cleanup policies
5. **Offline mode** — Install from local package cache
6. **Application updates** — Automatic application updates
7. **Application health checks** — Verify application functionality