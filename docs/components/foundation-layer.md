# Foundation Layer

This document provides a deep dive into the foundation layer modules in
`scripts/common/`. These are the core utilities that all higher-level scripts
rely upon.

## Module Overview

The foundation layer consists of **9 modules** that provide shared utilities
for all higher-level scripts. They are **sourced** (not executed) and have a
strict dependency hierarchy to ensure correct initialization order.

```
filesystem.sh (no deps)
    ↑
common.sh ──► filesystem.sh
    ↑
system-info.sh ──► filesystem.sh, common.sh
    ↑
package-management.sh ──► filesystem.sh, common.sh, system-info.sh
    ↑
config.sh ──► filesystem.sh
    ↑
service-management.sh ──► filesystem.sh, common.sh, config.sh
    ↑
apps.sh ──► filesystem.sh
    ↑
permissions.sh ──► config.sh, package-management.sh
    ↑
github.sh (no deps)
```

## 1. filesystem.sh — Path Resolution & Constants

**Location**: `scripts/common/filesystem.sh`

**Purpose**: Establish all filesystem paths used throughout the repository,
handling differences between standard Linux, Android/Termux, and root vs user
contexts.

### Exported Path Constants

#### Repository-Relative Paths
| Constant | Value | Description |
|----------|-------|-------------|
| `REPO_DIR` | Absolute path to repo root | Resolved via `BASH_SOURCE[0]` traversal |
| `REPO_DATA_DIR` | `${REPO_DIR}/data` | Static data files (steam names, wmclasses) |
| `REPO_RES_DIR` | `${REPO_DIR}/resources` | Resource templates (firefox, git, lxpanel, etc.) |
| `REPO_RC_DIR` | `${REPO_DIR}/rc` | Configuration templates (shell, git, grub, etc.) |
| `REPO_SCRIPTS_DIR` | `${REPO_DIR}/scripts` | All executable scripts |
| `REPO_SCRIPTS_COMMON_DIR` | `${REPO_SCRIPTS_DIR}/common` | Foundation modules |
| `REPO_KEYBOARD_LAYOUTS_DIR` | `${REPO_RC_DIR}/keyboard-layouts` | X11 keymap files |

#### Root Filesystem Paths (prefix `ROOT_`)
| Constant | Standard Linux | Android/Termux |
|----------|----------------|----------------|
| `ROOT_PATH` | `/` | `/data/data/com.termux/files/usr` |
| `ROOT_BIN` | `/bin` | `${ROOT_PATH}/bin` |
| `ROOT_ETC` | `/etc` | `${ROOT_PATH}/etc` |
| `ROOT_HOME` | `/home` | `${ROOT_PATH}/home` |
| `ROOT_USR` | `/usr` | `${ROOT_PATH}` (Termux has no /usr) |
| `ROOT_USR_BIN` | `/usr/bin` | `${ROOT_PATH}/bin` |
| `ROOT_USR_SHARE` | `/usr/share` | `${ROOT_PATH}/share` |
| `ROOT_USR_LOCAL_BIN` | `/usr/local/bin` | `${ROOT_PATH}/bin` |
| `ROOT_VAR` | `/var` | `${ROOT_PATH}/var` |
| `ROOT_VAR_LIB` | `/var/lib` | `${ROOT_PATH}/var/lib` |
| `ROOT_VAR_LIB_FLATPAK` | `/var/lib/flatpak` | N/A |
| `ROOT_BOOT` | `/boot` | `${ROOT_PATH}/boot` |
| `ROOT_BOOT_FIRMWARE` | `/boot/firmware` | N/A |
| `ROOT_SYS` | `/sys` | `${ROOT_PATH}/sys` |
| `ROOT_PROC` | `/proc` | `${ROOT_PATH}/proc` |

#### Derived System Paths
| Constant | Value |
|----------|-------|
| `UDEV_RULES_DIR` | `${ROOT_ETC}/udev/rules.d` |
| `LOCAL_INSTALL_TEMP_DIR` | `${REPO_DIR}/.temp-sysinstall` |
| `LINUX_SETUP_SCRIPT_DATA_DIR` | `${ROOT_VAR_LIB}/linux-setup-script` |
| `LINUX_SETUP_SCRIPT_PACKAGES_DIR` | `${LINUX_SETUP_SCRIPT_DATA_DIR}/packages` |

