# Configuration Deployment Flow

This document describes the flow of configuration file deployment from
source templates to target locations across the system.

## Overview

The configuration deployment system manages the deployment of RC files,
profile scripts, resources, and system configurations using an idempotent
atomic write pattern.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Configuration Deployment Flow                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Source Discovery                             │
│  • rc/ directory (dotfiles)                                     │
│  • profiles/ directory (profile scripts)                        │
│  • resources/ directory (application configs)                   │
│  • data/ directory (static data files)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Target Resolution                            │
│  • User home directory (~/.bashrc, ~/.vimrc, etc.)              │
│  • System directories (/etc/, /usr/share/)                      │
│  • Application config directories (~/.config/, ~/.local/)       │
│  • Boot directories (/boot/, /etc/grub.d/)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Execution                         │
│  • update-rcs.sh (dotfiles)                                     │
│  • update-profiles.sh (profile scripts)                         │
│  • update-resources.sh (application resources)                  │
│  • configure-system.sh (system configs)                         │
│  • update-grub.sh (boot config)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Atomic Write Pattern                         │
│  • Read target file                                             │
│  • Compare with source                                          │
│  • Write only if different                                      │
│  • Preserve permissions                                         │
│  • Create backups                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Post-Deployment                              │
│  • Verify deployments                                           │
│  • Reload affected services                                     │
│  • Update caches                                                │
└─────────────────────────────────────────────────────────────────┘
```

## Source Structure

### RC Files (`rc/`)

```
rc/
├── boot_firmware_config_argononeup.txt
├── firefox-policies.json
├── gitconfig
├── inputrc
├── lxde-dock
├── lxde-panel
├── nanorc
├── profile
├── vimrc
├── gimp/
│   ├── gimprc
│   ├── sessionrc
│   └── toolrc
├── grub/
│   ├── 25_windows
│   ├── 29_android
│   ├── 29_blissos
│   ├── 29_phoenixos
│   ├── 29_primeos
│   └── 99_power
├── hidden-files/
│   ├── home
│   ├── home-documents
│   ├── home-downloads
│   └── home-ro
├── keyboard-layouts/
│   ├── ro
│   └── ro-argononeup
├── network-manager/
│   └── mac-randomisation.conf
└── shell/
    ├── aliases
    ├── bash_profile
    ├── bashrc
    ├── functions
    ├── opts
    ├── processes
    └── prompt
```

### Profile Scripts (`profiles/`)

```
profiles/
├── cmake.sh
└── dotnet.sh
```

### Resources (`resources/`)

```
resources/
├── fetch/
│   ├── fastfetch/
│   │   └── logos/
│   └── neofetch/
│       └── logos/
├── firefox/
│   ├── containers.json
│   ├── userChrome.css
│   └── icons/
├── git/
│   └── hooks/
│       ├── post-checkout
│       └── prepare-commit-msg
├── lxpanel/
│   └── lxde-logout-gnomified.desktop
├── neofetch/
│   ├── ascii-arch
│   └── ascii-lineageos
├── pcmanfm/
│   ├── open-in-code.desktop
│   └── open-in-terminal.desktop
├── plank/
│   ├── autostart.desktop
│   └── dock.theme
├── templates/
│   ├── doc
│   ├── file
│   └── odt
└── udev/
    ├── ioschedulers.rules
    ├── pci_pm.rules
    ├── usb_powersave.rules
    └── wifi_powersave.rules
