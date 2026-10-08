# Theme and Font Resolution

This document describes how themes and fonts are resolved and applied across the
system based on screen resolution, DPI, and user preferences.

## Overview

The theme and font resolution system dynamically calculates appropriate values
for GTK themes, font sizes, and font faces based on detected hardware
characteristics.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Theme and Font Resolution Flow               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Input Detection                              │
│  • Screen height and width                                      │
│  • Screen DPI                                                   │
│  • Desktop environment                                          │
│  • GTK theme preference                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Theme Resolution                             │
│  • Determine theme mode (dark/light)                            │
│  • Select base GTK theme                                        │
│  • Normalise theme names for GTK2/3/4                           │
│  • Set icon and cursor themes                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Font Resolution                              │
│  • Calculate font sizes based on screen height                  │
│  • Adjust for DPI                                               │
│  • Select font faces                                            │
│  • Apply Debian/Ubuntu specific adjustments                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application                                  │
│  • Apply GTK settings                                           │
│  • Configure GNOME/KDE/LXDE/Phosh                               │
│  • Set terminal fonts                                           │
│  • Configure application fonts                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Theme Resolution

### Theme Mode Detection

```bash
# From system-info.sh
get_theme_mode() {
    # Check for dark mode preference
    if [ "${DARK_MODE:-}" = "true" ]; then
        echo "dark"
        return 0
    fi

    # Check system settings
    if command_exists gsettings; then
        if gsettings get org.gnome.desktop.interface color-scheme | grep -q "dark"; then
            echo "dark"
            return 0
        fi
    fi

    # Check KDE
    if [ "${KDE_SESSION_VERSION:-}" = "5" ] || [ "${KDE_SESSION_VERSION:-}" = "6" ]; then
        if [ -f "${HOME}/.config/kdeglobals" ]; then
            if grep -q "ColorScheme=.*Dark" "${HOME}/.config/kdeglobals"; then
                echo "dark"
                return 0
            fi
        fi
    fi

    # Default to light
    echo "light"
}
```

### GTK Theme Selection

```bash
# From system-info.sh
get_theme() {
    # Check for explicit theme override
    if [ -n "${GTK_THEME_OVERRIDE:-}" ]; then
        echo "${GTK_THEME_OVERRIDE}"
        return 0
    fi

    # Check for saved preference
    if [ -f "${HOME}/.config/gtk-theme" ]; then
        cat "${HOME}/.config/gtk-theme"
        return 0
    fi

    # Default themes by distro
    case "${DISTRO_FAMILY}" in
        Arch)
            echo "adw-gtk3"
            ;;
        Debian|Ubuntu)
            echo "Yaru-dark"
            ;;
        Alpine)
            echo "Adwaita-dark"
            ;;
        Android)
            echo "Material-dark"
            ;;
        *)
            echo "Adwaita-dark"
            ;;
    esac
}
```

### Theme Name Normalisation

```bash
# Normalise GTK theme names for GTK2 compatibility
GTK2_THEME=$(echo "${GTK_THEME}" | sed \
    -e 's/adw-gtk3/AdwaitaDark/g' \
    -e 's/Dark-dark/Dark/g')

# GTK3 and GTK4 use the base theme
GTK3_THEME="${GTK_THEME}"
GTK4_THEME="${GTK_THEME}"

# Special case for themes without GTK4 support
if [ "${GTK_THEME}" = "ZorinGrey" ]; then
    GTK4_THEME="Adwaita-dark"
fi
```

## Font Resolution

### Font Size Calculation

