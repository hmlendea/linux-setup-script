# Configuration Management Component

This document provides a deep dive into the configuration management component,
which handles all configuration file manipulation across INI, JSON, XML,
GSettings, modprobe, and PulseAudio formats.

## Overview

**Location**: `scripts/common/config.sh`

**Purpose**: Generic configuration value get/set with section support for
multiple file formats, plus specialised helpers for system configuration
(modprobe, GSettings, PulseAudio).

**Consumers**: All configuration scripts (`configure-system.sh`,
`configure-locale.sh`, `configure-time.sh`, `update-grub.sh`,
`update-rcs.sh`, `update-resources.sh`, `configure-permissions.sh`,
`configure-hardware-integration.sh`)

## Core Functions

### 1. Generic Configuration Access

```bash
# Get value from config file
get_config_value [--separator=] <file> <key>

# Set value in config file (INI/JSON/XML)
set_config_value [--separator=] [--quote=] [--section=] <file> <key> <value>

# Bulk set multiple values
set_config_values [--section=] <file> <key1> <val1> [key2 val2...]

# Append line if not present
append_line <file> <line>

# Copy file only if content differs
update_file_if_distinct <src> <dst>

# File/directory creation
create_file <path>
create_directory <path>
create_symlink <target> <link>
remove <path>
read_file <path>
```

### 2. INI File Handling (`set_ini_config_value`)

**Features**:
- Section support via `--section`
- Custom separator via `--separator` (default `=`, becomes `: ` for `:`)
- Custom quoting via `--quote` (default `'`, empty for no quotes)
- Creates section header if missing
- Updates existing key or appends to section

**Example**:
```bash
# Set value in sectioned INI
set_config_value --section "Manager" /etc/systemd/system.conf \
    "DefaultTimeoutStartSec" "90s"

# Set value in non-sectioned INI
set_config_value /etc/default/grub "GRUB_TIMEOUT" "5"
```

### 3. JSON File Handling (`set_json_property`)

**Features**:
- Uses `jq` if available (preferred)
- Falls back to `sed` for simple replacements
- Preserves formatting when using `jq`

**Example**:
```bash
# Set JSON property
set_config_value /path/to/config.json "key" "value"
# Internally calls: jq --arg key "key" --arg val "value" '.[$key] = $val'
```

### 4. XML File Handling (`set_xml_node`)

**Features**:
- Basic `sed`-based replacement for simple XML
- Not a full XML parser; suitable for simple config files

**Example**:
```bash
# Set XML node value
set_config_value /path/to/config.xml "node" "value"
```

## Specialised System Configuration Helpers

### 5. Firefox Configuration (`set_firefox_config`)

```bash
set_firefox_config <profile_dir> <key> <value>
# Writes to prefs.js in Firefox profile
```

### 6. Kernel Module Parameters (`set_modprobe_option`)

```bash
set_modprobe_option <module> <parameter> <value>
# Creates/updates /etc/modprobe.d/<module>.conf
# Example: set_modprobe_option i915 enable_guc 3
# Result: options i915 enable_guc=3
```

### 7. PulseAudio Module Options (`set_pulseaudio_module_option`)

```bash
set_pulseaudio_module_option <module> <option> <value>
# Creates/updates /etc/pulse/default.pa.d/<module>.conf
```

### 8. GSettings Integration

**Session Check**:
```bash
has_gsettings_session
# Returns 0 if GSettings accessible (DBus session)
```

**GSettings Operations**:
```bash
call_gsettings <schema> <key> <value>
# Wrapper for gsettings set

get_gsetting <schema> <key>
# Returns current value

set_gsetting <schema> <key> <value>
# Sets value if session available

set_gsettings <schema> <key1> <val1> [key2 val2...]
# Bulk set
```

**Example**:
```bash
# Configure GNOME theme
set_gsettings "org.gnome.desktop.interface" "gtk-theme" "Adwaita-dark"
set_gsettings "org.gnome.desktop.interface" "icon-theme" "Papirus-Dark"
```

## Configuration Application Patterns

### Pattern 1: System Configuration (Root)

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Kernel module parameters
set_modprobe_option i915 enable_fbc 1
set_modprobe_option i915 enable_guc 3
set_modprobe_option i915 enable_psr 2

# Sysctl configuration
set_config_values /etc/sysctl.d/00-system.conf \
    "net.core.default_qdisc" "cake" \
    "net.ipv4.tcp_congestion_control" "bbr" \
    "kernel.core_pattern" "|/bin/false"

# Systemd configuration
set_config_values --section "Manager" /etc/systemd/system.conf \
    "DefaultTimeoutStartSec" "90s" \
    "DefaultTimeoutStopSec" "90s"

# GRUB configuration
set_config_value /etc/default/grub "GRUB_TIMEOUT" "5"
set_config_value /etc/default/grub "GRUB_CMDLINE_LINUX_DEFAULT" \
    "mitigations=off random.trust_cpu=on intel_idle.max_cstate=1 resume=/swapfile quiet loglevel=3"