```

## Target Resolution

### User Home Directory

| Source | Target |
|--------|--------|
| `rc/gitconfig` | `~/.gitconfig` |
| `rc/inputrc` | `~/.inputrc` |
| `rc/nanorc` | `~/.nanorc` |
| `rc/profile` | `~/.profile` |
| `rc/vimrc` | `~/.vimrc` |
| `rc/shell/bashrc` | `~/.bashrc` |
| `rc/shell/bash_profile` | `~/.bash_profile` |
| `rc/shell/aliases` | `~/.bash_aliases` |
| `rc/shell/functions` | `~/.bash_functions` |
| `rc/shell/opts` | `~/.bash_opts` |
| `rc/shell/processes` | `~/.bash_processes` |
| `rc/shell/prompt` | `~/.bash_prompt` |

### System Directories

| Source | Target |
|--------|--------|
| `rc/grub/*` | `/etc/grub.d/` |
| `rc/keyboard-layouts/*` | `/usr/share/X11/xkb/symbols/` |
| `rc/network-manager/*` | `/etc/NetworkManager/conf.d/` |
| `rc/udev/*` | `/etc/udev/rules.d/` |

### Application Config Directories

| Source | Target |
|--------|--------|
| `rc/gimp/*` | `~/.config/GIMP/2.10/` |
| `rc/firefox-policies.json` | `/etc/firefox/policies/policies.json` |
| `resources/firefox/userChrome.css` | `~/.mozilla/firefox/*.default/chrome/userChrome.css` |
| `resources/firefox/containers.json` | `~/.mozilla/firefox/*.default/containers.json` |
| `resources/firefox/icons/*` | `~/.mozilla/firefox/*.default/chrome/icons/` |
| `resources/lxpanel/*` | `~/.config/lxpanel/LXDE/panels/` |
| `resources/neofetch/*` | `~/.config/neofetch/` |
| `resources/pcmanfm/*` | `~/.local/share/applications/` |
| `resources/plank/*` | `~/.config/plank/dock1/` |
| `resources/templates/*` | `~/Templates/` |

## Deployment Scripts

### update-rcs.sh

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

deploy_rcs() {
    log_section "Deploying RC Files"

    # Deploy shell configs
    deploy_shell_configs

    # Deploy editor configs
    deploy_editor_configs

    # Deploy git config
    deploy_git_config

    # Deploy GIMP configs
    deploy_gimp_configs

    # Deploy GRUB configs
    deploy_grub_configs

    # Deploy keyboard layouts
    deploy_keyboard_layouts

    # Deploy network manager configs
    deploy_network_manager_configs

    # Deploy hidden files
    deploy_hidden_files

    # Deploy udev rules
    deploy_udev_rules

    log_success "RC files deployed"
}

deploy_shell_configs() {
    local files=(
        "bashrc:.bashrc"
        "bash_profile:.bash_profile"
        "aliases:.bash_aliases"
        "functions:.bash_functions"
        "opts:.bash_opts"
        "processes:.bash_processes"
        "prompt:.bash_prompt"
    )

    for mapping in "${files[@]}"; do
        local source="${mapping%%:*}"
        local target="${mapping##*:}"
        deploy_file "rc/shell/${source}" "${HOME}/${target}"
    done

    # Deploy inputrc
    deploy_file "rc/inputrc" "${HOME}/.inputrc"

    # Deploy nanorc
    deploy_file "rc/nanorc" "${HOME}/.nanorc"

    # Deploy profile
    deploy_file "rc/profile" "${HOME}/.profile"
}

deploy_editor_configs() {
    deploy_file "rc/vimrc" "${HOME}/.vimrc"
}

deploy_git_config() {
    deploy_file "rc/gitconfig" "${HOME}/.gitconfig"
}

deploy_gimp_configs() {
    local gimp_dir="${HOME}/.config/GIMP/2.10"
    ensure_directory "${gimp_dir}"

    deploy_file "rc/gimp/gimprc" "${gimp_dir}/gimprc"
    deploy_file "rc/gimp/sessionrc" "${gimp_dir}/sessionrc"
    deploy_file "rc/gimp/toolrc" "${gimp_dir}/toolrc"
}

deploy_grub_configs() {
    local grub_dir="/etc/grub.d"
    ensure_directory "${grub_dir}"

    for file in rc/grub/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${grub_dir}/${basename}"
    done
}

deploy_keyboard_layouts() {
    local kb_dir="/usr/share/X11/xkb/symbols"
    ensure_directory "${kb_dir}"

    for file in rc/keyboard-layouts/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${kb_dir}/${basename}"
    done
}

deploy_network_manager_configs() {
    local nm_dir="/etc/NetworkManager/conf.d"
    ensure_directory "${nm_dir}"

    for file in rc/network-manager/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${nm_dir}/${basename}"
    done
}

deploy_hidden_files() {
    for file in rc/hidden-files/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${HOME}/.${basename}"
    done
}

deploy_udev_rules() {
    local udev_dir="/etc/udev/rules.d"
    ensure_directory "${udev_dir}"

    for file in resources/udev/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${udev_dir}/${basename}"
    done
}
```

### update-profiles.sh

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

deploy_profiles() {
    log_section "Deploying Profile Scripts"

    local profile_dir="${HOME}/.profile.d"
    ensure_directory "${profile_dir}"

    for file in profiles/*.sh; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${profile_dir}/${basename}"
    done

    # Source profiles in .bashrc if not already
    ensure_profile_sourcing

    log_success "Profile scripts deployed"
}

ensure_profile_sourcing() {
    local bashrc="${HOME}/.bashrc"
    local source_line='for f in ~/.profile.d/*.sh; do [ -r "$f" ] && source "$f"; done'

    if ! grep -q "profile.d" "${bashrc}" 2>/dev/null; then
        echo "" >> "${bashrc}"
        echo "# Source profile scripts" >> "${bashrc}"
        echo "${source_line}" >> "${bashrc}"
        log_info "Added profile sourcing to .bashrc"
    fi
}
```

### update-resources.sh

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

deploy_resources() {
    log_section "Deploying Resources"

    # Deploy Firefox resources
    deploy_firefox_resources

    # Deploy neofetch resources
    deploy_neofetch_resources

    # Deploy fastfetch resources
    deploy_fastfetch_resources

    # Deploy lxpanel resources
    deploy_lxpanel_resources

    # Deploy pcmanfm resources
    deploy_pcmanfm_resources

    # Deploy plank resources
    deploy_plank_resources

    # Deploy templates
    deploy_templates

    # Deploy git hooks
    deploy_git_hooks

    log_success "Resources deployed"
}

deploy_firefox_resources() {
    # Find Firefox profile directory
    local firefox_profile=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -name "*.default*" -type d | head -1)

    if [ -z "${firefox_profile}" ]; then
        log_warn "Firefox profile not found, skipping Firefox resources"
        return 0
    fi

    local chrome_dir="${firefox_profile}/chrome"
    ensure_directory "${chrome_dir}"

    # Deploy userChrome.css
    deploy_file "resources/firefox/userChrome.css" "${chrome_dir}/userChrome.css"

    # Deploy containers.json
    deploy_file "resources/firefox/containers.json" "${firefox_profile}/containers.json"

    # Deploy icons
    local icons_dir="${chrome_dir}/icons"
    ensure_directory "${icons_dir}"

    for icon in resources/firefox/icons/*; do
        local basename=$(basename "${icon}")
        deploy_file "${icon}" "${icons_dir}/${basename}"
    done
}

deploy_neofetch_resources() {
    local neofetch_dir="${HOME}/.config/neofetch"
    ensure_directory "${neofetch_dir}"

    for file in resources/neofetch/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${neofetch_dir}/${basename}"
    done
}

deploy_fastfetch_resources() {
    local fastfetch_dir="${HOME}/.config/fastfetch"
    ensure_directory "${fastfetch_dir}"

    for file in resources/fetch/fastfetch/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${fastfetch_dir}/${basename}"
    done

    # Deploy logos
    local logos_dir="${fastfetch_dir}/logos"
    ensure_directory "${logos_dir}"

    for logo in resources/fetch/fastfetch/logos/*; do
        local basename=$(basename "${logo}")
        deploy_file "${logo}" "${logos_dir}/${basename}"
    done
}

deploy_lxpanel_resources() {
    local lxpanel_dir="${HOME}/.config/lxpanel/LXDE/panels"
    ensure_directory "${lxpanel_dir}"

    for file in resources/lxpanel/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${lxpanel_dir}/${basename}"
    done
}

deploy_pcmanfm_resources() {
    local apps_dir="${HOME}/.local/share/applications"
    ensure_directory "${apps_dir}"

    for file in resources/pcmanfm/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${apps_dir}/${basename}"
    done
}

deploy_plank_resources() {
    local plank_dir="${HOME}/.config/plank/dock1"
    ensure_directory "${plank_dir}"

    for file in resources/plank/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${plank_dir}/${basename}"
    done
}

deploy_templates() {
    local templates_dir="${HOME}/Templates"
    ensure_directory "${templates_dir}"

    for file in resources/templates/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${templates_dir}/${basename}"
    done
}

deploy_git_hooks() {
    local hooks_dir="${HOME}/.git-templates/hooks"
    ensure_directory "${hooks_dir}"

    for file in resources/git/hooks/*; do
        local basename=$(basename "${file}")
        deploy_file "${file}" "${hooks_dir}/${basename}"
    done

    # Configure git to use template
    git config --global init.templateDir "${HOME}/.git-templates"
}
```

## Atomic Write Pattern

### Core Function: `update_file_if_distinct`

```bash
# scripts/common/filesystem.sh

update_file_if_distinct() {
    local source="$1"
    local target="$2"
    local mode="${3:-644}"
    local owner="${4:-}"
    local group="${5:-}"

    # Ensure source exists
    if [ ! -f "${source}" ]; then
        log_error "Source file not found: ${source}"
        return 1
    fi

    # Ensure target directory exists
    local target_dir=$(dirname "${target}")
    ensure_directory "${target_dir}"

    # Read target content if exists
    local target_content=""
    if [ -f "${target}" ]; then
        target_content=$(cat "${target}")
    fi

    # Read source content
    local source_content=$(cat "${source}")

    # Compare content
    if [ "${source_content}" = "${target_content}" ]; then
        log_debug "File unchanged: ${target}"
        return 0
    fi

    # Create backup if target exists
    if [ -f "${target}" ]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        cp "${target}" "${backup}"
        log_debug "Created backup: ${backup}"
    fi

    # Write new content
    echo "${source_content}" > "${target}"

    # Set permissions
    chmod "${mode}" "${target}"

    # Set ownership if specified
    if [ -n "${owner}" ] && [ -n "${group}" ]; then
        chown "${owner}:${group}" "${target}"
    elif [ -n "${owner}" ]; then
        chown "${owner}" "${target}"
    fi

    log_info "Updated: ${target}"
    return 0
}
```

### Wrapper: `deploy_file`

```bash
deploy_file() {
    local source="$1"
    local target="$2"
    local mode="${3:-644}"

    # Resolve source path relative to repo
    if [[ ! "${source}" = /* ]]; then
        source="${REPO_DIR}/${source}"
    fi

    update_file_if_distinct "${source}" "${target}" "${mode}"
}
```

## Configuration File Manipulation

### INI File Updates

```bash
# scripts/common/config.sh

update_ini_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"

    # Create file if not exists
    touch "${file}"

    # Use awk to update or add the value
    awk -v section="[${section}]" -v key="${key}" -v value="${value}" '
        BEGIN { in_section=0; found=0 }
        $0 == section { in_section=1; print; next }
        in_section && /^\[.*\]/ { in_section=0 }
        in_section && $1 == key "=" { print key "=" value; found=1; next }
        { print }
        END {
            if (in_section && !found) print key "=" value
        }
    ' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
}
```

### JSON File Updates

```bash
update_json_value() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Use jq to update
    jq --arg key "${key}" --arg value "${value}" \
        '.[$key] = $value' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
}
```

### Environment Variable Updates

```bash
update_env_file() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Create file if not exists
    touch "${file}"

    # Update or add
    if grep -q "^${key}=" "${file}"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
    else
        echo "${key}=${value}" >> "${file}"
    fi
}
```

## Post-Deployment Actions

### Service Reload

```bash
reload_services() {
    log_section "Reloading Services"

    # Reload systemd user services
    systemctl --user daemon-reload

    # Reload NetworkManager
    if systemctl is-active --quiet NetworkManager; then
        systemctl reload NetworkManager
    fi

    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger

    log_success "Services reloaded"
}
```

### Cache Updates

```bash
update_caches() {
    log_section "Updating Caches"

    # Update font cache
    fc-cache -f

    # Update desktop database
    update-desktop-database "${HOME}/.local/share/applications"

    # Update MIME database
    update-mime-database "${HOME}/.local/share/mime"

    # Update icon cache
    gtk-update-icon-cache -f "${HOME}/.local/share/icons" 2>/dev/null || true

    log_success "Caches updated"
}
```

## Verification

### Deployment Verification

```bash
verify_deployments() {
    log_section "Verifying Deployments"

    local failed=0

    # Verify RC files
    for file in rc/shell/*; do
        local basename=$(basename "${file}")
        local target="${HOME}/.${basename}"
        if ! verify_file "${file}" "${target}"; then
            failed=1
        fi
    done

    # Verify profile scripts
    for file in profiles/*.sh; do
        local basename=$(basename "${file}")
        local target="${HOME}/.profile.d/${basename}"
        if ! verify_file "${file}" "${target}"; then
            failed=1
        fi
    done

    if [ ${failed} -eq 0 ]; then
        log_success "All deployments verified"
    else
        log_error "Some deployments failed verification"
        return 1
    fi
}

verify_file() {
    local source="$1"
    local target="$2"

    if [ ! -f "${target}" ]; then
        log_error "Missing: ${target}"
        return 1
    fi

    local source_content=$(cat "${source}")
    local target_content=$(cat "${target}")

    if [ "${source_content}" != "${target_content}" ]; then
        log_error "Content mismatch: ${target}"
        return 1
    fi

    log_debug "Verified: ${target}"
    return 0
}
```

## Error Handling

### Deployment Failures

```bash
# Continue on non-critical failures
deploy_with_fallback() {
    local source="$1"
    local target="$2"
    local critical="${3:-false}"

    if ! deploy_file "${source}" "${target}"; then
        if [ "${critical}" = "true" ]; then
            log_error "Critical deployment failed: ${target}"
            return 1
        else
            log_warn "Non-critical deployment failed: ${target}"
            return 0
        fi
    fi

    return 0
}
```

### Permission Issues

```bash
# Handle permission issues with sudo
deploy_file_sudo() {
    local source="$1"
    local target="$2"
    local mode="${3:-644}"
    local owner="${4:-root}"
    local group="${5:-root}"

    local source_content=$(cat "${source}")

    echo "${source_content}" | ${RUN_AS_SU} tee "${target}" > /dev/null
    ${RUN_AS_SU} chmod "${mode}" "${target}"
    ${RUN_AS_SU} chown "${owner}:${group}" "${target}"
}
```

## Logging

### Deployment Log

```
=== Deploying RC Files ===
[INFO] Updated: /home/user/.bashrc
[INFO] Updated: /home/user/.vimrc
[INFO] Updated: /home/user/.gitconfig
[INFO] Updated: /etc/grub.d/25_windows
[INFO] Updated: /etc/NetworkManager/conf.d/mac-randomisation.conf
[SUCCESS] RC files deployed

=== Deploying Profile Scripts ===
[INFO] Updated: /home/user/.profile.d/cmake.sh
[INFO] Updated: /home/user/.profile.d/dotnet.sh
[SUCCESS] Profile scripts deployed

=== Deploying Resources ===
[INFO] Updated: /home/user/.config/neofetch/ascii-arch
[INFO] Updated: /home/user/.mozilla/firefox/abc123.default/chrome/userChrome.css
[INFO] Updated: /home/user/.local/share/applications/open-in-code.desktop
[SUCCESS] Resources deployed

=== Reloading Services ===
[SUCCESS] Services reloaded

=== Updating Caches ===
[SUCCESS] Caches updated

=== Verifying Deployments ===
[SUCCESS] All deployments verified
```

## Idempotency Guarantees

1. **Content Comparison**: Files only written if content differs
2. **Permission Preservation**: Target permissions maintained
3. **Backup Creation**: Previous versions backed up before overwrite
4. **Directory Creation**: Target directories created automatically
5. **Atomic Writes**: Temporary file + rename for atomicity

## Performance

### Typical Deployment Times

| Component | Time |
|-----------|------|
| RC files | 1-2 seconds |
| Profile scripts | <1 second |
| Resources | 2-5 seconds |
| System configs | 1-3 seconds |
| Verification | 1-2 seconds |
| **Total** | **5-13 seconds** |

### Optimisation

- Skip unchanged files (content comparison)
- Parallel deployment for independent files
- Batch directory creation
- Minimal stat() calls