#### User Home Resolution
```bash
USER_REAL=${SUDO_USER:-${USER}}
HOME_REAL=$(grep "${USER_REAL}" "${ROOT_PATH}/etc/passwd" | cut -f6 -d:)
# Fallbacks: /data/data/com.termux/files/home, /root, /home/${USER_REAL}
HOME="${HOME:-${HOME_REAL}}"
```

### Utility Functions

| Function | Description |
|----------|-------------|
| `does_directory_exist(path)` | Returns 0 if directory exists |
| `does_file_exist(path)` | Returns 0 if file exists |

## 2. common.sh — Execution Primitives & Shell Setup

**Location**: `scripts/common/common.sh`

**Purpose**: Provide privilege escalation, script execution, and shell
environment normalisation.

### Exported Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `run_as_su` | `run_as_su <cmd> [args...]` | Execute as root (sudo/su) or directly if UID=0 |
| `get_preferred_script_shell` | `get_preferred_script_shell` | Returns 'bash', 'zsh', or 'sh' (first available) |
| `run_script` | `run_script <script_path> [args...]` | Execute script as current user with logging |
| `run_script_as_su` | `run_script_as_su <script_path> [args...]` | Execute script as root with logging |

### Shell Environment

```bash
LANG=en_US.UTF-8  # Forced for deterministic command output (e.g., `yes`)
```

### Logging Format

```
Executing as <user>: '/path/to/script.sh'...
Executing as root: '/path/to/script.sh'...
```

## 3. system-info.sh — Hardware & Environment Detection

**Location**: `scripts/common/system-info.sh`

**Purpose**: Detect and export all hardware, display, and environment
properties used for conditional configuration.

### Detection Functions (called at source time)

| Function | Returns | Method |
|----------|---------|--------|
| `get_screen_width` | pixels | Wayland: `wayland-info`; X11: `xrandr`/`xdpyinfo` |
| `get_screen_height` | pixels | Same as width |
| `get_screen_dpi` | integer | Calculated from width + physical mm; X11: `xdpyinfo` |
| `get_arch` | string | `uname -m` → `lscpu` → CPU family heuristic |
| `get_arch_family` | 'x86'/'arm' | Mapping from `get_arch` |
| `get_device_model` | string | Device tree, systemd, dmidecode, Android props |
| `get_chassis_type` | string | `systemd-detect-virt`, dmidecode chassis |
| `get_cpu` | string | `/proc/cpuinfo`, `lscpu` |
| `get_gpu` | string | `lspci`, `glxinfo` |
| `get_gpu_family` | string | 'Intel', 'Nvidia', 'AMD', 'Qualcomm' |
| `get_audio_driver` | string | `lspci -k`, `/proc/asound` |
| `get_wifi_driver` | string | `lspci -k`, `iw dev` |
| `get_display_server` | string | `XDG_SESSION_TYPE` |
| `get_os_language` | string | `locale`, `LANG` |
| `get_uptime_text` | string | `/proc/uptime` |
| `is_system_storage_sd_card` | boolean | `/sys/block/*/device/type`, `mmcblk` |

### Exported Variables (set at source time)

| Variable | Type | Description |
|----------|------|-------------|
| `OS` | string | 'Linux', 'Android', 'Windows' |
| `DISTRO` | string | Pretty name from `/etc/os-release` |
| `DISTRO_FAMILY` | string | 'Arch', 'Debian', 'Ubuntu', 'Alpine', 'Android' |
| `ARCH` | string | `get_arch()` |
| `ARCH_FAMILY` | string | `get_arch_family()` |
| `DEVICE_MODEL` | string | `get_device_model()` |
| `CHASSIS_TYPE` | string | `get_chassis_type()` |
| `HAS_GUI` | boolean | GUI session detected |
| `DESKTOP_ENVIRONMENT` | string | 'GNOME', 'KDE', 'MATE', 'LXDE', 'Phosh' |
| `DISPLAY_SERVER` | string | 'wayland', 'x11', 'tty' |
| `GPU_FAMILY` | string | `get_gpu_family()` |
| `IS_BATTERY_DEVICE` | boolean | Battery present |
| `HAS_EFI_SUPPORT` | boolean | `/sys/firmware/efi` exists |
| `POWERFUL_PC` | boolean | Heuristic: cores ≥ 8, RAM ≥ 16GB, discrete GPU |
| `IS_DEVELOPMENT_DEVICE` | boolean | Hostname or package heuristic |
| `IS_GAMING_DEVICE` | boolean | Steam, games, GPU heuristic |
| `IS_GENERAL_PURPOSE_DEVICE` | boolean | `!DEV && !GAMING` |
| `HAS_SU_PRIVILEGES` | boolean | Passwordless sudo or su available |

