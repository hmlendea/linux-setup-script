# Presentation Component

This document provides a deep dive into the presentation component,
which handles theming, visual configuration, and desktop environment
personalisation.

## Overview

**Location**: `scripts/common/apps.sh` (presentation-related functions)

**Purpose**: Theme management, icon sets, cursor themes, GTK configuration,
and desktop personalisation utilities.

**Consumers**: `configure-system.sh`, `configure-default-apps.sh`,
`configure-hardware-integration.sh`, `update-resources.sh`

## Core Functions

### 1. Theme Management

```bash
# Set GTK theme
set_gtk_theme <theme_name>

# Set GTK2 theme
set_gtk2_theme <theme_name>

# Set GTK3 theme
set_gtk3_theme <theme_name>

# Set GTK4 theme
set_gtk4_theme <theme_name>

# Set icon theme
set_icon_theme <theme_name>

# Set cursor theme
set_cursor_theme <theme_name>

# Set window border theme
set_border_theme <theme_name>

# Apply theme immediately
apply_theme <theme_name>
```

### 2. Font Management

```bash
# Set interface font
set_interface_font <font_name>

# Set document font
set_document_font <font_name>

# Set monospace font
set_monospace_font <font_name>

# Set font size
set_font_size <size>

# Apply font configuration
apply_fonts <font_name> <size>
```

### 3. Visual Effects

```bash
# Set compositor enablement
set_compositor_enabled <enabled>

# Set blur effects
set_blur_effects <enabled>

# Set transparency effects
set_transparency_enabled <enabled>

# Set animation duration
set_animation_duration <milliseconds>
```

## Theme Application Patterns

### Pattern 1: System Theme Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Detect desktop environment
detect_desktop_environment

# Apply theme based on DE
if [ "${DESKTOP_ENVIRONMENT}" = "gnome" ]; then
    set_gsettings "org.gnome.desktop.interface" "gtk-theme" "${GTK_THEME}"
    set_gsettings "org.gnome.desktop.interface" "icon-theme" "${ICON_THEME}"
    set_gsettings "org.gnome.desktop.interface" "cursor-theme" "${CURSOR_THEME}"
    set_gsettings "org.gnome.desktop.interface" "color-scheme" "prefer-dark"
elif [ "${DESKTOP_ENVIRONMENT}" = "kde" ]; then
    set_gsettings "org.kde.desktop" "theme" "${GTK_THEME}"
    set_gsettings "org.kde.desktop" "icon-theme" "${ICON_THEME}"
    set_gsettings "org.kde.desktop" "cursor-theme" "${CURSOR_THEME}"
elif [ "${DESKTOP_ENVIRONMENT}" = "xfce" ]; then
    set_gsettings "xsettings" "Net/ThemeName" "${GTK_THEME}"
    set_gsettings "xsettings" "Net/IconThemeName" "${ICON_THEME}"
    set_gsettings "xsettings" "Net/CursorThemeName" "${CURSOR_THEME}"
fi

# Apply to system configs if available
if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
    update_file_if_distinct "${REPO_RC_DIR}/system/gtk-3.0/settings.ini" \
        "/etc/gtk-3.0/settings.ini"
fi
```

### Pattern 2: User Theme Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"

# Apply theme to user config files
update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bashrc"

# Create theme symlinks
create_symlink "${REPO_RC_DIR}/themes/current" "${HOME}/.themes/current"
create_symlink "${REPO_RC_DIR}/icons/current" "${HOME}/.icons/current"
```

### Pattern 3: Theme Fallback Logic

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"

# Try primary theme, fall back to default
set_gtk_theme "${GTK_THEME}" || {
    log_warn "Failed to set theme ${GTK_THEME}, falling back to Adwaita"
    set_gtk_theme "Adwaita"
}
```

## Configuration Invariants

1. **Idempotency** — All theme writes use `update_file_if_distinct`
2. **Platform guards** — GSettings wrapped in `has_gsettings_session`
3. **DE awareness** — Theme commands specific to desktop environment
4. **Privilege separation** — System themes via `run_as_su`, user themes directly
5. **No runtime templating** — Themes deployed as-is; no variable interpolation
6. **Single source of truth** — Each theme setting derived in exactly one place

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `set_gtk_theme` | Theme not found | Error message, tries fallback |
| `set_gsettings` | Schema not found | Error message, skips GSettings |
| `update_file_if_distinct` | Permission denied | Error message, returns 2 |
| `create_symlink` | Target exists | Error message, returns 1 |

## Performance Considerations

- **Batch theme applies** — Multiple theme settings in one call
- **Cache theme configs** — Theme settings cached during session
- **Minimal subprocesses** — GSettings preferred over theme config files
- **Skip if unchanged** — `update_file_if_distinct` avoids redundant writes

## Security Considerations

- **No arbitrary theme execution** — Theme names validated
- **Path safety** — Theme paths resolved safely
- **Privilege separation** — System themes via `run_as_su`
- **No eval/exec** on theme values

## Testing

### Unit Tests

```bash
function test_set_gtk_theme() {
    # Test theme setting
    set_gtk_theme "Adwaita-dark"
    assertEquals "theme set" "Adwaita-dark" "$(get_gtk_theme)"
}

function test_set_icon_theme() {
    # Test icon theme setting
    set_icon_theme "Papirus-Dark"
    assertEquals "icon theme set" "Papirus-Dark" "$(get_icon_theme)"
}

function test_apply_theme() {
    # Test theme application
    apply_theme "Adwaita-dark"
    assertTrue "theme applied" "[ -f /tmp/theme-applied ]"
}
```

### Integration Tests

```bash
function test_theme_detection() {
    detect_desktop_environment
    assertNotNull "DESKTOP_ENVIRONMENT is set" "${DESKTOP_ENVIRONMENT}"

    # Test theme setting works
    set_gtk_theme "${GTK_THEME}"
    assertNotNull "GTK theme applied" "${GTK_THEME}"
}
```

## Future Enhancements

1. **Theme engine support** — Support for multiple theme engines (adwaita, breeze, etc.)
2. **Theme import/export** — Import/export theme configurations
3. **Dynamic theme switching** — Automatic theme switching based on time/day
4. **Wallpaper management** — Set/change desktop wallpapers
5. **Color scheme generation** — Generate complementary color schemes
6. **Theme compatibility** — Check theme compatibility across DEs