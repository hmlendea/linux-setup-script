# Directory and File Management

This document describes how directories and files are managed, including XDG
directories, hidden files, symlinks, and special directory configurations.

## Overview

The directory and file management system configures user directories, manages
hidden files, creates symlinks, and handles special directory configurations
for applications like Minecraft and Android.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Directory and File Management Flow           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    XDG Directory Configuration                   │
│  • Configure user-dirs.conf                                     │
│  • Configure user-dirs.dirs                                     │
│  • Configure user-dirs.locale                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Hidden Files Management                       │
│  • Deploy .hidden files                                         │
│  • Configure hidden files for home, Documents, Downloads        │
│  • Romanian/English variants                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Symlink Management                            │
│  • Create directory symlinks                                    │
│  • Minecraft screenshots symlink                                │
│  • Android emulated storage symlinks                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Directory Icons                               │
│  • Set folder icons                                             │
│  • Configure project folder icons                               │
└─────────────────────────────────────────────────────────────────┘
```

## XDG Directory Configuration

### Script: `scripts/configure-directories.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

configure_directories() {
    log_section "Directory Configuration"

    # Configure XDG directories
    configure_xdg_directories

    # Configure hidden files
    configure_hidden_files

    # Configure symlinks
    configure_symlinks

    # Configure directory icons
    configure_directory_icons

    log_success "Directories configured"
}

configure_xdg_directories() {
    log_subsection "XDG Directories"

    # Create user-dirs.conf
    local user_dirs_conf="${HOME}/.config/user-dirs.conf"
    ensure_directory "$(dirname "${user_dirs_conf}")"

    cat > "${user_dirs_conf}" <<EOF
# This file is written by xdg-user-dirs-update
# If you want to change or add directories, just edit the line you're
# interested in. All local changes will be retained on the next run.
# Format is XDG_xxx_DIR="$HOME/yyy", where yyy is a shell-escaped
# homedir-relative path, or XDG_xxx_DIR="/yyy", where /yyy is an
# absolute path. No other format is supported.
#
enabled=true
filename_encoding=UTF-8
EOF

    # Create user-dirs.dirs
    local user_dirs_dirs="${HOME}/.config/user-dirs.dirs"

    cat > "${user_dirs_dirs}" <<EOF
# This file is written by xdg-user-dirs-update
# If you want to change or add directories, just edit the line you're
# interested in. All local changes will be retained on the next run.
# Format is XDG_xxx_DIR="$HOME/yyy", where yyy is a shell-escaped
# homedir-relative path, or XDG_xxx_DIR="/yyy", where /yyy is an
# absolute path. No other format is supported.
#
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF

    # Create user-dirs.locale
    local user_dirs_locale="${HOME}/.config/user-dirs.locale"

    cat > "${user_dirs_locale}" <<EOF
en_GB
EOF

    # Update XDG directories
    if command_exists xdg-user-dirs-update; then
        xdg-user-dirs-update
        log_info "XDG directories updated"
    fi

    log_info "XDG directories configured"
}
```

## Hidden Files Management

### Hidden Files Configuration

```bash
configure_hidden_files() {
    log_subsection "Hidden Files"

    # Deploy .hidden files
    deploy_hidden_file "home" "${HOME}/.hidden"
    deploy_hidden_file "home-documents" "${HOME}/Documents/.hidden"
    deploy_hidden_file "home-downloads" "${HOME}/Downloads/.hidden"
    deploy_hidden_file "home-ro" "${HOME}/.hidden.ro"

    log_info "Hidden files configured"
}

deploy_hidden_file() {
    local source_name="$1"
    local target="$2"

    local source="${REPO_RC_DIR}/hidden-files/${source_name}"

    if [ -f "${source}" ]; then
        update_file_if_distinct "${source}" "${target}"
        log_info "Deployed hidden file: ${target}"
    else
        log_warn "Hidden file source not found: ${source}"
    fi
}
```

### Hidden File Contents

#### Home Directory (.hidden)

```
# Hidden files in home directory
.cache
.config
.local
.ssh
.gnupg
.gitconfig
.bashrc
.bash_profile
.profile
.vimrc
.nanorc
.inputrc
```

#### Documents Directory (.hidden)

```
# Hidden files in Documents
~$
*.tmp
*.bak
*.swp
*.swo
```

#### Downloads Directory (.hidden)

```
# Hidden files in Downloads
*.part
*.crdownload
*.tmp
*.download
```

#### Romanian Variant (.hidden.ro)

```
# Fișiere ascunse în directorul home
.cache
.config
.local
.ssh
.gnupg
.gitconfig
.bashrc
.bash_profile
.profile
.vimrc
.nanorc
.inputrc
```

## Symlink Management

### Symlink Configuration

```bash
configure_symlinks() {
    log_subsection "Symlinks"

    # Minecraft screenshots symlink
    configure_minecraft_symlink

    # Android emulated storage symlinks
    configure_android_symlinks

    log_info "Symlinks configured"
}