### Derived Booleans (in `configure-system.sh`)

```bash
USING_INTEL_GPU=false; [ "$(get_gpu_family)" == "Intel" ] && USING_INTEL_GPU=true
USING_NVIDIA_GPU=false; [ "$(get_gpu_family)" == "Nvidia" ] && USING_NVIDIA_GPU=true
IS_SERVER=false; [ -z "${SCREEN_RESOLUTION_H}" ] && IS_SERVER=true
```

## 4. package-management.sh — Package Manager Abstraction

**Location**: `scripts/common/package-management.sh`

**Purpose**: Unified interface for native packages, Flatpak, Cargo, AUR,
GitHub releases, VS Code extensions, and GNOME extensions.

### Package Manager Dispatch (`call_package_manager`)

```bash
call_package_manager <pacman/apt/apk/pkg args...>
```

| Distro Family | Command | Notes |
|---------------|---------|-------|
| Arch | `paru`/`yay`/`yaourt`/`pacman` | Prefers AUR helper; `--noconfirm` |
| Alpine | `apk` | `yes \|` for non-interactive |
| Android | `pkg` | Termux package manager |
| Debian/Ubuntu | `apt` | `yes \| run_as_su` |

### Installation Functions

| Function | Scope | Description |
|----------|-------|-------------|
| `install_native_package` | Single | Install via `call_package_manager install` |
| `install_native_packages` | Multiple | Loop over `install_native_package` |
| `uninstall_native_package` | Single | Remove via package manager |
| `uninstall_native_packages` | Multiple | Loop over uninstall |
| `install_flatpak` | Single | `flatpak install --assumeyes` (flathub) |
| `install_flatpaks` | Multiple | Loop over `install_flatpak` |
| `uninstall_flatpak` | Single | `flatpak uninstall --assumeyes` |
| `install_cargo_package` | Single | `cargo install` |
| `install_github_release` | Single | Download .deb/.tar.gz from GitHub releases |
| `install_aur_package_manually` | Single | Clone AUR, `makepkg -si` |
| `install_vscode_extension` | Single | `code --install-extension` |
| `call_gnome_extensions` | Single | Download & install from extensions.gnome.org |

### Query Functions

| Function | Returns | Checks |
|----------|---------|--------|
| `is_package_installed` | boolean | Native → Flatpak → GitHub → WebApp |
| `is_native_package_installed` | boolean | pacman/apt/apk/pkg query |
| `is_flatpak_installed` | boolean | `flatpak list` |
| `is_github_package_installed` | boolean | Binary in `ROOT_USR_LOCAL_BIN` |
| `is_webapp_installed` | boolean | `.desktop` in applications dir |
| `is_android_package_installed` | boolean | `pm list packages` |
| `is_vscode_extension_installed` | boolean | VS Code extension DB |
| `is_gnome_extension_installed` | boolean | GNOME extension DB |
| `is_steam_app_installed` | boolean | Steam library check |

### Specialised Helpers

| Function | Purpose |
|----------|---------|
| `call_cargo` | Wrapper for `cargo` with args |
| `call_flatpak` | Wrapper for `flatpak --assumeyes` |
| `call_vscode` | Detects `code`/`codium`/`code-oss`/`com.visualstudio.code` |
| `get_latest_github_release_assets` | Fetches download URLs from GitHub API |

## 5. config.sh — Configuration File Manipulation

**Location**: `scripts/common/config.sh`

**Purpose**: Generic INI/JSON/XML configuration value get/set with
section support.

### Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `get_config_value` | `get_config_value [--separator=] <file> <key>` | Extract value |
| `set_config_value` | `set_config_value [--separator=] [--quote=] [--section=] <file> <key> <value>` | Set value (INI/JSON/XML) |
| `set_config_values` | `set_config_values [--section=] <file> <key1> <val1> [key2 val2...]` | Bulk set |
| `append_line` | `append_line <file> <line>` | Append if not present |
| `update_file_if_distinct` | `update_file_if_distinct <src> <dst>` | Copy only if content differs |
| `create_file` | `create_file <path>` | Touch file, create parent dirs |
| `create_directory` | `create_directory <path>` | `mkdir -p` |
| `create_symlink` | `create_symlink <target> <link>` | `ln -sf` with dir creation |
| `remove` | `remove <path>` | `rm -rf` |
| `read_file` | `read_file <path>` | Cat file to stdout |

