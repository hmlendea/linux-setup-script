# 02 — Execution Model

## Entry Points

### Primary: `run.sh`

**Location**: `/home/horatiu/Proiecte/scripts/linux-setup-script/run.sh`

**Invocation**: Direct execution `./run.sh` or `bash run.sh`

**Responsibilities**:
1. Resolve absolute repository path (`EXEDIR`, `REPO_DIR`)
2. Ensure `USER` environment variable is set (Android/Termux fix)
3. Source foundation libraries: `filesystem.sh`, `common.sh`, `package-management.sh`, `system-info.sh`
4. Request SU privileges early (via `run_as_su printf`)
5. Print system information banner
6. Remove `/etc/motd`
7. Execute all phases in strict sequence (see below)

### Secondary: Individual Scripts

Each script in `scripts/` can be executed independently for targeted operations.
They all source `filesystem.sh` and `common.sh` at minimum.

## Execution Flow (run.sh)

```
Phase 0: Environment Setup
    ├── Source foundation libraries
    ├── Detect and export system info (DEVICE_TYPE, DISTRO_FAMILY, etc.)
    └── Request SU privileges

Phase 1: Package Repositories & Management (Linux only)
    ├── configure-repositories.sh (as root)
    ├── update-repositories.sh (user)
    ├── uninstall-packages.sh (user)
    ├── update-packages.sh (user)
    ├── install-packages.sh (user)
    ├── uninstall-packages.sh (user, second pass)
    └── clean-packages.sh (user)

Phase 2: Configuration Deployment
    ├── update-rcs.sh (user)
    ├── update-rcs.sh (root, Linux only)
    ├── update-resources.sh (user, Linux only)
    ├── update-resources.sh (root, Linux only)

Phase 3: System Configuration
    ├── configure-system.sh (user)
    ├── configure-system.sh (root, Linux only)
    ├── configure-launchers.sh (user, Linux GUI, non-WSL)
    ├── configure-autostart-apps.sh (user, Linux GUI, non-WSL)
    ├── configure-default-apps.sh (user, Linux GUI, non-WSL)
    ├── configure-permissions.sh (user, Linux GUI)
    ├── configure-locale.sh (root, Linux only)
    ├── configure-time.sh (root, Linux only)
    ├── update-profiles.sh (root, non-Android)
    ├── configure-services-user.sh (user, Linux only)
    ├── configure-services-system.sh (root, Linux only)
    ├── configure-hardware-integration.sh (root, Linux only)
    ├── update-grub.sh (root, Linux only, if grub-mkconfig exists)
    └── configure-directories.sh (user)

Phase 4: Optional Git Setup (manual)
    ├── setup-gpg-key.sh
    └── setup-ssh-key.sh
```

## Privilege Model

### `run_as_su` Function (`common.sh`)

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
    fi
}
```

### `run_script` vs `run_script_as_su`

| Function | Context | Use Case |
|----------|---------|----------|
| `run_script` | Current user | User-level config, package installs (with AUR helpers) |
| `run_script_as_su` | Root (via sudo/su) | System config, service management, /etc modifications |

**Key invariant**: `run_script_as_su` returns immediately if `HAS_SU_PRIVILEGES` is false.

### `HAS_SU_PRIVILEGES` Detection

Set in `system-info.sh` based on:
- `sudo -n true 2>/dev/null` (passwordless sudo)
- `su -c 'true' 2>/dev/null` (Android/Termux)
- UID 0 (already root)

## Environment Detection (`system-info.sh`)

All detection happens at source time of `system-info.sh` (sourced by `run.sh` and most scripts).

### Core Exported Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `OS` | `uname -s` | 'Linux', 'Android', 'Windows' (WSL) |
| `DISTRO` | `/etc/os-release` | Pretty name (e.g., 'Arch Linux') |
| `DISTRO_FAMILY` | ID_LIKE/ID | 'Arch', 'Debian', 'Ubuntu', 'Alpine', 'Android' |
| `ARCH` | `uname -m` / `lscpu` | 'x86_64', 'aarch64', 'armv7l', etc. |
| `ARCH_FAMILY` | Derived from ARCH | 'x86', 'arm' |
| `DEVICE_MODEL` | `/proc/device-tree/model`, systemd, dmidecode | 'Steam Deck', 'Argon ONE UP CM5', etc. |
| `CHASSIS_TYPE` | `systemd-detect-virt`, dmidecode | 'Laptop', 'Desktop', 'Server', 'Tablet' |
| `HAS_GUI` | `XDG_SESSION_TYPE`, `DISPLAY`, `WAYLAND_DISPLAY` | Boolean |
| `DESKTOP_ENVIRONMENT` | `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION` | 'GNOME', 'KDE', 'MATE', 'LXDE', 'Phosh' |
| `DISPLAY_SERVER` | `XDG_SESSION_TYPE` | 'wayland', 'x11', 'tty' |
| `GPU_FAMILY` | `lspci`, `glxinfo` | 'Intel', 'Nvidia', 'AMD', 'Qualcomm' |
| `IS_BATTERY_DEVICE` | `/sys/class/power_supply/*/type` | Boolean |
| `POWERFUL_PC` | CPU cores, RAM, GPU | Heuristic for performance tuning |
| `IS_DEVELOPMENT_DEVICE` | Hostname, packages | Heuristic |
| `IS_GAMING_DEVICE` | Packages, GPU | Heuristic |
| `IS_GENERAL_PURPOSE_DEVICE` | Negation of above | Heuristic |

### Screen Detection

| Function | Method |
|----------|--------|
| `get_screen_width` | Wayland: `wayland-info`; X11: `xrandr`/`xdpyinfo`; Fallback: device-specific |
| `get_screen_height` | Same as width |
| `get_screen_dpi` | Calculated from width + physical mm; X11: `xdpyinfo` resolution |

**Special cases**: Steam Deck (1280×800), Xiaomi Redmi Note 4X (1080×1920, 401 DPI)

### Device Model Detection (`get_device_model`)

Priority order:
1. Argon ONE UP (systemd service, kernel module, source directory)
2. Raspberry Pi Compute Module 5 (device tree)
3. Steam Deck (device tree)
4. Xiaomi Redmi Note 4X (device tree)
5. Generic x86 laptop/desktop (dmidecode)
6. Android device (props)

## Script Sourcing Conventions

Every script begins with:

```bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
```

Then sources:
- `scripts/common/filesystem.sh` → establishes `REPO_DIR`, `REPO_*_DIR`, `ROOT_*`, `HOME_REAL`
- `scripts/common/common.sh` → `run_as_su`, `run_script`, `run_script_as_su`, `LANG=en_US.UTF-8`
- Additional common modules as needed

## Execution Guarantees

1. **Ordering** — `run.sh` enforces strict phase ordering; dependencies flow forward
2. **Idempotency** — All file operations use `update_file_if_distinct`; package operations check `is_package_installed`
3. **Failure isolation** — Individual script failures don't halt `run.sh` (no `set -e` at top level)
4. **Privilege escalation** — Explicit per-script; no ambient authority
5. **Environment consistency** — `LANG=en_US.UTF-8` forced for deterministic command output