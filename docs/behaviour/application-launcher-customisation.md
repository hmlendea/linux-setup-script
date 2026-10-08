# Application Launcher Customisation

This document describes how application launchers are configured, modified,
and managed across the system.

## Overview

The application launcher customisation system modifies `.desktop` files for
installed applications, setting appropriate names, categories, icons, and
window class names.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Launcher Customisation Flow      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Launcher Discovery                             │
│  • Scan /usr/share/applications                                 │
│  • Scan ~/.local/share/applications                             │
│  • Scan ~/.config/autostart                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Launcher Modification                          │
│  • Set Name and localized names                                 │
│  • Set Categories                                               │
│  • Set Icon                                                     │
│  • Set NoDisplay                                                │
│  • Set StartupWMClass                                           │
│  • Set Keywords                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Launcher Deployment                            │
│  • Deploy custom launchers                                      │
│  • Create desktop entries                                       │
│  • Update desktop database                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Launcher Discovery

### Script: `scripts/configure-launchers.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

# Launcher categories
declare -a LAUNCHER_CATEGORIES=(
    "ai"
    "app-stores"
    "archive-managers"
    "audio-players"
    "browsers"
    "calculators"
    "cameras"
    "chat"
    "code-editors"
    "databases"
    "disk"
    "email"
    "file-managers"
    "games"
    "ides"
    "image-viewers"
    "media-players"
    "messengers"
    "notes"
    "office"
    "password-managers"
    "remote-desktop"
    "screenshots"
    "settings"
    "terminals"
    "text-editors"
    "video-players"
    "virtualization"
    "vpn"
    "web-apps"
)

configure_launchers() {
    log_section "Application Launcher Customisation"

    # Discover launchers
    discover_launchers

    # Modify launchers
    modify_launchers

    # Deploy custom launchers
    deploy_custom_launchers

    log_success "Application launchers customised"
}

discover_launchers() {
    log_subsection "Discovering Launchers"

    local launcher_dirs=(
        "/usr/share/applications"
        "${HOME}/.local/share/applications"
        "${HOME}/.config/autostart"
    )

    for dir in "${launcher_dirs[@]}"; do
        if [ -d "${dir}" ]; then
            log_info "Scanning: ${dir}"
            find "${dir}" -name "*.desktop" -type f
        fi
    done
}
```

## Launcher Modification

### Modification Function

```bash
modify_launchers() {
    log_subsection "Modifying Launchers"

    local launcher_files=()

    # Collect launcher files
    for dir in /usr/share/applications "${HOME}/.local/share/applications"; do
        if [ -d "${dir}" ]; then
            while IFS= read -r -d '' file; do
                launcher_files+=("${file}")
            done < <(find "${dir}" -name "*.desktop" -type f -print0)
        fi
    done

    # Modify each launcher
    for launcher in "${launcher_files[@]}"; do
        modify_launcher "${launcher}"
    done

    log_info "Launchers modified: ${#launcher_files[@]}"
}

modify_launcher() {
    local launcher="$1"

    # Read launcher content
    local content=$(cat "${launcher}")

    # Modify launcher based on application
    modify_launcher_by_app "${launcher}" "${content}"

    # Write back if changed
    if [ "${content}" != "$(cat "${launcher}")" ]; then
        log_info "Modified launcher: ${launcher}"
    fi
}