### INI Handling (`set_ini_config_value`)

- Supports `--section` for sectioned INI files
- `--separator` defaults to `=` (becomes `: ` for `:`)
- `--quote` defaults to `'` (empty for no quotes)
- Creates section header if missing
- Updates existing key or appends to section

### JSON Handling (`set_json_property`)

- Uses `jq` if available, falls back to `sed`
- Preserves formatting

### XML Handling (`set_xml_node`)

- Basic `sed`-based replacement for simple XML

## 6. service-management.sh — Systemd/OpenRC Service Control

**Location**: `scripts/common/service-management.sh`

**Purpose**: Unified service enable/disable/mask across systemd and OpenRC.

### Service Existence

```bash
does_service_exist <name>
# Checks: /etc/systemd/system, /lib/systemd/system, /usr/lib/systemd/system, /etc/init.d
```

### Service State

| Function | systemd | OpenRC |
|----------|---------|--------|
| `is_service_enabled` | `systemctl is-enabled` | `rc-update show` |
| `enable_service` | `systemctl enable --now` | `rc-update add` + `rc-service start` |
| `disable_service` | `systemctl disable --now` | `rc-update del` + `rc-service stop` |
| `mask_user_service` | `systemctl --user mask` | N/A |
| `unmask_user_service` | `systemctl --user unmask` | N/A |

### Bulk Operations

| Function | Description |
|----------|-------------|
| `enable_services` | Loop `enable_service` |
| `disable_services` | Loop `disable_service` |
| `mask_user_services` | Loop `mask_user_service` |

## 7. apps.sh — Firefox Profile Detection

**Location**: `scripts/common/apps.sh`

**Purpose**: Locate Firefox/LibreWolf profile directories across installation
methods.

### Functions

| Function | Returns |
|----------|---------|
| `get_firefox_profiles_dir` | Profile root directory |
| `get_firefox_profile_id` | Default profile ID from `profiles.ini` |
| `get_firefox_profile_dir` | Full path to default profile |

### Search Order

1. Flatpak LibreWolf: `${HOME_VAR_APP}/io.gitlab.librewolf-community/.librewolf`
2. Flatpak Firefox: `${HOME_VAR_APP}/com.mozilla.firefox/.mozilla/firefox`
3. Native LibreWolf: `${HOME}/.librewolf`
4. Native Firefox: `${HOME}/.mozilla/firefox`

## 8. permissions.sh — Application Permission Management

**Location**: `scripts/common/permissions.sh`

**Purpose**: Configure Flatpak and GNOME desktop permissions for applications.

### `set_linux_permission(application, permission, state...)`

**Permissions handled**:

| Permission | Flatpak Table/Object | GNOME Schema |
|------------|---------------------|--------------|
| `background` | `background`/`background` | N/A |
| `camera` | `devices`/`camera` | N/A |
| `all-devices` | `devices`/`all` | N/A |
| `shared-memory` | `devices`/`shm` | N/A |
| `filesystem-home` | `filesystem`/`home` | N/A |
| `microphone` | `devices`/`microphone` | `org.gnome.desktop.notifications.application` |
| `speakers` | `devices`/`speakers` | Same as microphone |
| `location` | `location`/`location` | N/A |
| `network` | `shared`/`network` | N/A |
| `notification` | `notifications`/`notification` | `enable` + `show-in-lock-screen` |
| `notification_lockscreen` | N/A | `show-in-lock-screen` |

### PulseAudio Socket Logic

If `microphone` or `speakers` explicitly set:
- Both false → disable `pulseaudio` socket
- Either true → enable `pulseaudio` socket

### Flatpak Helpers

| Function | Description |
|----------|-------------|
| `get_flatpak_permission` | Query current permission |
| `set_flatpak_permission` | `flatpak permission-set` |
| `set_flatpak_device` | `flatpak override --device` |
| `set_flatpak_filesystem` | `flatpak override --filesystem` |
| `set_flatpak_shared` | `flatpak override --share` |
| `set_flatpak_socket` | `flatpak override --socket` |

## 9. github.sh — GitHub API Helpers

**Location**: `scripts/common/github.sh`

**Purpose**: Minimal GitHub API interaction.

### Function