```bash
# Calculate font sizes based on screen height
calculate_font_sizes() {
    local screen_height=$(get_screen_height)

    case ${screen_height} in
        800)
            INTERFACE_FONT_SIZE=11
            TITLEBAR_FONT_SIZE=11
            MONOSPACE_FONT_SIZE=12
            SUBTITLES_FONT_SIZE=17
            ;;
        1080)
            INTERFACE_FONT_SIZE=11
            TITLEBAR_FONT_SIZE=11
            MONOSPACE_FONT_SIZE=12
            SUBTITLES_FONT_SIZE=17
            ;;
        1440)
            INTERFACE_FONT_SIZE=11
            TITLEBAR_FONT_SIZE=12
            MONOSPACE_FONT_SIZE=13
            SUBTITLES_FONT_SIZE=20
            ;;
        2160)
            INTERFACE_FONT_SIZE=11
            TITLEBAR_FONT_SIZE=12
            MONOSPACE_FONT_SIZE=13
            SUBTITLES_FONT_SIZE=20
            ;;
        *)
            INTERFACE_FONT_SIZE=12
            TITLEBAR_FONT_SIZE=12
            MONOSPACE_FONT_SIZE=13
            SUBTITLES_FONT_SIZE=20
            ;;
    esac

    # DPI-dependent adjustment
    local dpi=$(get_screen_dpi)

    if [ "${dpi}" -lt 100 ]; then
        # Low DPI - increase font size
        INTERFACE_FONT_SIZE=$((INTERFACE_FONT_SIZE + 1))
        TITLEBAR_FONT_SIZE=$((TITLEBAR_FONT_SIZE + 1))
        MONOSPACE_FONT_SIZE=$((MONOSPACE_FONT_SIZE + 1))
        SUBTITLES_FONT_SIZE=$((SUBTITLES_FONT_SIZE + 2))
    elif [ "${dpi}" -gt 144 ]; then
        # High DPI - decrease font size
        INTERFACE_FONT_SIZE=$((INTERFACE_FONT_SIZE - 1))
        TITLEBAR_FONT_SIZE=$((TITLEBAR_FONT_SIZE - 1))
        MONOSPACE_FONT_SIZE=$((MONOSPACE_FONT_SIZE - 1))
        SUBTITLES_FONT_SIZE=$((SUBTITLES_FONT_SIZE - 2))
    fi
}
```

### Font Face Selection

```bash
# Set font faces
INTERFACE_FONT_FACE="Sans"
DOCUMENT_FONT_FACE="Sans"
TITLEBAR_FONT_FACE="Sans"
MENU_FONT_FACE="Sans"
MONOSPACE_FONT_FACE="Droid Sans"
EmoJi_FONT_FACE="Apple Color Emoji"

# Adjust for Debian/Ubuntu
if [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
    MONOSPACE_FONT_FACE="Liberation"
fi
```

### Font String Construction

```bash
# Construct font strings for applications
INTERFACE_FONT="${INTERFACE_FONT_FACE} Regular ${INTERFACE_FONT_SIZE}"
DOCUMENT_FONT="${DOCUMENT_FONT_FACE} Regular ${INTERFACE_FONT_SIZE}"
TITLEBAR_FONT="${TITLEBAR_FONT_FACE} Bold ${TITLEBAR_FONT_SIZE}"
MENU_FONT="${MENU_FONT_FACE} Regular ${INTERFACE_FONT_SIZE}"
MONOSPACE_FONT="${MONOSPACE_FONT_FACE} Regular ${MONOSPACE_FONT_SIZE}"
TEXT_EDITOR_FONT="${MONOSPACE_FONT_FACE} Regular ${MONOSPACE_FONT_SIZE}"
SUBTITLES_FONT="${INTERFACE_FONT_FACE} Regular ${SUBTITLES_FONT_SIZE}"
BROWSER_FONT="${INTERFACE_FONT_FACE} Regular ${INTERFACE_FONT_SIZE}"
EMOJI_FONT="${EMOJI_FONT_FACE} Regular ${INTERFACE_FONT_SIZE}"
```

## Application

### GTK Settings Application

```bash
# Apply GTK settings
apply_gtk_settings() {
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
}
```

### Desktop Environment Specific

#### GNOME

