# System Configuration Flow

This document describes the system configuration flow, covering all system-level
configuration applied during Phase 3 of the provisioning process.

## Overview

The system configuration flow applies system-wide settings including locale,
time, kernel parameters, services, hardware integration, and GRUB configuration.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    System Configuration Flow                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    System Configuration                         │
│  • configure-system.sh (user)                                   │
│  • configure-system.sh (root)                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Locale Configuration                         │
│  • configure-locale.sh (root)                                   │
│  • Set LANG, LC_ALL, LOCALE                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Time Configuration                            │
│  • configure-time.sh (root)                                     │
│  • Set timezone, NTP, hwclock                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Service Configuration                         │
│  • configure-services-user.sh (user)                            │
│  • configure-services-system.sh (root)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Hardware Integration                         │
│  • configure-hardware-integration.sh (root)                     │
│  • GPU, audio, power, thermal, input                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GRUB Configuration                            │
│  • update-grub.sh (root)                                        │
│  • Apply kernel parameters, multi-boot entries                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Directory Configuration                      │
│  • configure-directories.sh (user)                              │
│  • Create user directories                                      │
└─────────────────────────────────────────────────────────────────┘
```

## System Configuration

### Script: `scripts/configure-system.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

configure_system() {
    log_section "System Configuration"

    # User-level configuration
    configure_system_user

    # Root-level configuration (if privileges available)
    if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
        run_as_su configure_system_root
    fi

    log_success "System configuration complete"
}

configure_system_user() {
    log_subsection "User-Level System Configuration"

    # Configure terminal
    configure_terminal

    # Configure fonts
    configure_fonts

    # Configure themes
    configure_themes

    # Configure desktop environment
    configure_desktop_environment

    # Configure input devices
    configure_input_devices

    log_info "User-level system configuration complete"
}

configure_system_root() {
    log_subsection "Root-Level System Configuration"

    # Configure kernel parameters
    configure_kernel_parameters

    # Configure systemd
    configure_systemd

    # Configure users and groups
    configure_users_and_groups

    # Configure permissions
    configure_permissions

    log_info "Root-level system configuration complete"
}
```

### Terminal Configuration

```bash
configure_terminal() {
    log_info "Configuring terminal..."

    # Set terminal size based on screen resolution
    TERMINAL_SIZE_COLS=$(get_terminal_cols)
    TERMINAL_SIZE_ROWS=$(get_terminal_rows)

    # Configure terminal colors
    configure_terminal_colors

    # Configure terminal cursor
    configure_terminal_cursor

    log_info "Terminal configured"
}

