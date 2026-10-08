# System Info API Reference

This document provides API reference for system information detection in the linux-setup-script repository.

## Environment Variables

### Platform Detection

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `OS` | string | Operating system name | `Linux` |
| `DISTRO` | string | Distribution name | `Arch` |
| `DISTRO_FAMILY` | string | Distribution family | `Arch`, `Debian`, `Ubuntu`, `Alpine`, `Android` |
| `ARCH` | string | Architecture | `x86_64`, `aarch64` |

### Device Detection

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `DEVICE_MODEL` | string | Device model name | `ThinkPad X1 Carbon` |
| `CHASSIS_TYPE` | string | Chassis type | `laptop`, `desktop`, `server` |
| `IS_BATTERY_DEVICE` | boolean | Has battery | `true` or `false` |
| `POWERFUL_PC` | boolean | Powerful PC | `true` or `false` |

### Display Detection

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `HAS_GUI` | boolean | Has graphical interface | `true` or `false` |
| `DESKTOP_ENVIRONMENT` | string | Desktop environment | `GNOME`, `KDE`, `MATE`, `LXDE`, `Phosh` |
| `DISPLAY_SERVER` | string | Display server | `X11`, `Wayland` |
| `GTK_THEME` | string | GTK theme name | `Adwaita` |
| `GTK_THEME_VARIANT` | string | Theme variant | `dark` or `light` |

### Hardware Detection

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `GPU_FAMILY` | string | GPU family | `nvidia`, `amd`, `intel` |
| `IS_DEVELOPMENT_DEVICE` | boolean | Development device | `true` or `false` |
| `IS_GAMING_DEVICE` | boolean | Gaming device | `true` or `false` |
| `IS_GENERAL_PURPOSE_DEVICE` | boolean | General purpose device | `true` or `false` |

### Privilege Detection

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `HAS_SU_PRIVILEGES` | boolean | Can escalate to root | `true` or `false` |
| `RUN_AS_SU` | string | Command prefix for root | `sudo -n` or `su -c` |

## Detection Functions

### detect_os

```bash
function detect_os() {
    local OS_NAME
    OS_NAME="$(uname -s)"
    echo "${OS_NAME}"
}
```

**Returns:**
- Operating system name

**Example:**
```bash
OS="$(detect_os)"
```

### detect_distro

```bash
function detect_distro() {
    local DISTRO_NAME
    DISTRO_NAME="$(. /etc/os-release && echo "${NAME:-${ID}}")"
    echo "${DISTRO_NAME}"
}
```

**Returns:**
- Distribution name

**Example:**
```bash
DISTRO="$(detect_distro)"
```

### detect_arch

```bash
function detect_arch() {
    local ARCH_NAME
    ARCH_NAME="$(uname -m)"
    echo "${ARCH_NAME}"
}
```

**Returns:**
- Architecture name

**Example:**
```bash
ARCH="$(detect_arch)"
```

## Platform-Specific Detection

### Android/Termux Detection

```bash
# Check if running on Android/Termux
if does_directory_exist "/data/data/com.termux/files/usr"; then
    IS_ANDROID=true
else
    IS_ANDROID=false
fi
```

### SteamOS Detection

```bash
# Check if running on SteamOS
if [[ "${DISTRO}" == "SteamOS" ]]; then
    IS_STEAMOS=true
else
    IS_STEAMOS=false
fi
```

### WSL Detection

```bash
# Check if running on WSL
if grep -q "microsoft" /proc/version 2>/dev/null; then
    IS_WSL=true
else
    IS_WSL=false
fi
```

## See Also

- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [components/filesystem.md](../components/filesystem.md) — Filesystem operations
- [components/common.md](../components/common.md) — Execution primitives