| Function | Description |
|----------|-------------|
| `get_latest_github_release_assets <owner/repo>` | Returns download URLs for latest release assets |

## Cross-Module Dependencies

```
filesystem.sh (no deps)
    ↑
common.sh → filesystem.sh
    ↑
system-info.sh → filesystem.sh, common.sh
    ↑
package-management.sh → filesystem.sh, common.sh, system-info.sh
    ↑
config.sh → filesystem.sh
    ↑
service-management.sh → filesystem.sh, common.sh, config.sh
    ↑
apps.sh → filesystem.sh
    ↑
permissions.sh → config.sh, package-management.sh (for is_flatpak_installed)
    ↑
github.sh → (no deps)
```

All modules are sourced with guards to prevent double-execution:

```bash
[ -n "${DISTRO_FAMILY}" ] && return  # system-info.sh
[ -z "${GLOBAL_LAUNCHERS_DIR}" ] && source ...  # service-management.sh
```

## Module Usage Patterns

### 1. Minimal Script (User-level)

```bash
#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

source "${SCRIPT_DIR}/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

# User-level operations
run_script "scripts/install-packages.sh"
```

### 2. System Script (Root-level)

```bash
#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

source "${SCRIPT_DIR}/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"

# System-level operations
run_script_as_su "scripts/configure-system.sh"
```

### 3. Configuration Script

```bash
#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

source "${SCRIPT_DIR}/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"

# Configuration operations
update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bashrc"
set_config_value "${HOME}/.config/git/config" "user.name" "John Doe"
```

## Module-Specific Deep Dives

### filesystem.sh Deep Dive

**Path Resolution Logic**:

```bash
# Repository-relative paths (always absolute)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DATA_DIR="${REPO_DIR}/data"
REPO_RES_DIR="${REPO_DIR}/resources"
REPO_RC_DIR="${REPO_DIR}/rc"
REPO_SCRIPTS_DIR="${REPO_DIR}/scripts"
REPO_SCRIPTS_COMMON_DIR="${REPO_SCRIPTS_DIR}/common"

# Root filesystem paths (platform-dependent)
if [ "${DISTRO_FAMILY}" = "Android" ]; then
    ROOT_PATH="/data/data/com.termux/files/usr"
    ROOT_ETC="${ROOT_PATH}/etc"
    ROOT_HOME="${ROOT_PATH}/home"
    ROOT_USR="${ROOT_PATH}"
else
    ROOT_PATH="/"
    ROOT_ETC="/etc"
    ROOT_HOME="/home"
    ROOT_USR="/usr"
fi

# User home resolution (handles sudo, Android, root)
USER_REAL=${SUDO_USER:-${USER}}
if [ "${DISTRO_FAMILY}" = "Android" ]; then
    HOME_REAL="/data/data/com.termux/files/home"
elif [ "${USER_REAL}" = "root" ]; then
    HOME_REAL="/root"
else
    HOME_REAL=$(grep "${USER_REAL}" "${ROOT_PATH}/etc/passwd" | cut -f6 -d:)
fi
HOME="${HOME:-${HOME_REAL}}"
```

**Utility Functions**:

```bash
function does_directory_exist() {
    [ -d "$1" ] && return 0 || return 1
}

function does_file_exist() {
    [ -f "$1" ] && return 0 || return 1
}
```

### common.sh Deep Dive

**Privilege Escalation Logic**:

```bash
function run_as_su() {
    if [ "${UID}" -eq 0 ]; then
        "${@}"                    # Already root: execute directly
    elif ${HAS_SU_PRIVILEGES}; then
        if [[ "${DISTRO_FAMILY}" == "Android" ]]; then
            su -c ${*}            # Termux: use su
        else
            sudo "${@}"           # Standard Linux: use sudo
        fi
    else
        echo "Failed to run '${*}': Missing SU privileges!"
        return 1
    fi
}
```

**Shell Detection**:

```bash
function get_preferred_script_shell() {
    if command -v zsh >/dev/null 2>&1; then
        echo "zsh"
    elif command -v bash >/dev/null 2>&1; then
        echo "bash"
    else
        echo "sh"
    fi
}
```

### system-info.sh Deep Dive

**Display Detection**:

```bash
function get_screen_width() {
    if [ "${DISPLAY_SERVER}" = "wayland" ]; then
        # Wayland: use wayland-info
        wayland-info 2>/dev/null | grep -i width | awk '{print $2}'
    elif [ "${DISPLAY_SERVER}" = "x11" ]; then
        # X11: use xrandr or xdpyinfo
        xrandr 2>/dev/null | grep -i " connected" | head -1 | awk '{print $3}' || \
        xdpyinfo 2>/dev/null | grep -i "dimensions" | awk '{print $2}' | cut -d'x' -f1
    else
        # tty: device-specific fallback
        case "${DEVICE_MODEL}" in
            "Steam Deck") echo "1280" ;;
            "Xiaomi Redmi Note 4X") echo "1080" ;;
            *) echo "1920" ;;
        esac
    fi
}
```

**Device Model Detection**:

```bash
function get_device_model() {
    # Priority order
    if [ -d "/usr/local/lib/argononeup" ]; then
        echo "Argon ONE UP"
    elif [ -f "/proc/device-tree/model" ]; then
        local model=$(cat "/proc/device-tree/model")
        case "${model}" in
            *"Raspberry Pi Compute Module 5"*) echo "Raspberry Pi Compute Module 5" ;;
            *"Steam Deck"*) echo "Steam Deck" ;;
            *"Redmi Note 4X"*) echo "Xiaomi Redmi Note 4X" ;;
            *) echo "${model}" ;;
        esac
    elif command -v dmidecode >/dev/null 2>&1; then
        dmidecode -s system-product-name 2>/dev/null || echo "Unknown"
    else
        echo "Unknown"
    fi
}
```

### package-management.sh Deep Dive

**AUR Helper Preference**:

```bash
function call_package_manager() {
    local operation="$1"
    shift
    local packages=("$@")

    case "${DISTRO_FAMILY}" in
        "Arch")
            # Prefer AUR helpers
            if command -v paru >/dev/null 2>&1; then
                call_package_manager "paru" "${operation}" "${packages[@]}"
            elif command -v yay >/dev/null 2>&1; then
                call_package_manager "yay" "${operation}" "${packages[@]}"
            elif command -v yaourt >/dev/null 2>&1; then
                call_package_manager "yaourt" "${operation}" "${packages[@]}"
            else
                call_package_manager "pacman" "${operation}" "${packages[@]}"
            fi
            ;;
        "Debian"|"Ubuntu")
            call_package_manager "apt" "${operation}" "${packages[@]}"
            ;;
        "Alpine")
            call_package_manager "apk" "${operation}" "${packages[@]}"
            ;;
        "Android")
            call_package_manager "pkg" "${operation}" "${packages[@]}"
            ;;
        *)
            echo "Unsupported distro family: ${DISTRO_FAMILY}"
            return 1
            ;;
    esac
}
```

**Package Installation Logic**:

```bash
function install_native_package() {
    local package="$1"
    case "${DISTRO_FAMILY}" in
        "Arch")
            call_package_manager "install" "--noconfirm" "${package}"
            ;;
        "Debian"|"Ubuntu")
            call_package_manager "install" "-y" "${package}"
            ;;
        "Alpine")
            call_package_manager "add" "${package}"
            ;;
        "Android")
            call_package_manager "install" "${package}"
            ;;
    esac
}
```

### config.sh Deep Dive

**INI File Handling**:

```bash
function set_ini_config_value() {
    local file="$1" key="$2" value="$3"
    local section="$4" separator="=" quote="'"

    # Create section if missing
    if [ -n "${section}" ]; then
        if ! grep -q "^\[${section}\]" "${file}"; then
            echo "[${section}]" >> "${file}"
        fi
    fi

    # Update or append key
    if [ -n "${section}" ]; then
        # Sectioned INI
        local pattern="^${section}\]\\s*\n${key}${separator}.*$"
        if grep -q "${pattern}" "${file}"; then
            # Replace existing
            sed -i "s/^${section}\]\\s*\n${key}${separator}.*$/${section}\n${key}${separator}${value}/" "${file}"
        else
            # Append to section
            sed -i "/^\[${section}\]/a ${key}${separator}${value}" "${file}"
        fi
    else
        # Non-sectioned INI
        if grep -q "^${key}${separator}.*$" "${file}"; then
            sed -i "s/^${key}${separator}.*$/${key}${separator}${value}/" "${file}"
        else
            echo "${key}${separator}${value}" >> "${file}"
        fi
    fi
}
```

**JSON File Handling**:

