# Autostart and Default Applications

This document describes how autostart applications and default applications
are configured across the system.

## Overview

The autostart and default applications system manages user autostart entries
and sets default applications for MIME types.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Autostart and Default Apps Flow              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Autostart Configuration                       │
│  • Configure user autostart entries                             │
│  • Configure system autostart entries                           │
│  • Manage autostart conditions                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Default Applications                          │
│  • Set default applications via mimeapps.list                   │
│  • Configure MIME associations                                  │
│  • Set default browser, editor, etc.                            │
└─────────────────────────────────────────────────────────────────┘
```

## Autostart Configuration

### Script: `scripts/configure-autostart-apps.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

configure_autostart_apps() {
    log_section "Autostart Applications Configuration"

    # Configure user autostart
    configure_user_autostart

    # Configure system autostart (if root)
    if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
        run_as_su configure_system_autostart
    fi

    log_success "Autostart applications configured"
}

configure_user_autostart() {
    log_subsection "User Autostart"

    local autostart_dir="${HOME}/.config/autostart"
    ensure_directory "${autostart_dir}"

    # Applications to autostart
    local autostart_apps=(
        "plank"
        "signal-desktop"
        "telegram-desktop"
        "discord"
        "electron-mail"
        "planify"
    )

    # Applications to disable
    local disabled_apps=(
        "discord"
    )

    # Enable autostart for applications
    for app in "${autostart_apps[@]}"; do
        enable_autostart "${app}" "${autostart_dir}"
    done

    # Disable autostart for applications
    for app in "${disabled_apps[@]}"; do
        disable_autostart "${app}" "${autostart_dir}"
    done

    log_info "User autostart configured"
}

enable_autostart() {
    local app="$1"
    local autostart_dir="$2"

    # Find the .desktop file
    local desktop_file=$(find /usr/share/applications "${HOME}/.local/share/applications" -name "${app}.desktop" 2>/dev/null | head -1)

    if [ -z "${desktop_file}" ]; then
        log_warn "Desktop file not found for: ${app}"
        return 0
    fi

    # Copy to autostart directory
    local target="${autostart_dir}/${app}.desktop"
    cp "${desktop_file}" "${target}"

    # Ensure it's enabled
    sed -i 's/^Hidden=.*/Hidden=false/' "${target}"
    sed -i 's/^NoDisplay=.*/NoDisplay=false/' "${target}"

    log_info "Enabled autostart: ${app}"
}

disable_autostart() {
    local app="$1"
    local autostart_dir="$2"

    local target="${autostart_dir}/${app}.desktop"

    if [ -f "${target}" ]; then
        # Disable by setting Hidden=true
        sed -i 's/^Hidden=.*/Hidden=true/' "${target}"
        log_info "Disabled autostart: ${app}"
    else
        # Create a disabled entry
        cat > "${target}" <<EOF
[Desktop Entry]
Type=Application
Name=${app}
Exec=${app}
Hidden=true
NoDisplay=true
EOF
        log_info "Created disabled autostart: ${app}"
    fi
}

configure_system_autostart() {
    log_subsection "System Autostart"

    local autostart_dir="/etc/xdg/autostart"
    ensure_directory "${autostart_dir}"

    # System autostart applications
    local system_apps=(
        "polkit-gnome-authentication-agent-1"
        "gnome-keyring-daemon"
        "xdg-desktop-portal"
    )

    for app in "${system_apps[@]}"; do
        local desktop_file=$(find /usr/share/applications -name "${app}.desktop" 2>/dev/null | head -1)

        if [ -n "${desktop_file}" ]; then
            cp "${desktop_file}" "${autostart_dir}/"
            log_info "Enabled system autostart: ${app}"
        fi
    done

    log_info "System autostart configured"
}
```

### Autostart Conditions

```bash
# Conditional autostart based on environment
configure_conditional_autostart() {
    log_subsection "Conditional Autostart"

    # Only autostart Plank on GUI
    if [ "${HAS_GUI}" = "true" ] && [ "${DESKTOP_ENVIRONMENT}" != "phosh" ]; then
        enable_autostart "plank" "${HOME}/.config/autostart"
    fi

    # Only autostart Discord on powerful PCs
    if [ "${IS_POWERFUL_PC}" = "true" ]; then
        enable_autostart "discord" "${HOME}/.config/autostart"
    else
        disable_autostart "discord" "${HOME}/.config/autostart"
    fi

    # Only autostart Signal on battery devices
    if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
        enable_autostart "signal-desktop" "${HOME}/.config/autostart"
    fi

    log_info "Conditional autostart configured"
}
```

## Default Applications

### Script: `scripts/configure-default-apps.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

