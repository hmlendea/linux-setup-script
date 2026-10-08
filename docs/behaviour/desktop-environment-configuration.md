# Desktop Environment Configuration

This document describes how desktop environments are detected, configured,
and managed across the system.

## Overview

The desktop environment configuration system detects the current desktop
environment and applies appropriate settings for GNOME, KDE, MATE, LXDE,
and Phosh.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Desktop Environment Configuration Flow           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Desktop Environment Detection                    │
│  • XDG_CURRENT_DESKTOP                                            │
│  • DESKTOP_SESSION                                                  │
│  • XDG_SESSION_TYPE                                                 │
│  • XDG_SESSION_DESKTOP                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Configuration Application                        │
│  • GNOME: gsettings, dconf                                         │
│  • KDE: kwriteconfig5, kdeglobals                                  │
│  • MATE: gsettings, mateconf                                       │
│  • LXDE: lxpanel, pcmanfm, openbox                                  │
│  • Phosh: gsettings, phosh-specific                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Post-Configuration                               │
│  • Verify settings applied                                          │
│  • Reload desktop environment                                       │
│  • Restart affected applications                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Desktop Environment Detection

### Detection Logic

```bash
# From system-info.sh
detect_desktop_environment() {
    # Check XDG_CURRENT_DESKTOP
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        DESKTOP_ENVIRONMENT="${XDG_CURRENT_DESKTOP}"
        return 0
    fi

    # Check DESKTOP_SESSION
    if [ -n "${DESKTOP_SESSION:-}" ]; then
        DESKTOP_ENVIRONMENT="${DESKTOP_SESSION}"
        return 0
    fi

    # Check XDG_SESSION_DESKTOP
    if [ -n "${XDG_SESSION_DESKTOP:-}" ]; then
        DESKTOP_ENVIRONMENT="${XDG_SESSION_DESKTOP}"
        return 0
    fi

    # Fallback: detect from running processes
    if pgrep -x "gnome-shell" &>/dev/null; then
        DESKTOP_ENVIRONMENT="GNOME"
    elif pgrep -x "plasma" &>/dev/null; then
        DESKTOP_ENVIRONMENT="KDE"
    elif pgrep -x "mate-panel" &>/dev/null; then
        DESKTOP_ENVIRONMENT="MATE"
    elif pgrep -x "lxpanel" &>/dev/null; then
        DESKTOP_ENVIRONMENT="LXDE"
    elif pgrep -x "phosh" &>/dev/null; then
        DESKTOP_ENVIRONMENT="Phosh"
    else
        DESKTOP_ENVIRONMENT="unknown"
    fi
}
```

### Detection Priority

| Priority | Variable | Example |
|----------|----------|---------|
| 1 | XDG_CURRENT_DESKTOP | GNOME, KDE, MATE, LXDE |
| 2 | DESKTOP_SESSION | gnome, kde, mate, lxde |
| 3 | XDG_SESSION_DESKTOP | GNOME, KDE, MATE, LXDE |
| 4 | Process detection | gnome-shell, plasma, mate-panel |

## GNOME Configuration

### Configuration Methods

```bash
# GNOME uses gsettings and dconf
configure_gnome() {
    log_subsection "GNOME Configuration"

    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK3_THEME}"

    # Set icon theme
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}"

    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME}"

    # Set font
    gsettings set org.gnome.desktop.interface font-name "${INTERFACE_FONT}"
    gsettings set org.gnome.desktop.interface monospace-font-name "${MONOSPACE_FONT}"

    # Set color scheme
    if [ "${DESKTOP_THEME_IS_DARK}" = "true" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    else
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    fi

    # Set shell theme
    gsettings set org.gnome.shell.extensions.user-theme name "${GTK3_THEME}"

    # Set window manager theme
    gsettings set org.gnome.desktop.wm.preferences theme "${GTK3_THEME}"

    # Set desktop background
    gsettings set org.gnome.desktop.background picture-uri "file:///path/to/wallpaper"

    # Set lock screen background
    gsettings set org.gnome.desktop.screensaver picture-uri "file:///path/to/wallpaper"

    # Set show desktop icons
    gsettings set org.gnome.desktop.background show-desktop-icons false

    # Set show battery percentage
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    # Set clock format
    gsettings set org.gnome.desktop.interface clock-format '24h'

    # Set date format
    gsettings set org.gnome.desktop.interface clock-format '24h'

    # Set enable animations
    gsettings set org.gnome.desktop.interface enable-animations true

    # Set enable hot corners
    gsettings set org.gnome.desktop.interface enable-hot-corners false

    # Set enable edge tiling
    gsettings set org.gnome.mutter edge-tiling true

    # Set enable attach modal dialogs
    gsettings set org.gnome.mutter attach-modal-dialogs true

    # Set enable dynamic workspaces
    gsettings set org.gnome.desktop.privacy dynamic-workspaces false

    # Set enable hot corners
    gsettings set org.gnome.desktop.interface enable-hot-corners false

    # Set enable show apps at top
    gsettings set org.gnome.shell enable-hot-corners false

    # Set enable hot corners
    gsettings set org.gnome.shell enable-hot-corners false

    log_info "GNOME configured"
}
```

