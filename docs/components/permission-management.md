# Permission Management

This document describes the permission management system for Flatpak,
GNOME, and Android/Termux platforms.

## Overview

The permission management module provides a unified interface for
managing application permissions across different sandboxing and
permission systems.

## Flatpak Permissions

### Permission Model

Flatpak uses a portal-based permission system where applications
request access to resources through portals.

```bash
# scripts/common/apps.sh

# Grant permission to Flatpak app
flatpak_grant_permission() {
    local app_id="$1"
    local permission="$2"

    log_info "Granting ${permission} to ${app_id}"
    flatpak permission-set "${permission}" yes "${app_id}"
}

# Revoke permission from Flatpak app
flatpak_revoke_permission() {
    local app_id="$1"
    local permission="$2"

    log_info "Revoking ${permission} from ${app_id}"
    flatpak permission-set "${permission}" no "${app_id}"
}

# Reset permission to default
flatpak_reset_permission() {
    local app_id="$1"
    local permission="$2"

    log_info "Resetting ${permission} for ${app_id}"
    flatpak permission-set "${permission}" reset "${app_id}"
}

# List permissions for app
flatpak_list_permissions() {
    local app_id="$1"

    flatpak permission-show "${app_id}"
}
```

### Common Permissions

| Permission | Description | Portal |
|------------|-------------|--------|
| filesystem | File system access | filechooser |
| filesystem:home | Home directory access | filechooser |
| filesystem:host | Host filesystem access | filechooser |
| network | Network access | network |
| bluetooth | Bluetooth access | bluetooth |
| camera | Camera access | camera |
| microphone | Microphone access | microphone |
| location | Location access | location |
| notifications | Desktop notifications | notification |
| print | Printing access | print |
| cups | CUPS printing | print |

### Permission Presets

```bash
# Development preset
flatpak_dev_permissions() {
    local app_id="$1"

    flatpak_grant_permission "${app_id}" "filesystem:home"
    flatpak_grant_permission "${app_id}" "filesystem:host"
    flatpak_grant_permission "${app_id}" "network"
    flatpak_grant_permission "${app_id}" "dri"
    flatpak_grant_permission "${app_id}" "wayland"
    flatpak_grant_permission "${app_id}" "x11"
}

# Gaming preset
flatpak_gaming_permissions() {
    local app_id="$1"

    flatpak_grant_permission "${app_id}" "filesystem:home"
    flatpak_grant_permission "${app_id}" "network"
    flatpak_grant_permission "${app_id}" "dri"
    flatpak_grant_permission "${app_id}" "wayland"
    flatpak_grant_permission "${app_id}" "x11"
    flatpak_grant_permission "${app_id}" "controller"
    flatpak_grant_permission "${app_id}" "bluetooth"
}

# Media preset
flatpak_media_permissions() {
    local app_id="$1"

    flatpak_grant_permission "${app_id}" "filesystem:home"
    flatpak_grant_permission "${app_id}" "network"
    flatpak_grant_permission "${app_id}" "dri"
    flatpak_grant_permission "${app_id}" "wayland"
    flatpak_grant_permission "${app_id}" "x11"
    flatpak_grant_permission "${app_id}" "camera"
    flatpak_grant_permission "${app_id}" "microphone"
}
```

## GNOME Permissions

### App Permissions

```bash
# scripts/common/apps.sh

# Grant GNOME app permission
gnome_grant_permission() {
    local app_id="$1"
    local permission="$2"

    log_info "Granting ${permission} to ${app_id}"
    gsettings set "org.gnome.desktop.app-permissions.${app_id}" "${permission}" true
}

# Revoke GNOME app permission
gnome_revoke_permission() {
    local app_id="$1"
    local permission="$2"

    log_info "Revoking ${permission} from ${app_id}"
    gsettings set "org.gnome.desktop.app-permissions.${app_id}" "${permission}" false
}

# List GNOME app permissions
gnome_list_permissions() {
    local app_id="$1"

    gsettings list-recursively "org.gnome.desktop.app-permissions.${app_id}"
}
```

### Common GNOME Permissions

| Permission | Description |
|------------|-------------|
| camera | Camera access |
| microphone | Microphone access |
| location | Location access |
| notifications | Notifications |
| geoclue | Geolocation service |
| gnome-shell-extensions | Shell extensions |

## Android/Termux Permissions

### Termux API Permissions

```bash
# scripts/common/apps.sh

# Request Termux permission
termux_request_permission() {
    local permission="$1"

    log_info "Requesting Termux permission: ${permission}"
    termux-api "${permission}" || {
        log_warn "Termux API not available or permission denied"
        return 1
    }
}

# Check Termux permission
termux_check_permission() {
    local permission="$1"

    termux-api "${permission}" --check 2>/dev/null
}
```

### Common Termux Permissions

| Permission | Description |
|------------|-------------|
| storage | Storage access (termux-setup-storage) |
| camera | Camera access |
| microphone | Microphone access |
| location | Location access |
| contacts | Contacts access |
| sms | SMS access |
| phone | Phone state access |
| notification | Notification access |
| bluetooth | Bluetooth access |
| wifi | WiFi scan access |

### Storage Access