configure_default_apps() {
    log_section "Default Applications Configuration"

    # Configure MIME associations
    configure_mime_associations

    # Configure default browser
    configure_default_browser

    # Configure default editor
    configure_default_editor

    # Configure default terminal
    configure_default_terminal

    # Configure default file manager
    configure_default_file_manager

    log_success "Default applications configured"
}

configure_mime_associations() {
    log_subsection "MIME Associations"

    local mimeapps="${HOME}/.config/mimeapps.list"
    ensure_directory "$(dirname "${mimeapps}")"

    # Create or update mimeapps.list
    cat > "${mimeapps}" <<EOF
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/ftp=firefox.desktop
x-scheme-handler/chrome=firefox.desktop
x-scheme-handler/chromium=firefox.desktop
text/plain=code.desktop
application/x-shellscript=code.desktop
application/json=code.desktop
application/xml=code.desktop
image/png=gimp.desktop
image/jpeg=gimp.desktop
image/gif=gimp.desktop
image/svg+xml=gimp.desktop
application/pdf=org.gnome.Evince.desktop
video/mp4=vlc.desktop
video/x-matroska=vlc.desktop
audio/mpeg=vlc.desktop
audio/flac=vlc.desktop
application/x-bittorrent=qbittorrent.desktop
inode/directory=pcmanfm.desktop
application/x-archive=file-roller.desktop
application/zip=file-roller.desktop
application/x-rar=file-roller.desktop
application/x-7z-compressed=file-roller.desktop
application/x-tar=file-roller.desktop
application/x-gzip=file-roller.desktop
application/x-xz=file-roller.desktop
application/x-bzip2=file-roller.desktop
application/x-compress=file-roller.desktop
application/x-lzma=file-roller.desktop
application/x-lzop=file-roller.desktop
application/x-rpm=file-roller.desktop
application/x-deb=file-roller.desktop
application/x-ms-dos-executable=wine.desktop
application/x-msi=wine.desktop
application/x-wine-extension-ini=wine.desktop
application/x-wine-extension-dll=wine.desktop
application/x-wine-extension-exe=wine.desktop
application/x-wine-extension-msi=wine.desktop
application/x-wine-extension-bat=wine.desktop
application/x-wine-extension-cmd=wine.desktop
application/x-wine-extension-com=wine.desktop
application/x-wine-extension-scr=wine.desktop
application/x-wine-extension-sys=wine.desktop
application/x-wine-extension-drivers=wine.desktop
application/x-wine-extension-tlb=wine.desktop
application/x-wine-extension-acm=wine.desktop
application/x-wine-extension-ax=wine.desktop
application/x-wine-extension-cpl=wine.desktop
application/x-wine-extension-drv=wine.desktop
application/x-wine-extension-efi=wine.desktop
application/x-wine-extension-fon=wine.desktop
application/x-wine-extension-grp=wine.desktop
application/x-wine-extension-icm=wine.desktop
application/x-wine-extension-ime=wine.desktop
application/x-wine-extension-mui=wine.desktop
application/x-wine-extension-nls=wine.desktop
application/x-wine-extension-ocx=wine.desktop
application/x-wine-extension-tsp=wine.desktop
application/x-wine-extension-acm=wine.desktop
application/x-wine-extension-ax=wine.desktop
application/x-wine-extension-cpl=wine.desktop
application/x-wine-extension-drv=wine.desktop
application/x-wine-extension-efi=wine.desktop
application/x-wine-extension-fon=wine.desktop
application/x-wine-extension-grp=wine.desktop
application/x-wine-extension-icm=wine.desktop
application/x-wine-extension-ime=wine.desktop
application/x-wine-extension-mui=wine.desktop
application/x-wine-extension-nls=wine.desktop
application/x-wine-extension-ocx=wine.desktop
application/x-wine-extension-tsp=wine.desktop
EOF

    log_info "MIME associations configured"
}