### GNOME Extensions

```bash
# Install GNOME extensions
install_gnome_extensions() {
    log_subsection "GNOME Extensions"

    # Install extensions
    local extensions=(
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash-to-dock@micxgx.gmail.com"
        "arc-menu@arcmenu.github.com"
        "just-perfection@just-perfection.github.com"
    )

    for extension in "${extensions[@]}"; do
        if ! gnome-extensions list | grep -q "${extension}"; then
            gnome-extensions install "${extension}"
            log_info "Installed extension: ${extension}"
        fi
    done

    # Enable extensions
    for extension in "${extensions[@]}"; do
        gnome-extensions enable "${extension}"
        log_info "Enabled extension: ${extension}"
    done
}
```

## KDE Configuration

### Configuration Methods

```bash
# KDE uses kwriteconfig5 and kdeglobals
configure_kde() {
    log_subsection "KDE Configuration"

    local kde_config="${HOME}/.config/kdeglobals"

    # Set widget style
    kwriteconfig5 --file "${kde_config}" --group "General" --key "widgetStyle" "${GTK_THEME}"

    # Set font
    kwriteconfig5 --file "${kde_config}" --group "General" --key "font" "${INTERFACE_FONT_FACE},${INTERFACE_FONT_SIZE},-1,5,50,0,0,0,0,0"

    # Set fixed font
    kwriteconfig5 --file "${kde_config}" --group "General" --key "fixedFont" "${MONOSPACE_FONT_FACE},${MONOSPACE_FONT_SIZE},-1,5,50,0,0,0,0,0"

    # Set icon theme
    kwriteconfig5 --file "${kde_config}" --group "Icons" --key "Theme" "${ICON_THEME}"

    # Set cursor theme
    kwriteconfig5 --file "${kde_config}" --group "Mouse" --key "cursorTheme" "${CURSOR_THEME}"

    # Set show desktop icons
    kwriteconfig5 --file "${kde_config}" --group "Desktop" --key "ShowDesktopIcons" "true"

    # Set show taskbar
    kwriteconfig5 --file "${kde_config}" --group "Taskbar" --key "ShowTaskbar" "true"

    # Set show desktop grid
    kwriteconfig5 --file "${kde_config}" --group "Desktop" --key "ShowDesktopGrid" "false"

    log_info "KDE configured"
}
```

### KDE Plasma Configuration

```bash
# Configure Plasma panels
configure_kde_plasma() {
    log_subsection "KDE Plasma Configuration"

    # Configure panel
    local panel_config="${HOME}/.config/plasma-org.kde.plasma.plasmoidrc"

    # Set panel position
    kwriteconfig5 --file "${panel_config}" --group "General" --key "Location" "Bottom"

    # Set panel height
    kwriteconfig5 --file "${panel_config}" --group "General" --key "Height" "40"

    # Set panel alignment
    kwriteconfig5 --file "${panel_config}" --group "General" --key "Alignment" "Center"

    # Set panel visibility
    kwriteconfig5 --file "${panel_config}" --group "General" --key "HideMode" "0"

    log_info "KDE Plasma configured"
}
```

## MATE Configuration

### Configuration Methods

```bash
# MATE uses gsettings and mateconf
configure_mate() {
    log_subsection "MATE Configuration"

    # Set GTK theme
    gsettings set org.mate.interface gtk-theme "${GTK3_THEME}"

    # Set icon theme
    gsettings set org.mate.interface icon-theme "${ICON_THEME}"

    # Set cursor theme
    gsettings set org.mate.interface cursor-theme "${CURSOR_THEME}"

    # Set font
    gsettings set org.mate.interface font-name "${INTERFACE_FONT}"
    gsettings set org.mate.interface monospace-font-name "${MONOSPACE_FONT}"

    # Set show desktop icons
    gsettings set org.mate.caja.desktop show-desktop-icons false

    # Set show panel
    gsettings set org.mate.panel general show-panels true

    # Set panel position
    gsettings set org.mate.panel.toplevels.panel1 orientation "top"

    # Set panel size
    gsettings set org.mate.panel.toplevels.panel1 size "40"

    log_info "MATE configured"
}
```

## LXDE Configuration

### Configuration Methods