configure_terminal_colors() {
    # Set terminal color scheme based on theme
    if [ "${DESKTOP_THEME_IS_DARK}" = "true" ]; then
        TERMINAL_BG="${GTK_THEME_BG_COLOUR}"
        TERMINAL_FG="#FFFFFF"
    else
        TERMINAL_BG=""
        TERMINAL_FG="#000000"
    fi

    # Set terminal palette
    TERMINAL_BLACK_D="#241F31"
    TERMINAL_RED_D="#C01C28"
    TERMINAL_GREEN_D="#2EC27E"
    TERMINAL_YELLOW_D="#F5C211"
    TERMINAL_BLUE_D="#1E78E4"
    TERMINAL_PURPLE_D="#9841BB"
    TERMINAL_CYAN_D="#089195"
    TERMINAL_WHITE_D="#A8A8A8"

    TERMINAL_BLACK_L="#241F31"
    TERMINAL_RED_L="#ED333B"
    TERMINAL_GREEN_L="#57E389"
    TERMINAL_YELLOW_L="#F8E45C"
    TERMINAL_BLUE_L="#51A1FF"
    TERMINAL_PURPLE_L="#C061CB"
    TERMINAL_CYAN_L="#93D6F0"
    TERMINAL_WHITE_L="#FFFFFF"
}
```

### Font Configuration

```bash
configure_fonts() {
    log_info "Configuring fonts..."

    # Set font sizes based on screen resolution
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

    # Set font faces
    INTERFACE_FONT_FACE="Sans"
    DOCUMENT_FONT_FACE="Sans"
    TITLEBAR_FONT_FACE="Sans"
    MENU_FONT_FACE="Sans"
    MONOSPACE_FONT_FACE="Droid Sans"
    EMOJI_FONT_FACE="Apple Color Emoji"

    # Adjust for Debian/Ubuntu
    if [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        MONOSPACE_FONT_FACE="Liberation"
    fi

    log_info "Fonts configured"
}
```

### Theme Configuration

```bash
configure_themes() {
    log_info "Configuring themes..."

    # Determine theme mode (dark/light)
    GTK_THEME_VARIANT=$(get_theme_mode)
    DESKTOP_THEME_IS_DARK=$([ "${GTK_THEME_VARIANT}" = "dark" ] && echo "true" || echo "false")
    DESKTOP_THEME_IS_DARK_BINARY=$([ "${DESKTOP_THEME_IS_DARK}" = "true" ] && echo "1" || echo "0")

    # Determine GTK theme
    GTK_THEME=$(get_theme)

    # Normalise theme names
    GTK2_THEME=$(echo "${GTK_THEME}" | sed \
        -e 's/adw-gtk3/AdwaitaDark/g' \
        -e 's/Dark-dark/Dark/g')

    GTK3_THEME="${GTK_THEME}"
    GTK4_THEME="${GTK_THEME}"

    # Fallback for GTK4
    if [ "${GTK_THEME}" = "ZorinGrey" ]; then
        GTK4_THEME="Adwaita-dark"
    fi

    # Set icon theme
    ICON_THEME="Papirus-Dark"
    ICON_THEME_DIRECTORY_COLOUR="grey"

    # Set cursor theme
    CURSOR_THEME="Vimix-white-cursors"

    # Set background colour
    if [ "${GTK_THEME}" = "ZorinGrey" ]; then
        GTK_THEME_BG_COLOUR="#202020"
    else
        GTK_THEME_BG_COLOUR="#1c1c1f"
    fi

    log_info "Themes configured"
}
```

### Desktop Environment Configuration

```bash
configure_desktop_environment() {
    log_info "Configuring desktop environment..."

    case "${DESKTOP_ENVIRONMENT}" in
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
            log_warn "Unknown desktop environment: ${DESKTOP_ENVIRONMENT}"
            ;;
    esac

    log_info "Desktop environment configured"
}

configure_gnome() {
    # Set GNOME theme
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK3_THEME}"
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME}"
    gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME}"

    # Set GNOME font
    gsettings set org.gnome.desktop.interface font-name "${INTERFACE_FONT_FACE} ${INTERFACE_FONT_SIZE}"
    gsettings set org.gnome.desktop.interface monospace-font-name "${MONOSPACE_FONT_FACE} ${MONOSPACE_FONT_SIZE}"

    # Set GNOME color scheme
    if [ "${DESKTOP_THEME_IS_DARK}" = "true" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    else
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    fi
}

configure_lxde() {
    # Set LXDE theme
    update_file_if_distinct \
        "${REPO_RC_DIR}/lxde-panel" \
        "${HOME}/.config/lxpanel/LXDE/panels/panel"

    update_file_if_distinct \
        "${REPO_RC_DIR}/lxde-dock" \
        "${HOME}/.config/lxpanel/LXDE/panels/dock"
}
```

## Locale Configuration

### Script: `scripts/configure-locale.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_locale() {
    log_section "Locale Configuration"

    # Set locale
    if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
        run_as_su configure_locale_root
    fi

    # Set user locale
    configure_locale_user

    log_success "Locale configured"
}

configure_locale_root() {
    log_subsection "System Locale"

    # Generate locale
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        sed -i 's/^#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
        locale-gen
    elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        locale-gen en_US.UTF-8
    fi

    # Set system locale
    update_file_if_distinct \
        "${REPO_RC_DIR}/locale" \
        "/etc/locale.conf"

    log_info "System locale configured"
}

configure_locale_user() {
    log_subsection "User Locale"

    # Set user locale
    update_file_if_distinct \
        "${REPO_RC_DIR}/locale" \
        "${HOME}/.config/locale.conf"

    log_info "User locale configured"
}
```

## Time Configuration

### Script: `scripts/configure-time.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_time() {
    log_section "Time Configuration"

    if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
        run_as_su configure_time_root
    fi

    log_success "Time configured"
}