configure_minecraft_symlink() {
    log_info "Configuring Minecraft screenshots symlink..."

    # Find Minecraft instances
    local minecraft_dir="${HOME}/.minecraft"
    local instances_dir="${HOME}/.local/share/minecraft/instances"

    if [ -d "${instances_dir}" ]; then
        # Create shared screenshots directory
        local shared_screenshots="${HOME}/Pictures/Minecraft"
        ensure_directory "${shared_screenshots}"

        # Symlink each instance's screenshots
        for instance in "${instances_dir}"/*; do
            if [ -d "${instance}" ]; then
                local instance_name=$(basename "${instance}")
                local instance_screenshots="${instance}/screenshots"

                if [ -d "${instance_screenshots}" ]; then
                    # Remove existing screenshots directory
                    rm -rf "${instance_screenshots}"
                fi

                # Create symlink
                ln -sf "${shared_screenshots}" "${instance_screenshots}"
                log_info "Symlinked ${instance_name} screenshots to ${shared_screenshots}"
            fi
        done
    fi

    log_info "Minecraft screenshots symlink configured"
}

configure_android_symlinks() {
    log_info "Configuring Android symlinks..."

    # Only on Android/Termux
    if [ "${DISTRO_FAMILY}" = "Android" ]; then
        # Symlink emulated storage to XDG directories
        local emulated_storage="/storage/emulated/0"

        if [ -d "${emulated_storage}" ]; then
            # Symlink Downloads
            ln -sf "${emulated_storage}/Download" "${HOME}/Downloads"

            # Symlink Documents
            ln -sf "${emulated_storage}/Documents" "${HOME}/Documents"

            # Symlink Pictures
            ln -sf "${emulated_storage}/Pictures" "${HOME}/Pictures"

            # Symlink Videos
            ln -sf "${emulated_storage}/Movies" "${HOME}/Videos"

            # Symlink Music
            ln -sf "${emulated_storage}/Music" "${HOME}/Music"

            log_info "Android emulated storage symlinks created"
        fi
    fi

    log_info "Android symlinks configured"
}
```

## Directory Icons

### Directory Icon Configuration

```bash
configure_directory_icons() {
    log_subsection "Directory Icons"

    # Set folder icon for Projects directory
    local projects_dir="${HOME}/Projects"
    ensure_directory "${projects_dir}"

    # Create .directory file for Projects
    local directory_file="${projects_dir}/.directory"

    cat > "${directory_file}" <<EOF
[Desktop Entry]
Type=Directory
Icon=folder-projects
EOF

    # Deploy folder-projects icon
    if [ -f "${REPO_RES_DIR}/icons/folder-projects.png" ]; then
        local icon_dir="${HOME}/.local/share/icons/hicolor/48x48/places"
        ensure_directory "${icon_dir}"
        cp "${REPO_RES_DIR}/icons/folder-projects.png" "${icon_dir}/folder-projects.png"
        log_info "Deployed folder-projects icon"
    fi

    # Update icon cache
    if command_exists gtk-update-icon-cache; then
        gtk-update-icon-cache -f "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
    fi

    log_info "Directory icons configured"
}
```

## Special Directory Configurations

### Minecraft Configuration

```bash
configure_minecraft() {
    log_subsection "Minecraft Configuration"

    # Create Minecraft directory structure
    local minecraft_dir="${HOME}/.minecraft"
    ensure_directory "${minecraft_dir}"

    # Create instances directory
    local instances_dir="${HOME}/.local/share/minecraft/instances"
    ensure_directory "${instances_dir}"

    # Create shared screenshots directory
    local shared_screenshots="${HOME}/Pictures/Minecraft"
    ensure_directory "${shared_screenshots}"

    # Configure Prism Launcher
    if command_exists prismlauncher; then
        local prism_config="${HOME}/.config/PrismLauncher/PrismLauncher.conf"
        ensure_directory "$(dirname "${prism_config}")"

        # Set instance directory
        sed -i "s|^InstanceDir=.*|InstanceDir=${instances_dir}|" "${prism_config}"

        # Set screenshots directory
        sed -i "s|^ScreenshotDir=.*|ScreenshotDir=${shared_screenshots}|" "${prism_config}"

        log_info "Prism Launcher configured"
    fi

    log_info "Minecraft configured"
}
```

### Android Configuration

```bash
configure_android() {
    log_subsection "Android Configuration"

    if [ "${DISTRO_FAMILY}" = "Android" ]; then
        # Configure Termux storage
        if command_exists termux-setup-storage; then
            termux-setup-storage
            log_info "Termux storage configured"
        fi

        # Configure Android-specific directories
        local android_dirs=(
            "${HOME}/storage/downloads"
            "${HOME}/storage/documents"
            "${HOME}/storage/pictures"
            "${HOME}/storage/movies"
            "${HOME}/storage/music"
        )

        for dir in "${android_dirs[@]}"; do
            ensure_directory "${dir}"
        done

        log_info "Android directories configured"
    fi

    log_info "Android configured"
}
```

## Logging

### Directory and File Management Log

```
=== Directory Configuration ===
[INFO] XDG directories configured
[INFO] Deployed hidden file: /home/user/.hidden
[INFO] Deployed hidden file: /home/user/Documents/.hidden
[INFO] Deployed hidden file: /home/user/Downloads/.hidden
[INFO] Deployed hidden file: /home/user/.hidden.ro
[INFO] Symlinks configured
[INFO] Symlinked instance1 screenshots to /home/user/Pictures/Minecraft
[INFO] Symlinked instance2 screenshots to /home/user/Pictures/Minecraft
[INFO] Android emulated storage symlinks created
[INFO] Directory icons configured
[INFO] Deployed folder-projects icon
[INFO] Minecraft configured
[INFO] Prism Launcher configured
[SUCCESS] Directories configured
```

## Performance

### Typical Execution Times

| Operation | Time |
|-----------|------|
| XDG directories | <1 second |
| Hidden files | <1 second |
| Symlinks | 1-2 seconds |
| Directory icons | <1 second |
| Minecraft | 1-3 seconds |
| Android | 1-3 seconds |
| **Total** | **3-10 seconds** |

### Optimisation

- Skip already-configured directories
- Batch symlink creation
- Cache directory paths
- Parallel directory creation