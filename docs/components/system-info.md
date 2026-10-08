# System Info Component

This document provides a deep dive into the system info component,
which handles environment detection and platform identification.

## Overview

**Location**: `scripts/common/system-info.sh`

**Purpose**: Detect and export system information including OS, distribution,
architecture, hardware, and device type.

**Consumers**: All scripts in the repository (foundation layer, configuration
scripts, update scripts, profile scripts)

## Core Functions

### 1. OS Detection

```bash
# Detect operating system
detect_os
# Exports: OS (linux, android, darwin, windows)

# Detect distribution
detect_distro
# Exports: DISTRO (arch, debian, ubuntu, alpine, etc.)

# Detect distribution family
detect_distro_family
# Exports: DISTRO_FAMILY (arch, debian, alpine, android, etc.)

# Detect architecture
detect_arch
# Exports: ARCH (x86_64, aarch64, armv7l, etc.)
```

### 2. Hardware Detection

```bash
# Detect device model
detect_device_model
# Exports: DEVICE_MODEL

# Detect chassis type
detect_chassis_type
# Exports: CHASSIS_TYPE (desktop, laptop, server, etc.)

# Detect GPU family
detect_gpu_family
# Exports: GPU_FAMILY (intel, amd, nvidia, etc.)

# Detect CPU info
detect_cpu_info
# Exports: CPU_VENDOR, CPU_MODEL, CPU_CORES, CPU_THREADS

# Detect memory info
detect_memory_info
# Exports: TOTAL_MEMORY, AVAILABLE_MEMORY
```

### 3. Display Detection

```bash
# Detect if GUI is available
detect_has_gui
# Exports: HAS_GUI (true/false)

# Detect desktop environment
detect_desktop_environment
# Exports: DESKTOP_ENVIRONMENT (gnome, kde, xfce, lxde, etc.)

# Detect display server
detect_display_server
# Exports: DISPLAY_SERVER (x11, wayland, tty)

# Detect screen resolution
detect_screen_resolution
# Exports: SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_DPI
```

### 4. Device Type Detection

```bash
# Detect if battery device
detect_is_battery_device
# Exports: IS_BATTERY_DEVICE (true/false)

# Detect if powerful PC
detect_is_powerful_pc
# Exports: IS_POWERFUL_PC (true/false)

# Detect if development device
detect_is_development_device
# Exports: IS_DEVELOPMENT_DEVICE (true/false)

# Detect if gaming device
detect_is_gaming_device
# Exports: IS_GAMING_DEVICE (true/false)

# Detect if general purpose device
detect_is_general_purpose_device
# Exports: IS_GENERAL_PURPOSE_DEVICE (true/false)
```

### 5. Privilege Detection

```bash
# Detect if has SU privileges
detect_has_su_privileges
# Exports: HAS_SU_PRIVILEGES (true/false)

# Check if running as root
is_root
# Returns 0 if UID=0, 1 otherwise

# Check if sudo is available
has_sudo
# Returns 0 if sudo available, 1 otherwise

# Check if su is available
has_su
# Returns 0 if su available, 1 otherwise
```

### 6. Platform Detection

```bash
# Detect if Android/Termux
is_android_termux
# Returns 0 if Android/Termux, 1 otherwise

# Detect if SteamOS
is_steamos
# Returns 0 if SteamOS, 1 otherwise

# Detect if WSL
is_wsl
# Returns 0 if WSL, 1 otherwise

# Detect if container
is_container
# Returns 0 if container, 1 otherwise

# Detect if VM
is_vm
# Returns 0 if VM, 1 otherwise
```

## Exported Variables

### Core System Info

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `OS` | Operating system | `linux`, `android`, `darwin` |
| `DISTRO` | Distribution name | `arch`, `debian`, `ubuntu`, `alpine` |
| `DISTRO_FAMILY` | Distribution family | `arch`, `debian`, `alpine`, `android` |
| `ARCH` | CPU architecture | `x86_64`, `aarch64`, `armv7l` |
| `DEVICE_MODEL` | Device model string | `ThinkPad X1 Carbon`, `Steam Deck` |
| `CHASSIS_TYPE` | Chassis type | `desktop`, `laptop`, `server` |
| `GPU_FAMILY` | GPU vendor family | `intel`, `amd`, `nvidia` |

