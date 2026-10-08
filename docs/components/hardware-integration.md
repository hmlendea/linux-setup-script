# Hardware Integration

This document describes the hardware integration system for device-specific
configuration, including Argon ONE UP, GPU, laptop power management, and
other hardware-specific setup.

## Overview

The hardware integration module detects and configures hardware-specific
settings based on device model, chassis type, and available hardware
components.

## Device Detection

### Chassis Type Detection

```bash
# scripts/common/system-info.sh

# Detect chassis type
detect_chassis_type() {
    local chassis=""

    # Try DMI first
    if [ -f /sys/class/dmi/id/chassis_type ]; then
        chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)
    fi

    # Fallback to systemd
    if [ -z "${chassis}" ]; then
        chassis=$(hostnamectl chassis 2>/dev/null)
    fi

    # Map numeric to string
    case "${chassis}" in
        1)  echo "desktop" ;;
        2)  echo "desktop" ;;  # Multi-system chassis
        3)  echo "server" ;;
        4)  echo "laptop" ;;
        5)  echo "laptop" ;;  # Laptop (with removable disk)
        6)  echo "desktop" ;;  # Blade
        7)  echo "desktop" ;;  # Hand-held
        8)  echo "laptop" ;;  # Hand-held (with detachable)
        9)  echo "laptop" ;;  # Hand-held (with detachable)
        10) echo "desktop" ;;  # All-in-one
        11) echo "laptop" ;;  # Notebook
        12) echo "desktop" ;;  # Tower
        13) echo "desktop" ;;  # 2-in-1
        14) echo "laptop" ;;  # 2-in-1 (detachable)
        *)  echo "unknown" ;;
    esac
}

export CHASSIS_TYPE=$(detect_chassis_type)
```

### Device Model Detection

```bash
# Detect device model
detect_device_model() {
    local model=""

    # Try DMI
    if [ -f /sys/class/dmi/id/product_name ]; then
        model=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    fi

    # Try board name
    if [ -z "${model}" ] && [ -f /sys/class/dmi/id/board_name ]; then
        model=$(cat /sys/class/dmi/id/board_name 2>/dev/null)
    fi

    # Try device tree (ARM)
    if [ -z "${model}" ] && [ -f /proc/device-tree/model ]; then
        model=$(cat /proc/device-tree/model 2>/dev/null | cut -d' ' -f1-3)
    fi

    # Try Android
    if [ -z "${model}" ] && [ -f /system/build.prop ]; then
        model=$(grep "ro.product.model" /system/build.prop | cut -d'=' -f2)
    fi

    echo "${model}"
}

export DEVICE_MODEL=$(detect_device_model)
```

### Battery Detection

```bash
# Detect if device has battery
detect_battery() {
    if [ -d /sys/class/power_supply/BAT* ] || \
       [ -d /sys/class/power_supply/battery ]; then
        echo "true"
    else
        echo "false"
    fi
}

export IS_BATTERY_DEVICE=$(detect_battery)
```

## Argon ONE UP

### Hardware Overview

The Argon ONE UP is a Raspberry Pi 4-based handheld gaming console with
custom cooling and power management.

### Fan Control

```bash
# scripts/configure-hardware-integration.sh

# Configure Argon ONE UP fan control
configure_argon_one_up_fan() {
    if [ "${DEVICE_MODEL}" != "Argon ONE UP" ]; then
        return 0
    fi

    log_section "Configuring Argon ONE UP fan control"

    # Install Argon ONE UP scripts
    if ! command_exists argonone-cli; then
        log_info "Installing Argon ONE UP tools"
        curl -sSL https://github.com/Argon40Tech/Argon-One-Up-Iris-Service/raw/main/install.sh | bash
    fi

    # Configure fan curves
    argonone-cli setfan 50 0    # 50°C - off
    argonone-cli setfan 60 25   # 60°C - 25%
    argonone-cli setfan 70 50   # 70°C - 50%
    argonone-cli setfan 80 75   # 80°C - 75%
    argonone-cli setfan 90 100  # 90°C - 100%

    log_success "Argon ONE UP fan control configured"
}
```

