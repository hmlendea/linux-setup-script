# Browser State and Localisation Component

This document provides a deep dive into the browser state and localisation component,
which handles browser configuration, container management, and localisation settings.

## Overview

**Location**: `scripts/common/apps.sh` (browser-related functions),
`resources/firefox/`, `scripts/configure-default-apps.sh`

**Purpose**: Firefox configuration, container management, userChrome customisation,
and system localisation settings.

**Consumers**: `configure-default-apps.sh`, `update-resources.sh`,
`configure-locale.sh`

## Core Functions

### 1. Firefox Configuration

```bash
# Configure Firefox
configure_firefox

# Set Firefox preference
set_firefox_preference <profile_dir> <key> <value>

# Get Firefox preference
get_firefox_preference <profile_dir> <key>

# Install Firefox extension
install_firefox_extension <profile_dir> <extension_id>

# Remove Firefox extension
remove_firefox_extension <profile_dir> <extension_id>

# Configure Firefox containers
configure_firefox_containers <profile_dir>

# Deploy userChrome.css
deploy_userchrome <profile_dir>
```

### 2. Container Management

```bash
# Create container
create_container <name> <color> <icon>

# Update container
update_container <name> <color> <icon>

# Delete container
delete_container <name>

# List containers
list_containers

# Set default container
set_default_container <name>
```

### 3. Localisation Configuration

```bash
# Configure system locale
configure_locale

# Set system language
set_system_language <language_code>

# Set system locale
set_system_locale <locale_code>

# Set keyboard layout
set_keyboard_layout <layout>

# Set timezone
set_timezone <timezone>

# Configure input method
configure_input_method <method>
```

## Firefox Configuration Patterns

### Pattern 1: Firefox Preferences

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/apps.sh"

# Find Firefox profile
local profile_dir=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -type d -name "*.default*" | head -1)

if [ -n "${profile_dir}" ]; then
    # Privacy settings
    set_firefox_preference "${profile_dir}" "privacy.trackingprotection.enabled" "true"
    set_firefox_preference "${profile_dir}" "privacy.trackingprotection.pbmode.enabled" "true"
    set_firefox_preference "${profile_dir}" "privacy.donottrackheader.enabled" "true"
    set_firefox_preference "${profile_dir}" "privacy.donottrackheader.value" "1"

    # Security settings
    set_firefox_preference "${profile_dir}" "security.tls.version.min" "3"
    set_firefox_preference "${profile_dir}" "security.tls.version.max" "4"
    set_firefox_preference "${profile_dir}" "security.ssl.enable_ocsp_stapling" "true"

    # UI settings
    set_firefox_preference "${profile_dir}" "browser.tabs.drawInTitlebar" "true"
    set_firefox_preference "${profile_dir}" "toolkit.legacyUserProfileCustomizations.stylesheets" "true"
    set_firefox_preference "${profile_dir}" "browser.compactmode.show" "true"

    # Performance settings
    set_firefox_preference "${profile_dir}" "browser.cache.disk.enable" "true"
    set_firefox_preference "${profile_dir}" "browser.cache.memory.enable" "true"
    set_firefox_preference "${profile_dir}" "browser.sessionstore.interval" "30000"

    # Container settings
    set_firefox_preference "${profile_dir}" "privacy.userContext.enabled" "true"
    set_firefox_preference "${profile_dir}" "privacy.userContext.ui.enabled" "true"
fi
```

### Pattern 2: Firefox Containers

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/apps.sh"

# Deploy containers configuration
local profile_dir=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -type d -name "*.default*" | head -1)

if [ -n "${profile_dir}" ]; then
    update_file_if_distinct \
        "${REPO_RESOURCES_DIR}/firefox/containers.json" \
        "${profile_dir}/containers.json"
fi
```

### Pattern 3: userChrome.css Deployment

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/filesystem.sh"

# Deploy userChrome.css
local profile_dir=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -type d -name "*.default*" | head -1)

if [ -n "${profile_dir}" ]; then
    local chrome_dir="${profile_dir}/chrome"
    create_directory "${chrome_dir}"

    update_file_if_distinct \
        "${REPO_RESOURCES_DIR}/firefox/userChrome.css" \
        "${chrome_dir}/userChrome.css"

    # Deploy icons
    local icons_dir="${chrome_dir}/icons"
    create_directory "${icons_dir}"

    for icon in "${REPO_RESOURCES_DIR}/firefox/icons/"*; do
        update_file_if_distinct "${icon}" "${icons_dir}/$(basename "${icon}")"
    done