configure_default_browser() {
    log_subsection "Default Browser"

    # Set default browser
    if command_exists xdg-settings; then
        xdg-settings set default-web-browser firefox.desktop
        log_info "Default browser set to Firefox"
    fi

    # Set default browser for GNOME
    if [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
        gsettings set org.gnome.desktop.default-applications.browser exec 'firefox %s'
        log_info "GNOME default browser set to Firefox"
    fi

    # Set default browser for KDE
    if [ "${DESKTOP_ENVIRONMENT}" = "KDE" ]; then
        kwriteconfig5 --file "${HOME}/.config/kdeglobals" --group "General" --key "BrowserApplication" "firefox.desktop"
        log_info "KDE default browser set to Firefox"
    fi
}

configure_default_editor() {
    log_subsection "Default Editor"

    # Set default editor
    export EDITOR="code"
    export VISUAL="code"

    # Set default editor for GNOME
    if [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
        gsettings set org.gnome.desktop.default-applications.editor exec 'code %s'
        log_info "GNOME default editor set to VS Code"
    fi

    # Set default editor for KDE
    if [ "${DESKTOP_ENVIRONMENT}" = "KDE" ]; then
        kwriteconfig5 --file "${HOME}/.config/kdeglobals" --group "General" --key "EditorApplication" "code.desktop"
        log_info "KDE default editor set to VS Code"
    fi
}

configure_default_terminal() {
    log_subsection "Default Terminal"

    # Set default terminal
    if command_exists xdg-settings; then
        xdg-settings set default-terminal-emulator alacritty.desktop
        log_info "Default terminal set to Alacritty"
    fi

    # Set default terminal for GNOME
    if [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
        gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'
        log_info "GNOME default terminal set to Alacritty"
    fi

    # Set default terminal for KDE
    if [ "${DESKTOP_ENVIRONMENT}" = "KDE" ]; then
        kwriteconfig5 --file "${HOME}/.config/kdeglobals" --group "General" --key "TerminalApplication" "alacritty.desktop"
        log_info "KDE default terminal set to Alacritty"
    fi
}

configure_default_file_manager() {
    log_subsection "Default File Manager"

    # Set default file manager
    if command_exists xdg-settings; then
        xdg-settings set default-file-manager pcmanfm.desktop
        log_info "Default file manager set to PCManFM"
    fi

    # Set default file manager for GNOME
    if [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
        gsettings set org.gnome.desktop.default-applications.file-manager exec 'pcmanfm %s'
        log_info "GNOME default file manager set to PCManFM"
    fi

    # Set default file manager for KDE
    if [ "${DESKTOP_ENVIRONMENT}" = "KDE" ]; then
        kwriteconfig5 --file "${HOME}/.config/kdeglobals" --group "General" --key "FileManagerApplication" "pcmanfm.desktop"
        log_info "KDE default file manager set to PCManFM"
    fi
}
```

## MIME Type Associations

### Default Application Mapping

| MIME Type | Default Application |
|-----------|---------------------|
| text/html | Firefox |
| x-scheme-handler/http | Firefox |
| x-scheme-handler/https | Firefox |
| text/plain | VS Code |
| application/x-shellscript | VS Code |
| application/json | VS Code |
| application/xml | VS Code |
| image/png | GIMP |
| image/jpeg | GIMP |
| image/gif | GIMP |
| image/svg+xml | GIMP |
| application/pdf | Evince |
| video/mp4 | VLC |
| video/x-matroska | VLC |
| audio/mpeg | VLC |
| audio/flac | VLC |
| application/x-bittorrent | qBittorrent |
| inode/directory | PCManFM |
| application/x-archive | File Roller |
| application/zip | File Roller |
| application/x-rar | File Roller |
| application/x-7z-compressed | File Roller |
| application/x-tar | File Roller |
| application/x-gzip | File Roller |
| application/x-xz | File Roller |
| application/x-bzip2 | File Roller |
| application/x-compress | File Roller |
| application/x-lzma | File Roller |
| application/x-lzop | File Roller |
| application/x-rpm | File Roller |
| application/x-deb | File Roller |
| application/x-ms-dos-executable | Wine |
| application/x-msi | Wine |

## Logging

### Autostart and Default Apps Log

```
=== Autostart Applications Configuration ===
[INFO] User autostart configured
[INFO] Enabled autostart: plank
[INFO] Enabled autostart: signal-desktop
[INFO] Enabled autostart: telegram-desktop
[INFO] Disabled autostart: discord
[INFO] System autostart configured
[INFO] Enabled system autostart: polkit-gnome-authentication-agent-1
[INFO] Enabled system autostart: gnome-keyring-daemon
[INFO] Enabled system autostart: xdg-desktop-portal

=== Default Applications Configuration ===
[INFO] MIME associations configured
[INFO] Default browser set to Firefox
[INFO] GNOME default browser set to Firefox
[INFO] Default editor set to VS Code
[INFO] GNOME default editor set to VS Code
[INFO] Default terminal set to Alacritty
[INFO] GNOME default terminal set to Alacritty
[INFO] Default file manager set to PCManFM
[INFO] GNOME default file manager set to PCManFM
[SUCCESS] Default applications configured
```

## Performance

### Typical Execution Times

| Operation | Time |
|-----------|------|
| Autostart configuration | 1-3 seconds |
| Default applications | 1-3 seconds |
| **Total** | **2-6 seconds** |

### Optimisation

- Skip already-configured applications
- Batch MIME type updates
- Cache desktop file locations
- Parallel autostart configuration