modify_launcher_by_app() {
    local launcher="$1"
    local content="$2"

    # Extract application name
    local app_name=$(grep -oP '(?<=^Name=).+' "${launcher}" | head -1)

    # Modify based on application
    case "${app_name}" in
        "Visual Studio Code")
            modify_vscode "${launcher}"
            ;;
        "Discord")
            modify_discord "${launcher}"
            ;;
        "Telegram")
            modify_telegram "${launcher}"
            ;;
        "Signal Desktop")
            modify_signal "${launcher}"
            ;;
        "Firefox")
            modify_firefox "${launcher}"
            ;;
        "Chromium")
            modify_chromium "${launcher}"
            ;;
        "Google Chrome")
            modify_chrome "${launcher}"
            ;;
        "LibreOffice Writer")
            modify_libreoffice "${launcher}"
            ;;
        "GIMP")
            modify_gimp "${launcher}"
            ;;
        "VLC media player")
            modify_vlc "${launcher}"
            ;;
        *)
            # Generic modification
            modify_generic "${launcher}"
            ;;
    esac
}
```

### Generic Launcher Modification

```bash
modify_generic() {
    local launcher="$1"

    # Set Name (if not already set)
    if ! grep -q "^Name=" "${launcher}"; then
        local app_name=$(grep -oP '(?<=^Exec=).+' "${launcher}" | sed 's/.*\///' | sed 's/^[^/]*\///')
        sed -i "1i Name=${app_name}" "${launcher}"
    fi

    # Set Name[ro] (Romanian localization)
    if grep -q "^Name=" "${launcher}"; then
        local name=$(grep -oP '(?<=^Name=).+' "${launcher}" | head -1)
        sed -i "s/^Name=.*/Name=${name}\nName[ro]=${name}/" "${launcher}"
    fi

    # Set Categories
    if ! grep -q "^Categories=" "${launcher}"; then
        sed -i "s/^Exec=.*/&\nCategories=Application;" "${launcher}"
    fi

    # Set Icon
    if ! grep -q "^Icon=" "${launcher}"; then
        local icon=$(grep -oP '(?<=^Exec=).+' "${launcher}" | sed 's/.*\///' | sed 's/^[^/]*\///')
        sed -i "s/^Exec=.*/&\nIcon=${icon}/" "${launcher}"
    fi

    # Set NoDisplay
    if ! grep -q "^NoDisplay=" "${launcher}"; then
        sed -i "s/^Exec=.*/&\nNoDisplay=false/" "${launcher}"
    fi

    # Set StartupWMClass
    if ! grep -q "^StartupWMClass=" "${launcher}"; then
        local wm_class=$(grep -oP '(?<=^Exec=).+' "${launcher}" | sed 's/.*\///' | sed 's/^[^/]*\///')
        sed -i "s/^Exec=.*/&\nStartupWMClass=${wm_class}/" "${launcher}"
    fi

    # Set Keywords
    if ! grep -q "^Keywords=" "${launcher}"; then
        sed -i "s/^Exec=.*/&\nKeywords=Application;" "${launcher}"
    fi
}
```

### Application-Specific Modifications

#### Visual Studio Code

```bash
modify_vscode() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Visual Studio Code/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Visual Studio Code\nName[ro]=Visual Studio Code/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Development;IDE;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=code/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=Code/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Development;IDE;Code;Editor;' "${launcher}"
}
```

#### Discord

```bash
modify_discord() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Discord/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Discord\nName[ro]=Discord/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;Chat;InstantMessaging;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=discord/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=discord/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;Chat;InstantMessaging;Discord;' "${launcher}"
}
```

#### Telegram

```bash
modify_telegram() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Telegram/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Telegram\nName[ro]=Telegram/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;Chat;InstantMessaging;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=telegram-desktop/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=Telegram/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;Chat;InstantMessaging;Telegram;' "${launcher}"
}
```

#### Signal Desktop

```bash
modify_signal() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Signal/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Signal\nName[ro]=Signal/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;Chat;InstantMessaging;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=signal/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=Signal/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;Chat;InstantMessaging;Signal;' "${launcher}"
}
```

#### Firefox

```bash
modify_firefox() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Firefox Web Browser/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Firefox Web Browser\nName[ro]=Firefox Web Browser/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;WebBrowser;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=firefox/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=firefox/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;WebBrowser;Firefox;' "${launcher}"
}
```

#### Chromium

```bash
modify_chromium() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Chromium Web Browser/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Chromium Web Browser\nName[ro]=Chromium Web Browser/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;WebBrowser;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=chromium/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=chromium/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;WebBrowser;Chromium;' "${launcher}"
}
```

#### Google Chrome

```bash
modify_chrome() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=Google Chrome/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=Google Chrome\nName[ro]=Google Chrome/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Network;WebBrowser;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=google-chrome/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=google-chrome/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Network;WebBrowser;Chrome;' "${launcher}"
}
```

#### LibreOffice Writer

```bash
modify_libreoffice() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=LibreOffice Writer/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=LibreOffice Writer\nName[ro]=LibreOffice Writer/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Office;WordProcessor;TextEditor;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=libreoffice-writer/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=writer/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Office;WordProcessor;TextEditor;LibreOffice;' "${launcher}"
}
```

#### GIMP

```bash
modify_gimp() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=GIMP/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=GIMP\nName[ro]=GIMP/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=Graphics;2DGraphics;RasterGraphics;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=gimp/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=gimp/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=Graphics;2DGraphics;RasterGraphics;GIMP;' "${launcher}"
}
```

#### VLC media player

```bash
modify_vlc() {
    local launcher="$1"

    # Set Name
    sed -i 's/^Name=.*/Name=VLC media player/' "${launcher}"

    # Set Name[ro]
    sed -i 's/^Name=.*/Name=VLC media player\nName[ro]=VLC media player/' "${launcher}"

    # Set Categories
    sed -i 's/^Exec=.*/&\nCategories=AudioVideo;Player;Video;' "${launcher}"

    # Set Icon
    sed -i 's/^Exec=.*/&\nIcon=vlc/' "${launcher}"

    # Set StartupWMClass
    sed -i 's/^Exec=.*/&\nStartupWMClass=vlc/' "${launcher}"

    # Set Keywords
    sed -i 's/^Exec=.*/&\nKeywords=AudioVideo;Player;Video;VLC;' "${launcher}"
}
```

## Launcher Deployment

### Deploy Custom Launchers

```bash
deploy_custom_launchers() {
    log_subsection "Deploying Custom Launchers"

    # Deploy custom launchers from resources
    if [ -d "${REPO_RES_DIR}/pcmanfm" ]; then
        for launcher in "${REPO_RES_DIR}/pcmanfm"/*.desktop; do
            if [ -f "${launcher}" ]; then
                local basename=$(basename "${launcher}")
                update_file_if_distinct "${launcher}" "${HOME}/.local/share/applications/${basename}"
            fi
        done
    fi

    # Deploy custom launchers from rc
    if [ -d "${REPO_RC_DIR}/launchers" ]; then
        for launcher in "${REPO_RC_DIR}/launchers"/*.desktop; do
            if [ -f "${launcher}" ]; then
                local basename=$(basename "${launcher}")
                update_file_if_distinct "${launcher}" "${HOME}/.local/share/applications/${basename}"
            fi
        done
    fi

    log_info "Custom launchers deployed"
}
```

### Update Desktop Database

```bash
update_desktop_database() {
    log_subsection "Updating Desktop Database"

    # Update desktop database
    if command_exists update-desktop-database; then
        update-desktop-database "${HOME}/.local/share/applications"
        update-desktop-database "/usr/share/applications"
        log_info "Desktop database updated"
    else
        log_warn "update-desktop-database not found, skipping"
    fi
}
```

## Launcher Categories

### Category Mapping

| Application | Categories |
|-------------|------------|
| AI apps | AI;Development; |
| App Stores | System;PackageManager; |
| Archive Managers | System;FileManager; |
| Audio Players | AudioVideo;Player;Audio; |
| Browsers | Network;WebBrowser; |
| Calculators | Education;Calculator; |
| Cameras | Graphics;Camera; |
| Chat | Network;Chat;InstantMessaging; |
| Code Editors | Development;TextEditor; |
| Databases | Development;Database; |
| Disk | System;FileManager; |
| Email | Network;Email; |
| File Managers | System;FileManager; |
| Games | Game; |
| IDEs | Development;IDE; |
| Image Viewers | Graphics;Viewer; |
| Media Players | AudioVideo;Player;Video; |
| Messengers | Network;Chat;InstantMessaging; |
| Notes | Office;Note; |
| Office | Office; |
| Password Managers | Security;Password; |
| Remote Desktop | Network;RemoteAccess; |
| Screenshots | Graphics;Screenshot; |
| Settings | System;Settings; |
| Terminals | System;TerminalEmulator; |
| Text Editors | Development;TextEditor; |
| Video Players | AudioVideo;Player;Video; |
| Virtualization | System;Virtualization; |
| VPN | Network;VPN; |
| Web Apps | Network;WebBrowser; |

## Logging

### Launcher Customisation Log

```
=== Application Launcher Customisation ===
[INFO] Scanning: /usr/share/applications
[INFO] Scanning: /home/user/.local/share/applications
[INFO] Scanning: /home/user/.config/autostart
[INFO] Modified launcher: /usr/share/applications/code.desktop
[INFO] Modified launcher: /usr/share/applications/discord.desktop
[INFO] Modified launcher: /usr/share/applications/telegram-desktop.desktop
[INFO] Modified launcher: /usr/share/applications/firefox.desktop
[INFO] Modified launcher: /usr/share/applications/libreoffice-writer.desktop
[INFO] Modified launcher: /usr/share/applications/gimp.desktop
[INFO] Modified launcher: /usr/share/applications/vlc.desktop
[INFO] Launchers modified: 100
[INFO] Custom launchers deployed
[INFO] Desktop database updated
[SUCCESS] Application launchers customised
```

## Performance

### Typical Execution Times

| Operation | Time |
|-----------|------|
| Launcher discovery | 1-3 seconds |
| Launcher modification | 5-15 seconds |
| Launcher deployment | 1-3 seconds |
| Desktop database update | 1-3 seconds |
| **Total** | **8-24 seconds** |

### Optimisation

- Skip already-modified launchers
- Batch launcher modifications
- Parallel launcher processing
- Cache launcher metadata