### Power Button

```bash
# Configure power button behavior
configure_argon_one_up_power() {
    if [ "${DEVICE_MODEL}" != "Argon ONE UP" ]; then
        return 0
    fi

    log_info "Configuring Argon ONE UP power button"

    # Enable power button service
    systemctl enable argonone-powerbutton.service
    systemctl start argonone-powerbutton.service

    # Configure shutdown behavior
    argonone-cli setpowermode 1  # Normal mode
}
```

### IR Remote

```bash
# Configure IR remote
configure_argon_one_up_ir() {
    if [ "${DEVICE_MODEL}" != "Argon ONE UP" ]; then
        return 0
    fi

    log_info "Configuring Argon ONE UP IR remote"

    # Enable IR service
    systemctl enable argonone-ir.service
    systemctl start argonone-ir.service

    # Configure Lakka IR mapping
    if [ -d /etc/lakka/config ]; then
        cp "${REPO_DIR}/rc/boot_firmware_config_argononeup.txt" \
           /boot/firmware/config.txt
    fi
}
```

## GPU Configuration

### GPU Family Detection

```bash
# Detect GPU family
detect_gpu_family() {
    local gpu=""

    # NVIDIA
    if command_exists nvidia-smi; then
        gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
        echo "nvidia"
        return
    fi

    # AMD
    if command_exists lspci; then
        gpu=$(lspci | grep -i vga | grep -i amd 2>/dev/null)
        if [ -n "${gpu}" ]; then
            echo "amd"
            return
        fi
    fi

    # Intel
    if command_exists lspci; then
        gpu=$(lspci | grep -i vga | grep -i intel 2>/dev/null)
        if [ -n "${gpu}" ]; then
            echo "intel"
            return
        fi
    fi

    # Broadcom (Raspberry Pi)
    if [ -f /proc/device-tree/soc/v3d@7ec00000/status ] || \
       [ -f /proc/device-tree/v3d@7ec00000/status ]; then
        echo "broadcom"
        return
    fi

    echo "unknown"
}

export GPU_FAMILY=$(detect_gpu_family)
```

### GPU-Specific Configuration

```bash
# Configure GPU settings
configure_gpu() {
    log_section "Configuring GPU: ${GPU_FAMILY}"

    case "${GPU_FAMILY}" in
        nvidia)
            configure_nvidia_gpu
            ;;
        amd)
            configure_amd_gpu
            ;;
        intel)
            configure_intel_gpu
            ;;
        broadcom)
            configure_broadcom_gpu
            ;;
    esac
}

# NVIDIA GPU configuration
configure_nvidia_gpu() {
    log_info "Configuring NVIDIA GPU"

    # Install NVIDIA drivers
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
            ;;
        debian|ubuntu)
            apt-get install -y nvidia-driver nvidia-utils
            ;;
    esac

    # Configure power management
    set_config_value "/etc/modprobe.d/nvidia.conf" \
        "options nvidia NVreg_RegistryDwords=\"PerfLevelSrc=0x2222\""

    # Enable NVIDIA persistence daemon
    systemctl enable nvidia-persistenced
    systemctl start nvidia-persistenced
}

# AMD GPU configuration
configure_amd_gpu() {
    log_info "Configuring AMD GPU"

    # Install Mesa drivers
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon
            ;;
        debian|ubuntu)
            apt-get install -y mesa-vulkan-drivers xserver-xorg-video-amdgpu
            ;;
    esac

    # Enable AMDGPU power management
    set_config_value "/etc/modprobe.d/amdgpu.conf" \
        "options amdgpu ppfeaturemask=0xffffffff"
}

# Intel GPU configuration
configure_intel_gpu() {
    log_info "Configuring Intel GPU"

    # Install Mesa drivers
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm mesa xf86-video-intel vulkan-intel
            ;;
        debian|ubuntu)
            apt-get install -y mesa-vulkan-drivers xserver-xorg-video-intel
            ;;
    esac
}

# Broadcom (Raspberry Pi) GPU configuration
configure_broadcom_gpu() {
    log_info "Configuring Broadcom GPU"

    # Configure GPU memory split
    set_config_value "/boot/firmware/config.txt" \
        "gpu_mem=256"

    # Enable Vulkan
    set_config_value "/boot/firmware/config.txt" \
        "dtoverlay=vc4-kms-v3d"
}
```