```bash
# Setup Termux storage access
termux_setup_storage() {
    if is_android; then
        log_info "Setting up Termux storage access"
        termux-setup-storage

        # Wait for user confirmation
        local timeout=30
        while [ ${timeout} -gt 0 ]; do
            if [ -d "${HOME}/storage" ]; then
                log_success "Storage access granted"
                return 0
            fi
            sleep 1
            timeout=$((timeout - 1))
        done

        log_warn "Storage access not granted within timeout"
        return 1
    fi
}
```

## Permission Profiles

### Profile Definition

```bash
# Permission profiles for common app categories
declare -A PERMISSION_PROFILES=(
    ["development"]="filesystem:home filesystem:host network dri wayland x11"
    ["gaming"]="filesystem:home network dri wayland x11 controller bluetooth"
    ["media"]="filesystem:home network dri wayland x11 camera microphone"
    ["communication"]="filesystem:home network camera microphone notifications"
    ["productivity"]="filesystem:home network notifications print"
    ["system"]="filesystem:host network dri wayland x11"
)
```

### Apply Profile

```bash
# Apply permission profile to Flatpak app
apply_flatpak_profile() {
    local app_id="$1"
    local profile="$2"

    local permissions="${PERMISSION_PROFILES[${profile}]}"

    if [ -z "${permissions}" ]; then
        log_error "Unknown profile: ${profile}"
        return 1
    fi

    for perm in ${permissions}; do
        flatpak_grant_permission "${app_id}" "${perm}"
    done
}

# Apply permission profile to GNOME app
apply_gnome_profile() {
    local app_id="$1"
    local profile="$2"

    # Map Flatpak permissions to GNOME permissions
    case "${profile}" in
        development)
            gnome_grant_permission "${app_id}" "camera"
            gnome_grant_permission "${app_id}" "microphone"
            gnome_grant_permission "${app_id}" "location"
            ;;
        gaming)
            gnome_grant_permission "${app_id}" "camera"
            gnome_grant_permission "${app_id}" "microphone"
            ;;
        media)
            gnome_grant_permission "${app_id}" "camera"
            gnome_grant_permission "${app_id}" "microphone"
            gnome_grant_permission "${app_id}" "notifications"
            ;;
    esac
}
```

## Permission Audit

### Audit All Permissions

```bash
# Audit Flatpak permissions
audit_flatpak_permissions() {
    log_section "Flatpak Permission Audit"

    local apps=$(flatpak list --app --columns=application)

    for app in ${apps}; do
        log_info "Permissions for ${app}:"
        flatpak permission-show "${app}" | while read -r line; do
            log_info "  ${line}"
        done
    done
}

# Audit GNOME permissions
audit_gnome_permissions() {
    log_section "GNOME Permission Audit"

    gsettings list-schemas | grep "app-permissions" | while read -r schema; do
        log_info "Permissions for ${schema}:"
        gsettings list-recursively "${schema}" | while read -r line; do
            log_info "  ${line}"
        done
    done
}
```

## Integration with Setup Scripts

### Configure Flatpak Permissions

```bash
# scripts/configure-apps.sh

configure_flatpak_permissions() {
    log_section "Configuring Flatpak permissions"

    # Development tools
    apply_flatpak_profile "com.visualstudio.code" "development"
    apply_flatpak_profile "org.gnome.Builder" "development"
    apply_flatpak_profile "com.jetbrains.IntelliJ-IDEA-Community" "development"

    # Gaming
    apply_flatpak_profile "com.valvesoftware.Steam" "gaming"
    apply_flatpak_profile "net.lutris.Lutris" "gaming"
    apply_flatpak_profile "org.ppsspp.PPSSPP" "gaming"

    # Media
    apply_flatpak_profile "org.videolan.VLC" "media"
    apply_flatpak_profile "com.obsproject.Studio" "media"

    # Communication
    apply_flatpak_profile "org.telegram.desktop" "communication"
    apply_flatpak_profile "com.discordapp.Discord" "communication"
    apply_flatpak_profile "org.signal.Signal" "communication"
}
```

### Configure Termux Permissions

```bash
# scripts/configure-system.sh

configure_termux_permissions() {
    if ! is_android; then
        return 0
    fi

    log_section "Configuring Termux permissions"

    # Storage (required for most operations)
    termux_setup_storage

    # Optional permissions based on use case
    if is_development_device; then
        termux_request_permission "camera"
        termux_request_permission "microphone"
    fi

    if is_gaming_device; then
        termux_request_permission "bluetooth"
        termux_request_permission "wifi"
    fi
}
```

## Best Practices

1. **Principle of least privilege** — Grant only necessary permissions
2. **Profile-based** — Use predefined profiles for consistency
3. **Audit regularly** — Check permissions periodically
4. **User consent** — Request permissions interactively when possible
5. **Document exceptions** — Record why specific permissions are needed

## Future Enhancements

1. **Portal integration** — Use xdg-desktop-portal for unified permissions
2. **Permission inheritance** — Inherit from parent profiles
3. **Temporary permissions** — Time-limited permission grants
4. **Permission UI** — Graphical permission management
5. **Policy engine** — Centralized permission policies