### Display Info

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `HAS_GUI` | GUI availability | `true`, `false` |
| `DESKTOP_ENVIRONMENT` | Desktop environment | `gnome`, `kde`, `xfce`, `lxde` |
| `DISPLAY_SERVER` | Display server | `x11`, `wayland`, `tty` |
| `SCREEN_WIDTH` | Screen width in pixels | `1920`, `3840` |
| `SCREEN_HEIGHT` | Screen height in pixels | `1080`, `2160` |
| `SCREEN_DPI` | Screen DPI | `96`, `144`, `192` |

### Device Type Info

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `IS_BATTERY_DEVICE` | Battery-powered device | `true`, `false` |
| `IS_POWERFUL_PC` | High-performance PC | `true`, `false` |
| `IS_DEVELOPMENT_DEVICE` | Development-focused device | `true`, `false` |
| `IS_GAMING_DEVICE` | Gaming-focused device | `true`, `false` |
| `IS_GENERAL_PURPOSE_DEVICE` | General-purpose device | `true`, `false` |

### Privilege Info

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `HAS_SU_PRIVILEGES` | Has root/sudo access | `true`, `false` |

## Detection Logic

### OS Detection

```bash
detect_os() {
    if [ -n "${ANDROID_ROOT}" ] || [ -n "${TERMUX_VERSION}" ]; then
        OS="android"
    elif [ "$(uname -s)" = "Darwin" ]; then
        OS="darwin"
    else
        OS="linux"
    fi
}
```

### Distribution Detection

```bash
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID}"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/alpine-release ]; then
        DISTRO="alpine"
    else
        DISTRO="unknown"
    fi
}
```

### Architecture Detection

```bash
detect_arch() {
    ARCH="$(uname -m)"
    # Normalise architecture names
    case "${ARCH}" in
        x86_64|amd64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        armv7l|armv6l) ARCH="armv7l" ;;
    esac
}
```

### GPU Detection

```bash
detect_gpu_family() {
    if command_exists lspci; then
        if lspci | grep -i vga | grep -i intel >/dev/null 2>&1; then
            GPU_FAMILY="intel"
        elif lspci | grep -i vga | grep -i amd >/dev/null 2>&1; then
            GPU_FAMILY="amd"
        elif lspci | grep -i vga | grep -i nvidia >/dev/null 2>&1; then
            GPU_FAMILY="nvidia"
        fi
    fi
}
```

### Device Type Detection

```bash
detect_is_battery_device() {
    if [ -d /sys/class/power_supply/BAT0 ] || \
       [ -d /sys/class/power_supply/BAT1 ]; then
        IS_BATTERY_DEVICE="true"
    else
        IS_BATTERY_DEVICE="false"
    fi
}

detect_is_gaming_device() {
    # Steam Deck detection
    if [ -f /sys/firmware/dmi/tables/DMI ] && \
       grep -q "Steam Deck" /sys/firmware/dmi/tables/DMI 2>/dev/null; then
        IS_GAMING_DEVICE="true"
    # High-end GPU detection
    elif [ "${GPU_FAMILY}" = "nvidia" ] || \
         [ "${GPU_FAMILY}" = "amd" ]; then
        IS_GAMING_DEVICE="true"
    else
        IS_GAMING_DEVICE="false"
    fi
}
```

## Usage Patterns

### Pattern 1: Platform-Specific Configuration

```bash
#!/bin/bash
source "scripts/common/system-info.sh"

# Platform-specific package manager
case "${DISTRO_FAMILY}" in
    arch)
        install_packages "base-devel" "git"
        ;;
    debian)
        install_packages "build-essential" "git"
        ;;
    alpine)
        install_packages "build-base" "git"
        ;;
    android)
        pkg install "git"
        ;;
esac
```

### Pattern 2: Device-Type-Aware Configuration

```bash
#!/bin/bash
source "scripts/common/system-info.sh"

# Battery device: optimise for power
if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
    set_modprobe_option "i915" "enable_dc" "2"
    set_modprobe_option "i915" "enable_fbc" "1"
fi

# Gaming device: optimise for performance
if [ "${IS_GAMING_DEVICE}" = "true" ]; then
    set_modprobe_option "i915" "enable_guc" "3"
    set_modprobe_option "i915" "enable_psr" "2"
fi

# Powerful PC: enable aggressive optimisations
if [ "${IS_POWERFUL_PC}" = "true" ]; then
    set_config_value "/etc/default/grub" "GRUB_CMDLINE_LINUX_DEFAULT" \
        "mitigations=off random.trust_cpu=on fsck.repair=yes"
fi
```

