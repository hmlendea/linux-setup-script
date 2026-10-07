# 03 — Foundation Layer

The foundation layer consists of four core modules in `scripts/common/` that
provide shared utilities for all higher-level scripts.

## 3.1 `filesystem.sh` — Path Resolution & Constants

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

---

## 3.2 `common.sh` — Execution Primitives & Shell Setup

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

---

## 3.3 `system-info.sh` — Hardware & Environment Detection

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

---

## 3.4 `package-management.sh` — Package Manager Abstraction

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

### Specialised Helpers

| Function | Purpose |
|----------|---------|
| `call_cargo` | Wrapper for `cargo` with args |
| `call_flatpak` | Wrapper for `flatpak --assumeyes` |
| `call_vscode` | Detects `code`/`codium`/`code-oss`/`com.visualstudio.code` |
| `get_latest_github_release_assets` | Fetches download URLs from GitHub API |

---

## 3.5 `config.sh` — Configuration File Manipulation

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

---

## 3.6 `service-management.sh` — Systemd/OpenRC Service Control

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

---

## 3.7 `apps.sh` — Firefox Profile Detection

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

---

## 3.8 `permissions.sh` — Application Permission Management

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

---

## 3.9 `github.sh` — GitHub API Helpers

**Location**: `scripts/common/github.sh`

**Purpose**: Minimal GitHub API interaction.

### Function

| Function | Description |
|----------|-------------|
| `get_latest_github_release_assets <owner/repo>` | Returns download URLs for latest release assets |

---

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