```bash
apply_gnome_settings() {
    apply_gtk_settings

    # Additional GNOME settings
    gsettings set org.gnome.desktop.interface enable-animations true
    gsettings set org.gnome.desktop.wm.preferences theme "${GTK3_THEME}"
    gsettings set org.gnome.shell.extensions.user-theme name "${GTK3_THEME}"
}
```

#### KDE

```bash
apply_kde_settings() {
    # Apply via KDE config files
    local kde_config="${HOME}/.config/kdeglobals"

    # Set widget style
    kwriteconfig5 --file "${kde_config}" --group "General" --key "widgetStyle" "${GTK_THEME}"

    # Set font
    kwriteconfig5 --file "${kde_config}" --group "General" --key "font" "${INTERFACE_FONT_FACE},${INTERFACE_FONT_SIZE},-1,5,50,0,0,0,0,0"

    # Set fixed font
    kwriteconfig5 --file "${kde_config}" --group "General" --key "fixedFont" "${MONOSPACE_FONT_FACE},${MONOSPACE_FONT_SIZE},-1,5,50,0,0,0,0,0"
}
```

#### LXDE

```bash
apply_lxde_settings() {
    # LXDE uses GTK settings directly
    apply_gtk_settings

    # LXPanel specific
    if [ -f "${REPO_RC_DIR}/lxde-panel" ]; then
        cp "${REPO_RC_DIR}/lxde-panel" "${HOME}/.config/lxpanel/LXDE/panels/panel"
    fi

    if [ -f "${REPO_RC_DIR}/lxde-dock" ]; then
        cp "${REPO_RC_DIR}/lxde-dock" "${HOME}/.config/lxpanel/LXDE/panels/dock"
    fi
}
```

#### Phosh

```bash
apply_phosh_settings() {
    apply_gtk_settings

    # Phosh specific settings
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK3_THEME}"
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}"
}
```

## Terminal Fonts

```bash
# Configure terminal fonts
configure_terminal_fonts() {
    # Alacritty
    if [ -f "${HOME}/.config/alacritty/alacritty.yml" ]; then
        yq -i ".font.normal.family = \"${MONOSPACE_FONT_FACE}\"" "${HOME}/.config/alacritty/alacritty.yml"
        yq -i ".font.normal.size = ${MONOSPACE_FONT_SIZE}" "${HOME}/.config/alacritty/alacritty.yml"
    fi

    # Kitty
    if [ -f "${HOME}/.config/kitty/kitty.conf" ]; then
        sed -i "s/^font_family.*/font_family ${MONOSPACE_FONT_FACE}/" "${HOME}/.config/kitty/kitty.conf"
        sed -i "s/^font_size.*/font_size ${MONOSPACE_FONT_SIZE}/" "${HOME}/.config/kitty/kitty.conf"
    fi

    # GNOME Terminal
    if command_exists gsettings; then
        local profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" font "${MONOSPACE_FONT_FACE} ${MONOSPACE_FONT_SIZE}"
    fi
}
```

## Logging

### Theme and Font Resolution Log

```
=== Theme and Font Resolution ===
[INFO] Screen height: 1080
[INFO] Screen DPI: 96
[INFO] Desktop environment: GNOME
[INFO] Detected theme mode: dark
[INFO] Selected GTK theme: adw-gtk3
[INFO] Normalised GTK2 theme: AdwaitaDark
[INFO] Interface font: Sans Regular 11
[INFO] Monospace font: Droid Sans Regular 12
[INFO] Applying GTK settings
[INFO] Applying GNOME settings
[INFO] Configuring terminal fonts
[SUCCESS] Theme and font resolution complete
```

## Performance

### Typical Execution Time

- Theme resolution: <1 second
- Font resolution: <1 second
- Application: 1-3 seconds
- **Total**: 1-5 seconds

### Optimisation

- Cache resolved values
- Skip unchanged configurations
- Parallel application to different systems
- Lazy loading of desktop environment specific code