```bash
function set_json_property() {
    local file="$1" key="$2" value="$3"

    if command -v jq >/dev/null 2>&1; then
        # Use jq for proper JSON manipulation
        jq --arg key "${key}" --argjson val "${value}" '.[$key] = $val' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
    else
        # Fallback to sed (fragile)
        local pattern="\"${key}\"[[:space:]]*:[[:space:]]*[^,}]*"
        sed -i "s/${pattern}/\"${key}\": ${value}/" "${file}"
    fi
}
```

### service-management.sh Deep Dive

**Service Existence Check**:

```bash
function does_service_exist() {
    local service="$1"
    local found=0

    # systemd system services
    if [ -f "/etc/systemd/system/${service}.service" ] || \
       [ -f "/lib/systemd/system/${service}.service" ] || \
       [ -f "/usr/lib/systemd/system/${service}.service" ]; then
        found=1
    fi

    # systemd user services
    if [ -f "~/.config/systemd/user/${service}.service" ]; then
        found=1
    fi

    # OpenRC services
    if [ -f "/etc/init.d/${service}" ] || \
       [ -L "/etc/runlevels/default/${service}" ]; then
        found=1
    fi

    return ${found}
}
```

**Service Enable/Disable**:

```bash
function enable_service() {
    local service="$1"
    case "${DISTRO_FAMILY}" in
        "Arch"|"Debian"|"Ubuntu")
            systemctl enable --now "${service}"
            ;;
        "Alpine")
            rc-update add "${service}" default
            rc-service "${service}" start
            ;;
        *)
            echo "Unsupported distro family: ${DISTRO_FAMILY}"
            return 1
            ;;
    esac
}
```

## Module Integration Examples

### Example 1: Package Installation Script

```bash
#!/bin/bash

# Source foundation modules
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/package-management.sh"

# Install packages based on device profile
if ${IS_DEVELOPMENT_DEVICE}; then
    install_native_packages "git" "vim" "build-essential"
    install_cargo_package "cargo-watch"
    install_github_release "owner/repo" "tool-linux-x86_64"
fi

if ${HAS_GUI}; then
    install_flatpak "io.gitlab.librewolf-community" "com.mattjakeman.ExtensionManager"
    call_gnome_extensions "uuid-org-gnome-shell-extension"
fi
```

### Example 2: Configuration Script

```bash
#!/bin/bash

# Source foundation modules
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Configure theme
update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bashrc"
set_config_value "${HOME}/.config/gtk-3.0/settings.ini" "gtk-theme-name" "${GTK_THEME}"

# Configure Git
set_config_value "${HOME}/.config/git/config" "user.name" "John Doe"
set_config_value "${HOME}/.config/git/config" "user.email" "john@example.com"

# Configure permissions (requires package-management for is_flatpak_installed)
source "scripts/common/package-management.sh"
source "scripts/common/permissions.sh"

set_linux_permission "io.gitlab.librewolf-community" "camera" "yes"
set_linux_permission "io.gitlab.librewolf-community" "microphone" "yes"
```

### Example 3: Service Management Script

```bash
#!/bin/bash

# Source foundation modules
source "scripts/common/filesystem.sh"
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/service-management.sh"

# Enable services based on device profile
if ${IS_SERVER}; then
    enable_services "chrony" "fail2ban" "docker"
else
    enable_services "NetworkManager" "bluetooth" "cups"
fi

# Mask unwanted services (GNOME)
if [ "${DESKTOP_ENVIRONMENT}" = "gnome" ]; then
    mask_user_services "gnome-software" "gnome-software-monitor" \
                       "ibus" "tracker-miner-fs" "localsearch-3"
fi
```

## Module Testing Strategy

### Unit Testing Foundation Modules

```bash
# Test filesystem.sh functions
function test_does_directory_exist() {
    local temp_dir=$(mktemp -d)
    assertTrue "does_directory_exist should return 0 for existing dir" \
              does_directory_exist "${temp_dir}"
    assertFalse "does_directory_exist should return 1 for non-existent dir" \
               does_directory_exist "/non/existent/path"
    rm -rf "${temp_dir}"
}

function test_does_file_exist() {
    local temp_file=$(mktemp)
    assertTrue "does_file_exist should return 0 for existing file" \
              does_file_exist "${temp_file}"
    assertFalse "does_file_exist should return 1 for non-existent file" \
               does_file_exist "/non/existent/file"
    rm -f "${temp_file}"
}
```

### Integration Testing