## Laptop Power Management

### Power Profile Detection

```bash
# Detect if device is powerful PC
detect_powerful_pc() {
    local cpu_cores=$(nproc)
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local has_gpu="false"

    if [ "${GPU_FAMILY}" != "unknown" ] && [ "${GPU_FAMILY}" != "intel" ]; then
        has_gpu="true"
    fi

    if [ ${cpu_cores} -ge 8 ] && [ ${ram_gb} -ge 16 ] && [ "${has_gpu}" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

export IS_POWERFUL_PC=$(detect_powerful_pc)
```

### Power Management Configuration

```bash
# Configure power management
configure_power_management() {
    log_section "Configuring power management"

    # Install TLP
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm tlp tlp-rdw
            ;;
        debian|ubuntu)
            apt-get install -y tlp tlp-rdw
            ;;
    esac

    # Configure TLP
    set_config_value "/etc/tlp.conf" "TLP_ENABLE" "1"
    set_config_value "/etc/tlp.conf" "CPU_SCALING_GOVERNOR_ON_AC" "performance"
    set_config_value "/etc/tlp.conf" "CPU_SCALING_GOVERNOR_ON_BAT" "powersave"
    set_config_value "/etc/tlp.conf" "PCIE_ASPM_ON_AC" "performance"
    set_config_value "/etc/tlp.conf" "PCIE_ASPM_ON_BAT" "powersave"

    # Enable TLP
    systemctl enable tlp
    systemctl start tlp

    # Configure battery-specific settings
    if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
        configure_battery_power
    fi
}

# Battery power configuration
configure_battery_power() {
    log_info "Configuring battery power settings"

    # Reduce screen brightness
    set_config_value "/etc/tlp.conf" "RUNTIME_PM_ON_BAT" "auto"

    # USB autosuspend
    set_config_value "/etc/tlp.conf" "USB_AUTOSUSPEND" "1"

    # Audio power saving
    set_config_value "/etc/modprobe.d/audio.conf" \
        "options snd_hda_intel power_save=1"
}
```

## Audio Configuration

### Audio System Detection

```bash
# Detect audio system
detect_audio_system() {
    if command_exists pulseaudio; then
        echo "pulseaudio"
    elif command_exists pipewire; then
        echo "pipewire"
    else
        echo "alsa"
    fi
}

export AUDIO_SYSTEM=$(detect_audio_system)
```

### Audio Configuration

```bash
# Configure audio
configure_audio() {
    log_section "Configuring audio: ${AUDIO_SYSTEM}"

    case "${AUDIO_SYSTEM}" in
        pulseaudio)
            configure_pulseaudio
            ;;
        pipewire)
            configure_pipewire
            ;;
        alsa)
            configure_alsa
            ;;
    esac
}

# PulseAudio configuration
configure_pulseaudio() {
    log_info "Configuring PulseAudio"

    # Install
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm pulseaudio pulseaudio-alsa
            ;;
        debian|ubuntu)
            apt-get install -y pulseaudio pulseaudio-utils
            ;;
    esac

    # Configure
    set_config_value "/etc/pulse/daemon.conf" "default-sample-rate" "48000"
    set_config_value "/etc/pulse/daemon.conf" "alternate-sample-rate" "44100"
    set_config_value "/etc/pulse/daemon.conf" "resample-method" "speex-fixed-5"

    # Enable
    systemctl --user enable pulseaudio
    systemctl --user start pulseaudio
}

# PipeWire configuration
configure_pipewire() {
    log_info "Configuring PipeWire"

    # Install
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa
            ;;
        debian|ubuntu)
            apt-get install -y pipewire pipewire-pulse pipewire-alsa
            ;;
    esac

    # Enable
    systemctl --user enable pipewire pipewire-pulse
    systemctl --user start pipewire pipewire-pulse
}
```