fi
```

## Localisation Configuration Patterns

### Pattern 1: System Locale

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"
source "scripts/common/system-info.sh"

# Set system locale
set_system_language "en_US"
set_system_locale "en_US.UTF-8"

# Configure locale.conf
set_config_value "/etc/locale.conf" "LANG" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_ALL" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_MESSAGES" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_COLLATE" "C"
set_config_value "/etc/locale.conf" "LC_CTYPE" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_NUMERIC" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_TIME" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_MONETARY" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_PAPER" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_NAME" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_ADDRESS" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_TELEPHONE" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_MEASUREMENT" "en_US.UTF-8"
set_config_value "/etc/locale.conf" "LC_IDENTIFICATION" "en_US.UTF-8"

# Generate locale
run_as_su locale-gen
```

### Pattern 2: Keyboard Layout

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"
source "scripts/common/system-info.sh"

# Set keyboard layout
set_keyboard_layout "us"

# Configure vconsole.conf
set_config_value "/etc/vconsole.conf" "KEYMAP" "us"
set_config_value "/etc/vconsole.conf" "FONT" "latarcyrheb-sun16"
set_config_value "/etc/vconsole.conf" "FONT_MAP" "8859-1_to_uni"

# Configure X11 keyboard
update_file_if_distinct \
    "${REPO_RC_DIR}/keyboard-layouts/us" \
    "/etc/X11/xorg.conf.d/00-keyboard.conf"
```

### Pattern 3: Timezone

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"

# Set timezone
set_timezone "Europe/Bucharest"

# Configure systemd-timesyncd
set_config_value "/etc/systemd/timesyncd.conf" "Time" "NTP"
set_config_value "/etc/systemd/timesyncd.conf" "NTP" "ro.pool.ntp.org"
set_config_value "/etc/systemd/timesyncd.conf" "FallbackNTP" "0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org"

# Enable and start timesyncd
enable_and_start_service "systemd-timesyncd"
```

## Browser State and Localisation Invariants

1. **Idempotency** — All config writes use `update_file_if_distinct`
2. **Profile detection** — Firefox profile detected dynamically
3. **Platform awareness** — Different configs for different platforms
4. **Privilege separation** — System locale via `run_as_su`, user config directly
5. **No runtime templating** — Config files deployed verbatim
6. **Single source of truth** — Each setting derived in exactly one place

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `set_firefox_preference` | Profile not found | Error message, returns 1 |
| `set_firefox_preference` | prefs.js locked | Error message, returns 1 |
| `deploy_userchrome` | Chrome dir not writable | Error message, returns 1 |
| `set_system_locale` | Locale not generated | Runs `locale-gen` first |
| `set_keyboard_layout` | Layout not available | Error message, returns 1 |

## Performance Considerations

- **Batch preference sets** — Multiple preferences in one profile
- **Profile caching** — Firefox profile path cached during session
- **Minimal I/O** — Only write changed preferences
- **Conditional deployment** — Only deploy if Firefox installed

## Security Considerations

- **No arbitrary code** — Preferences are declarative
- **Path validation** — Profile paths validated before use
- **Privilege separation** — System locale via `run_as_su`
- **Extension verification** — Extensions installed from trusted sources

## Testing

### Unit Tests

```bash
function test_set_firefox_preference() {
    local temp_dir=$(mktemp -d)
    local prefs_file="${temp_dir}/prefs.js"

    echo 'user_pref("test.pref", false);' > "${prefs_file}"

    set_firefox_preference "${temp_dir}" "test.pref" "true"
    assertEquals "preference set" 'user_pref("test.pref", true);' "$(grep "test.pref" "${prefs_file}")"

    rm -rf "${temp_dir}"
}

function test_set_system_locale() {
    set_system_locale "en_US.UTF-8"
    assertEquals "locale set" "en_US.UTF-8" "$(get_system_locale)"
}
```

### Integration Tests

```bash
function test_firefox_configuration() {
    # Test Firefox configuration
    configure_firefox
    assertTrue "Firefox configured" "[ -f ${HOME}/.mozilla/firefox/*.default*/prefs.js ]"
}

function test_locale_configuration() {
    # Test locale configuration
    configure_locale
    assertEquals "locale set" "en_US.UTF-8" "$(get_system_locale)"
}
```

## Future Enhancements

1. **Multi-profile support** — Configure multiple Firefox profiles
2. **Extension management** — Install/remove extensions programmatically
3. **Sync configuration** — Firefox Sync configuration
4. **Policy management** — Firefox enterprise policies
5. **Container automation** — Automatic container assignment rules
6. **Localisation profiles** — Multiple localisation profiles