```bash
# Test package management abstraction
function test_call_package_manager() {
    # Mock package manager for testing
    export DISTRO_FAMILY="Test"
    # ... test logic
}

# Test privilege escalation
function test_run_as_su() {
    # Test with mocked sudo/su
    # ... test logic
}
```

## Module Maintenance Guidelines

### 1. Adding New Foundation Module

1. **Create new file** in `scripts/common/` (e.g., `new-module.sh`)
2. **Define exported functions** with clear signatures
3. **Document dependencies** in module header
4. **Add sourcing guard** to prevent double-execution
5. **Update dependency graph** in this document

### 2. Modifying Existing Module

1. **Maintain backward compatibility** — don't break existing function signatures
2. **Add tests** for new functionality
3. **Update documentation** in this file
4. **Check all consumers** for potential breakage

### 3. Module Removal

1. **Update all consumer scripts** to remove module sourcing
2. **Update dependency graph**
3. **Archive module** (don't delete for historical reference)
4. **Update documentation**

## Module Performance Considerations

### 1. Detection Cost

- `system-info.sh` runs detection **once** at source time
- Detection functions are called **multiple times** across scripts
- Expensive operations (dmidecode, lspci, wayland-info) cached in exported vars

### 2. File Operations

- `update_file_if_distinct` performs **content comparison** (I/O overhead)
- Binary file checks use `update_file_if_binary_exists` guard
- Symlink creation uses `create_symlink` with directory creation

### 3. Privilege Escalation

- `run_as_su` checks `HAS_SU_PRIVILEGES` **each call**
- Passwordless sudo required for non-interactive runs
- Android/Termux uses `su -c` instead of `sudo`

## Module Security Considerations

### 1. Privilege Separation

- Root operations only via `run_as_su` / `run_script_as_su`
- User operations via `run_script`
- No ambient authority; explicit per-script privilege declaration

### 2. Path Traversal

- All paths resolved via `filesystem.sh` utilities
- No user input directly used in filesystem operations
- Symlinks created with `create_symlink` (safe target)

### 3. Configuration Injection

- Configuration files written via `set_config_value` (sanitized)
- INI/JSON/XML parsing uses safe defaults
- No eval or exec on user-controlled data

## Module Compatibility

### Supported Platforms

| Module | Arch Linux | Debian | Ubuntu | Alpine | Android | SteamOS | WSL |
|--------|------------|--------|--------|--------|---------|---------|-----|
| filesystem.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| common.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| system-info.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| package-management.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| config.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| service-management.sh | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| apps.sh | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| permissions.sh | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| github.sh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

### Platform-Specific Behavior

- **Android/Termux**: No systemd, no GUI, `pkg` package manager, `su` instead of `sudo`
- **SteamOS**: Read-only rootfs, no AUR, Flatpak preferred, user-level configs only
- **WSL**: Early exit for system config, no kernel modules, no GRUB
- **Immutable distros**: rpm-ostree for base, Flatpak for apps, no `/etc` mutation

## Future Enhancements

### 1. Module Expansion

- **Network configuration** module (NetworkManager, netctl)
- **Audio configuration** module (PipeWire, PulseAudio)
- **Security module** (fail2ban, apparmor, SELinux)
- **Backup module** (rsync, tar, compression)

### 2. Performance Improvements

- **Lazy detection** — defer expensive detection until needed
- **Caching layer** — store detection results in temporary files
- **Parallel execution** — run independent scripts in parallel

### 3. Testing Framework

- **Unit tests** for each foundation module
- **Integration tests** for script chains
- **End-to-end tests** for provisioning scenarios
- **Mock framework** for testing without target system

### 4. Documentation Automation

- **Generate API docs** from function signatures
- **Auto-update dependency graph** from module imports
- **Validate configuration** against schema

## Conclusion

The foundation layer provides the **essential infrastructure** for the
linux-setup-script repository. Its 9 modules handle:

1. **Path resolution** and platform abstraction
2. **Privilege escalation** and execution control
3. **Hardware/environment detection** and variable export
4. **Package management** abstraction across 6 package managers
5. **Configuration file manipulation** for 3 formats
6. **Service management** for systemd and OpenRC
7. **Application-specific utilities** (Firefox, permissions, GitHub)

These modules enable **consistent, idempotent, platform-aware** system
provisioning while maintaining **clear privilege boundaries** and **single
source of truth** for all configuration.

The foundation layer's design ensures **maintainability**, **testability**,
and **extensibility** while supporting the repository's goal of **automating
Linux system setup across diverse platforms and hardware configurations**.