## Input Device Configuration

### Keyboard Layout

```bash
# Configure keyboard layouts
configure_keyboard() {
    log_section "Configuring keyboard layouts"

    # Copy keyboard layout files
    copy_config_file "${REPO_DIR}/keyboard-layouts/ro" \
        "/etc/X11/xorg.conf.d/00-keyboard.conf"

    # Apply for Argon ONE UP
    if [ "${DEVICE_MODEL}" = "Argon ONE UP" ]; then
        copy_config_file "${REPO_DIR}/keyboard-layouts/ro-argononeup" \
            "/etc/X11/xorg.conf.d/00-keyboard.conf"
    fi
}
```

### Input Device Tuning

```bash
# Configure input devices
configure_input_devices() {
    log_section "Configuring input devices"

    # Libinput configuration
    set_config_value "/etc/X11/xorg.conf.d/40-libinput.conf" \
        "Option \"Tapping\" \"on\""
    set_config_value "/etc/X11/xorg.conf.d/40-libinput.conf" \
        "Option \"NaturalScrolling\" \"true\""
    set_config_value "/etc/X11/xorg.conf.d/40-libinput.conf" \
        "Option \"DisableWhileTyping\" \"true\""
}
```

## Thermal Management

### Thermal Configuration

```bash
# Configure thermal management
configure_thermal() {
    log_section "Configuring thermal management"

    # Install thermald
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm thermald
            ;;
        debian|ubuntu)
            apt-get install -y thermald
            ;;
    esac

    # Enable thermald
    systemctl enable thermald
    systemctl start thermald

    # Configure CPU frequency scaling
    case "${DISTRO_FAMILY}" in
        arch)
            pacman -S --noconfirm cpupower
            ;;
        debian|ubuntu)
            apt-get install -y linux-tools-common linux-tools-generic
            ;;
    esac

    # Set governor
    if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
        cpupower frequency-set -g powersave
    else
        cpupower frequency-set -g performance
    fi
}
```

## Integration with Setup Scripts

### Main Hardware Integration

```bash
# scripts/configure-hardware-integration.sh

configure_hardware_integration() {
    log_section "Configuring hardware integration"

    # Detect hardware
    detect_hardware

    # Configure GPU
    configure_gpu

    # Configure power management
    configure_power_management

    # Configure audio
    configure_audio

    # Configure input devices
    configure_input_devices

    # Configure thermal management
    configure_thermal

    # Device-specific configuration
    configure_argon_one_up_fan
    configure_argon_one_up_power
    configure_argon_one_up_ir

    log_success "Hardware integration configured"
}
```

## Hardware Profiles

### Profile Definition

```bash
# Hardware profiles for common device types
declare -A HARDWARE_PROFILES=(
    ["desktop"]="gpu:nvidia|amd|intel power:performance thermal:performance"
    ["laptop"]="gpu:intel|amd power:powersave thermal:powersave battery:true"
    ["handheld"]="gpu:broadcom power:balanced thermal:balanced battery:true"
    ["server"]="gpu:none power:performance thermal:performance"
    ["development"]="gpu:nvidia|amd power:performance thermal:performance"
    ["gaming"]="gpu:nvidia|amd power:performance thermal:performance"
)
```

## Best Practices

1. **Detect before configure** — Always detect hardware before applying settings
2. **Graceful degradation** — Skip configuration if hardware not present
3. **Idempotent operations** — Re-running should not cause issues
4. **User override** — Allow user to skip hardware-specific config
5. **Log hardware state** — Record detected hardware for debugging

## Future Enhancements

1. **Hardware database** — Centralized hardware compatibility database
2. **Auto-tuning** — Adaptive configuration based on usage patterns
3. **Firmware updates** — Automated firmware update management
4. **Hardware monitoring** — Real-time hardware health monitoring
5. **Profile switching** — Dynamic profile switching based on context