configure_time_root() {
    log_subsection "System Time"

    # Set timezone
    if [ -n "${TIMEZONE:-}" ]; then
        ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
        log_info "Timezone set to: ${TIMEZONE}"
    fi

    # Enable NTP
    if command_exists timedatectl; then
        timedatectl set-ntp true
    elif [ "${DISTRO_FAMILY}" = "Arch" ]; then
        systemctl enable --now systemd-timesyncd
    elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        systemctl enable --now systemd-timesyncd
    fi

    # Set hwclock
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        hwclock --systohc --utc
    fi

    log_info "System time configured"
}
```

## Service Configuration

### Script: `scripts/configure-services-system.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_services_system() {
    log_section "System Service Configuration"

    if [ "${HAS_SU_PRIVILEGES}" != "true" ]; then
        log_warn "No SU privileges, skipping system service configuration"
        return 0
    fi

    # Enable system services
    local services=(
        "NetworkManager"
        "bluetooth"
        "cups"
        "fstrim.timer"
        "logrotate.timer"
        "reflector.timer"
    )

    for service in "${services[@]}"; do
        if command_exists systemctl; then
            systemctl enable "${service}"
            log_info "Enabled: ${service}"
        fi
    done

    # Start services
    local start_services=(
        "NetworkManager"
        "bluetooth"
        "cups"
    )

    for service in "${start_services[@]}"; do
        if command_exists systemctl; then
            systemctl start "${service}"
            log_info "Started: ${service}"
        fi
    done

    log_success "System services configured"
}
```

### Script: `scripts/configure-services-user.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_services_user() {
    log_section "User Service Configuration"

    # Enable user services
    local services=(
        "pipewire"
        "pipewire-pulse"
        "xdg-desktop-portal"
    )

    for service in "${services[@]}"; do
        if command_exists systemctl; then
            systemctl --user enable "${service}" 2>/dev/null || true
            log_info "Enabled user service: ${service}"
        fi
    done

    log_success "User services configured"
}
```

## Hardware Integration

### Script: `scripts/configure-hardware-integration.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_hardware_integration() {
    log_section "Hardware Integration"

    if [ "${HAS_SU_PRIVILEGES}" != "true" ]; then
        log_warn "No SU privileges, skipping hardware integration"
        return 0
    fi

    # Configure GPU
    configure_gpu

    # Configure power management
    configure_power_management

    # Configure audio
    configure_audio

    # Configure input devices
    configure_input_devices

    # Configure thermal management
    configure_thermal_management

    # Configure device-specific hardware
    configure_device_specific

    log_success "Hardware integration complete"
}

configure_gpu() {
    log_subsection "GPU Configuration"

    case "${GPU_FAMILY}" in
        Intel)
            # Enable Intel GPU
            modprobe i915
            # Configure power management
            echo 'options i915 enable_dc=1' > /etc/modprobe.d/i915.conf
            ;;
        AMD)
            # Enable AMD GPU
            modprobe amdgpu
            # Configure power management
            echo 'options amdgpu ppfeaturemask=0xffffffff' > /etc/modprobe.d/amdgpu.conf
            ;;
        Nvidia)
            # Install NVIDIA drivers
            if [ "${DISTRO_FAMILY}" = "Arch" ]; then
                pacman -S --noconfirm nvidia nvidia-utils
            elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
                apt install -y nvidia-driver nvidia-utils
            fi
            ;;
        Qualcomm)
            # Enable Qualcomm GPU
            modprobe adreno
            ;;
    esac

    log_info "GPU configured: ${GPU_FAMILY}"
}

configure_power_management() {
    log_subsection "Power Management"

    # Install TLP
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        pacman -S --noconfirm tlp
    elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        apt install -y tlp
    fi

    # Enable TLP
    systemctl enable tlp
    systemctl start tlp

    # Configure CPU frequency scaling
    if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
        echo 'GOVERNOR="powersave"' > /etc/tlp.conf
    else
        echo 'GOVERNOR="performance"' > /etc/tlp.conf
    fi

    log_info "Power management configured"
}

configure_audio() {
    log_subsection "Audio Configuration"

    # Install PipeWire
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa
    elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        apt install -y pipewire pipewire-pulse pipewire-alsa
    fi

    # Enable PipeWire
    systemctl --user enable pipewire pipewire-pulse
    systemctl --user start pipewire pipewire-pulse

    log_info "Audio configured"
}

configure_input_devices() {
    log_subsection "Input Device Configuration"

    # Configure keyboard layout
    if [ -f "${REPO_KEYBOARD_LAYOUTS_DIR}/ro" ]; then
        cp "${REPO_KEYBOARD_LAYOUTS_DIR}/ro" /usr/share/X11/xkb/symbols/ro
    fi

    # Configure touchpad
    update_file_if_distinct \
        "${REPO_RC_DIR}/inputrc" \
        "/etc/inputrc"

    log_info "Input devices configured"
}