### Pattern 3: GUI-Aware Configuration

```bash
#!/bin/bash
source "scripts/common/system-info.sh"

# Only configure desktop if GUI available
if [ "${HAS_GUI}" = "true" ]; then
    # Desktop environment specific config
    case "${DESKTOP_ENVIRONMENT}" in
        gnome)
            set_gsettings "org.gnome.desktop.interface" "gtk-theme" "${GTK_THEME}"
            ;;
        kde)
            set_gsettings "org.kde.desktop" "theme" "${GTK_THEME}"
            ;;
        xfce)
            set_gsettings "xsettings" "Net/ThemeName" "${GTK_THEME}"
            ;;
    esac
fi
```

### Pattern 4: Privilege-Aware Operations

```bash
#!/bin/bash
source "scripts/common/system-info.sh"
source "scripts/common/common.sh"

# System configuration requires privileges
if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
    run_as_su set_config_value "/etc/systemd/system.conf" \
        "DefaultTimeoutStartSec" "90s"
else
    log_warn "No SU privileges, skipping system configuration"
fi
```

## System Info Invariants

1. **Early detection** — All detection runs at script start
2. **Exported variables** — All values exported for child processes
3. **Platform awareness** — Handles Linux, Android, macOS
4. **Graceful degradation** — Missing tools don't crash detection
5. **Cached results** — Detection runs once per session
6. **No side effects** — Detection is read-only

## Error Handling

| Function | Failure Mode | Handling |
|----------|--------------|----------|
| `detect_os` | Unknown OS | Sets `OS="unknown"` |
| `detect_distro` | No release file | Sets `DISTRO="unknown"` |
| `detect_gpu_family` | No lspci | Sets `GPU_FAMILY=""` |
| `detect_has_su_privileges` | No sudo/su | Sets `HAS_SU_PRIVILEGES="false"` |
| `detect_screen_resolution` | No display | Sets `SCREEN_WIDTH=0`, `SCREEN_HEIGHT=0` |

## Performance Considerations

- **Single pass** — All detection in one function call
- **Lazy evaluation** — Expensive checks only when needed
- **Command caching** — `command_exists` results cached
- **Minimal subprocesses** — Built-in bash operations preferred

## Security Considerations

- **Read-only** — Detection does not modify system state
- **No network** — Detection uses local system info only
- **No secrets** — No sensitive data in detection
- **Path safety** — Uses standard system paths

## Testing

### Unit Tests

```bash
function test_detect_os() {
    detect_os
    assertNotNull "OS is set" "${OS}"
    assertTrue "OS is valid" "[ '${OS}' = 'linux' ] || [ '${OS}' = 'android' ] || [ '${OS}' = 'darwin' ]"
}

function test_detect_arch() {
    detect_arch
    assertNotNull "ARCH is set" "${ARCH}"
    assertTrue "ARCH is valid" "[ '${ARCH}' = 'x86_64' ] || [ '${ARCH}' = 'aarch64' ] || [ '${ARCH}' = 'armv7l' ]"
}

function test_detect_has_su_privileges() {
    detect_has_su_privileges
    assertTrue "HAS_SU_PRIVILEGES is boolean" "[ '${HAS_SU_PRIVILEGES}' = 'true' ] || [ '${HAS_SU_PRIVILEGES}' = 'false' ]"
}
```

### Integration Tests

```bash
function test_all_detection() {
    detect_os
    detect_distro
    detect_distro_family
    detect_arch
    detect_device_model
    detect_chassis_type
    detect_gpu_family
    detect_has_gui
    detect_desktop_environment
    detect_display_server
    detect_is_battery_device
    detect_is_powerful_pc
    detect_is_development_device
    detect_is_gaming_device
    detect_is_general_purpose_device
    detect_has_su_privileges

    # Verify all variables are set
    assertNotNull "OS" "${OS}"
    assertNotNull "DISTRO" "${DISTRO}"
    assertNotNull "DISTRO_FAMILY" "${DISTRO_FAMILY}"
    assertNotNull "ARCH" "${ARCH}"
}
```

## Future Enhancements

1. **Container detection** — Better Docker/Podman detection
2. **VM detection** — Improved VM detection (KVM, VMware, VirtualBox)
3. **Hardware serial** — Device serial number detection
4. **BIOS/UEFI** — Firmware type detection
5. **Secure Boot** — Secure Boot status detection
6. **TPM** — TPM chip detection
7. **Battery health** — Battery health and capacity detection