```

### Pattern 2: User Configuration (GSettings)

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Check GSettings session
if has_gsettings_session; then
    # Theme
    set_gsettings "org.gnome.desktop.interface" \
        "gtk-theme" "${GTK_THEME}" \
        "icon-theme" "${ICON_THEME}" \
        "cursor-theme" "${CURSOR_THEME}" \
        "color-scheme" "prefer-dark"

    # Fonts
    set_gsettings "org.gnome.desktop.interface" \
        "font-name" "${INTERFACE_FONT}" \
        "document-font-name" "${DOCUMENT_FONT}" \
        "monospace-font-name" "${MONOSPACE_FONT}"

    # Window controls
    set_gsettings "org.gnome.desktop.wm.preferences" \
        "button-layout" "appmenu:minimize,maximize,close"
fi
```

### Pattern 3: Application Configuration (INI/JSON)

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/config.sh"

# GTK config files
update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bashrc"

# Git config
set_config_value "${HOME}/.config/git/config" "user.name" "John Doe"
set_config_value "${HOME}/.config/git/config" "user.email" "john@example.com"
set_config_value "${HOME}/.config/git/config" "core.editor" "vim"

# Firefox preferences
if [ -d "${FIREFOX_PROFILE_DIR}" ]; then
    set_firefox_config "${FIREFOX_PROFILE_DIR}" "browser.tabs.drawInTitlebar" "true"
    set_firefox_config "${FIREFOX_PROFILE_DIR}" "toolkit.legacyUserProfileCustomizations.stylesheets" "true"
fi
```

## Configuration File Formats Supported

| Format | Read | Write | Use Cases |
|--------|------|-------|-----------|
| INI (sectioned) | ✓ | ✓ | systemd, GRUB, desktop files, GTK |
| INI (non-sectioned) | ✓ | ✓ | /etc/default/*, modprobe.d |
| JSON | ✓ | ✓ | Firefox prefs, VS Code settings |
| XML | ✓ | ✓ | Simple XML configs |
| GSettings | ✓ | ✓ | GNOME, KDE, MATE, Phosh |
| modprobe.d | ✗ | ✓ | Kernel module parameters |
| PulseAudio | ✗ | ✓ | Audio module options |

## Configuration Invariants

1. **Idempotency** — All writes use `update_file_if_distinct` (content comparison)
2. **Platform guards** — GSettings wrapped in `has_gsettings_session`
3. **Binary existence checks** — App configs only deployed if binary exists
4. **Root vs user separation** — System paths via `run_as_su`, user paths directly
5. **No runtime templating** — Templates deployed verbatim; no variable interpolation
6. **Single source of truth** — Each setting derived in exactly one place

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `get_config_value` | File not found | Returns empty string |
| `set_config_value` | Permission denied | Error message, returns 1 |
| `set_config_value` | Invalid JSON/XML | Falls back to sed, may corrupt |
| `has_gsettings_session` | No DBus | Returns 1, skips GSettings |
| `call_gsettings` | Schema not found | Error message, returns 1 |

## Performance Considerations

- **File I/O**: Each `set_config_value` reads/writes entire file
- **Bulk operations**: Use `set_config_values` for multiple keys
- **GSettings**: Requires DBus session; skipped on headless/SSH
- **Content comparison**: `cmp -s` for `update_file_if_distinct`

## Security Considerations

- **No eval/exec** on configuration values
- **Path validation** via `filesystem.sh` utilities
- **Privilege separation** — system configs via `run_as_su`
- **No user input** directly in config operations

## Testing

### Unit Tests

```bash
function test_set_ini_config_value() {
    local temp_file=$(mktemp)

    # Test sectioned INI
    set_config_value --section "Test" "${temp_file}" "key1" "value1"
    assertEquals "value1" "$(get_config_value --section "Test" "${temp_file}" "key1")"

    # Test non-sectioned INI
    set_config_value "${temp_file}" "key2" "value2"
    assertEquals "value2" "$(get_config_value "${temp_file}" "key2")"

    rm -f "${temp_file}"
}

function test_set_json_property() {
    local temp_file=$(mktemp)
    echo '{"key1": "old"}' > "${temp_file}"

    set_config_value "${temp_file}" "key1" "new"
    assertEquals '{"key1": "new"}' "$(cat "${temp_file}")"

    rm -f "${temp_file}"
}
```

### Integration Tests

```bash
function test_modprobe_option() {
    local temp_dir=$(mktemp -d)
    export ROOT_ETC="${temp_dir}"

    set_modprobe_option "test_module" "param1" "value1"
    assertTrue "modprobe.d file created" "[ -f ${temp_dir}/modprobe.d/test_module.conf ]"
    assertEquals "options test_module param1=value1" "$(cat ${temp_dir}/modprobe.d/test_module.conf)"

    rm -rf "${temp_dir}"
}
```

## Future Enhancements

1. **Schema validation** — Validate config against JSON Schema / INI schema
2. **Transactional writes** — Atomic multi-file updates with rollback
3. **Configuration diff** — Show what would change before applying
4. **YAML support** — Add YAML parsing/writing
5. **TOML support** — Add TOML parsing/writing
6. **GSettings schema validation** — Check schema exists before setting
7. **Parallel config writes** — Batch independent config operations