configure_thermal_management() {
    log_subsection "Thermal Management"

    # Install thermald
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        pacman -S --noconfirm thermald
    elif [ "${DISTRO_FAMILY}" = "Debian" ] || [ "${DISTRO_FAMILY}" = "Ubuntu" ]; then
        apt install -y thermald
    fi

    # Enable thermald
    systemctl enable thermald
    systemctl start thermald

    log_info "Thermal management configured"
}

configure_device_specific() {
    log_subsection "Device-Specific Configuration"

    case "${DEVICE_MODEL}" in
        "Argon ONE UP")
            # Configure Argon ONE UP
            if [ -f "${REPO_RC_DIR}/boot_firmware_config_argononeup.txt" ]; then
                update_file_if_distinct \
                    "${REPO_RC_DIR}/boot_firmware_config_argononeup.txt" \
                    "/boot/firmware/config.txt"
            fi
            ;;
        "Steam Deck")
            # Configure Steam Deck
            log_info "Steam Deck detected, applying device-specific config"
            ;;
    esac

    log_info "Device-specific configuration complete"
}
```

## GRUB Configuration

### Script: `scripts/update-grub.sh`

```bash
#!/bin/bash
set -euo pipefail

update_grub() {
    log_section "GRUB Configuration"

    if [ "${HAS_SU_PRIVILEGES}" != "true" ]; then
        log_warn "No SU privileges, skipping GRUB configuration"
        return 0
    fi

    if ! command_exists grub-mkconfig; then
        log_warn "grub-mkconfig not found, skipping GRUB update"
        return 0
    fi

    # Update GRUB configuration
    grub-mkconfig -o /boot/grub/grub.cfg

    log_success "GRUB configuration updated"
}
```

## Directory Configuration

### Script: `scripts/configure-directories.sh`

```bash
#!/bin/bash
set -euo pipefail

configure_directories() {
    log_section "Directory Configuration"

    # Create user directories
    local dirs=(
        "${HOME}/Documents"
        "${HOME}/Downloads"
        "${HOME}/Projects"
        "${HOME}/.local/share"
        "${HOME}/.config"
        "${HOME}/.cache"
    )

    for dir in "${dirs[@]}"; do
        ensure_directory "${dir}"
    done

    # Set directory permissions
    chmod 700 "${HOME}/.ssh" 2>/dev/null || true
    chmod 700 "${HOME}/.gnupg" 2>/dev/null || true

    log_success "Directories configured"
}
```

## Error Handling

### Configuration Failures

```bash
# Continue on non-critical failures
configure_with_fallback() {
    local config_func="$1"
    local critical="${2:-false}"

    if ! ${config_func}; then
        if [ "${critical}" = "true" ]; then
            log_error "Critical configuration failed: ${config_func}"
            return 1
        else
            log_warn "Non-critical configuration failed: ${config_func}"
            return 0
        fi
    fi

    return 0
}
```

## Logging

### System Configuration Log

```
=== System Configuration ===
[INFO] Configuring terminal...
[INFO] Terminal configured
[INFO] Configuring fonts...
[INFO] Fonts configured
[INFO] Configuring themes...
[INFO] Themes configured
[INFO] Configuring desktop environment...
[INFO] Desktop environment configured

=== Locale Configuration ===
[INFO] System locale configured
[INFO] User locale configured

=== Time Configuration ===
[INFO] Timezone set to: Europe/Bucharest
[INFO] System time configured

=== System Service Configuration ===
[INFO] Enabled: NetworkManager
[INFO] Enabled: bluetooth
[INFO] Enabled: cups
[INFO] Started: NetworkManager
[INFO] Started: bluetooth
[INFO] Started: cups

=== Hardware Integration ===
[INFO] GPU configured: Intel
[INFO] Power management configured
[INFO] Audio configured
[INFO] Input devices configured
[INFO] Thermal management configured
[INFO] Device-specific configuration complete

=== GRUB Configuration ===
[SUCCESS] GRUB configuration updated

=== Directory Configuration ===
[SUCCESS] Directories configured
```

## Performance

### Typical Execution Times

| Component | Time |
|-----------|------|
| System configuration | 2-5 seconds |
| Locale configuration | 1-3 seconds |
| Time configuration | 1-2 seconds |
| Service configuration | 2-5 seconds |
| Hardware integration | 5-15 seconds |
| GRUB configuration | 1-3 seconds |
| Directory configuration | <1 second |
| **Total** | **12-30 seconds** |

### Optimisation

- Skip already-configured items
- Batch service enable/start operations
- Use idempotent file writes
- Parallelise independent configurations