```bash
# LXDE uses lxpanel, pcmanfm, openbox
configure_lxde() {
    log_subsection "LXDE Configuration"

    # Configure panel
    configure_lxde_panel

    # Configure file manager
    configure_pcmanfm

    # Configure window manager
    configure_openbox

    log_info "LXDE configured"
}

configure_lxde_panel() {
    log_info "Configuring LXDE panel..."

    # Deploy panel configuration
    if [ -f "${REPO_RC_DIR}/lxde-panel" ]; then
        update_file_if_distinct \
            "${REPO_RC_DIR}/lxde-panel" \
            "${HOME}/.config/lxpanel/LXDE/panels/panel"
    fi

    # Deploy dock configuration
    if [ -f "${REPO_RC_DIR}/lxde-dock" ]; then
        update_file_if_distinct \
            "${REPO_RC_DIR}/lxde-dock" \
            "${HOME}/.config/lxpanel/LXDE/panels/dock"
    fi

    log_info "LXDE panel configured"
}

configure_pcmanfm() {
    log_info "Configuring PCManFM..."

    # Deploy desktop entries
    if [ -f "resources/pcmanfm/open-in-code.desktop" ]; then
        update_file_if_distinct \
            "resources/pcmanfm/open-in-code.desktop" \
            "${HOME}/.local/share/applications/open-in-code.desktop"
    fi

    if [ -f "resources/pcmanfm/open-in-terminal.desktop" ]; then
        update_file_if_distinct \
            "resources/pcmanfm/open-in-terminal.desktop" \
            "${HOME}/.local/share/applications/open-in-terminal.desktop"
    fi

    log_info "PCManFM configured"
}

configure_openbox() {
    log_info "Configuring Openbox..."

    # Deploy Openbox configuration
    if [ -f "${REPO_RC_DIR}/openbox-rc.xml" ]; then
        update_file_if_distinct \
            "${REPO_RC_DIR}/openbox-rc.xml" \
            "${HOME}/.config/openbox/rc.xml"
    fi

    log_info "Openbox configured"
}
```

## Phosh Configuration

### Configuration Methods

```bash
# Phosh uses gsettings
configure_phosh() {
    log_subsection "Phosh Configuration"

    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK3_THEME}"

    # Set icon theme
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}"

    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME}"

    # Set font
    gsettings set org.gnome.desktop.interface font-name "${INTERFACE_FONT}"
    gsettings set org.gnome.desktop.interface monospace-font-name "${MONOSPACE_FONT}"

    # Set color scheme
    if [ "${DESKTOP_THEME_IS_DARK}" = "true" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    else
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    fi

    log_info "Phosh configured"
}
```

## Desktop Environment Switching

### Switching Between Desktop Environments

```bash
# Switch desktop environment
switch_desktop_environment() {
    local target_de="$1"

    log_info "Switching to ${target_de}..."

    # Stop current desktop environment
    stop_desktop_environment

    # Apply new configuration
    case "${target_de}" in
        gnome)
            configure_gnome
            ;;
        kde)
            configure_kde
            ;;
        mate)
            configure_mate
            ;;
        lxde)
            configure_lxde
            ;;
        phosh)
            configure_phosh
            ;;
        *)
            log_error "Unknown desktop environment: ${target_de}"
            return 1
            ;;
    esac

    # Start new desktop environment
    start_desktop_environment

    log_success "Switched to ${target_de}"
}
```

## Verification

### Desktop Environment Verification

```bash
verify_desktop_environment() {
    log_subsection "Verifying Desktop Environment"

    local current_de=$(detect_desktop_environment)

    case "${current_de}" in
        gnome)
            verify_gnome_settings
            ;;
        kde)
            verify_kde_settings
            ;;
        mate)
            verify_mate_settings
            ;;
        lxde)
            verify_lxde_settings
            ;;
        phosh)
            verify_phosh_settings
            ;;
        *)
            log_warn "Unknown desktop environment: ${current_de}"
            ;;
    esac
}

verify_gnome_settings() {
    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
    local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme)

    if [ "${gtk_theme}" != "'${GTK3_THEME}'" ]; then
        log_warn "GTK theme mismatch: expected ${GTK3_THEME}, got ${gtk_theme}"
    fi

    if [ "${icon_theme}" != "'${ICON_THEME}'" ]; then
        log_warn "Icon theme mismatch: expected ${ICON_THEME}, got ${icon_theme}"
    fi
}
```

## Logging

### Desktop Environment Configuration Log

```
=== Desktop Environment Configuration ===
[INFO] Detected desktop environment: GNOME
[INFO] Applying GNOME settings
[INFO] Setting GTK theme: adw-gtk3
[INFO] Setting icon theme: Papirus-Dark
[INFO] Setting cursor theme: Vimix-white-cursors
[INFO] Setting font: Sans Regular 11
[INFO] Setting monospace font: Droid Sans Regular 12
[INFO] Setting color scheme: prefer-dark
[INFO] Installing GNOME extensions
[INFO] Installed extension: user-theme@gnome-shell-extensions.gcampax.github.com
[INFO] Enabled extension: user-theme@gnome-shell-extensions.gcampax.github.com
[INFO] Installed extension: dash-to-dock@micxgx.gmail.com
[INFO] Enabled extension: dash-to-dock@micxgx.gmail.com
[SUCCESS] GNOME configured
```

## Performance

### Typical Execution Times

| Desktop Environment | Time |
|---------------------|------|
| GNOME | 2-5 seconds |
| KDE | 2-5 seconds |
| MATE | 1-3 seconds |
| LXDE | 1-3 seconds |
| Phosh | 1-3 seconds |
| **Total** | **1-5 seconds** |

### Optimisation

- Skip already-configured settings
- Batch gsettings calls
- Cache desktop environment detection
- Lazy loading of desktop environment specific code