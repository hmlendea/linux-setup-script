# Host and Composition Component

This document provides a deep dive into the host and composition component,
which handles system composition, boot configuration, and hardware integration.

## Overview

**Location**: `scripts/configure-hardware-integration.sh`, `scripts/update-grub.sh`,
`scripts/configure-system.sh`

**Purpose**: Hardware detection, boot configuration, kernel parameters,
and system composition management.

**Consumers**: `run.sh` (Phase 3), `configure-hardware-integration.sh`,
`update-grub.sh`, `configure-system.sh`

## Core Functions

### 1. Hardware Integration

```bash
# Configure hardware-specific settings
configure_hardware_integration

# Detect and configure GPU
configure_gpu

# Detect and configure audio
configure_audio

# Detect and configure input devices
configure_input_devices

# Detect and configure power management
configure_power_management

# Detect and configure thermal management
configure_thermal_management
```

### 2. Boot Configuration

```bash
# Update GRUB configuration
update_grub

# Set kernel parameters
set_kernel_parameters <parameters>

# Configure boot timeout
set_boot_timeout <seconds>

# Configure default boot entry
set_default_boot_entry <entry>

# Add boot entry
add_boot_entry <name> <kernel> <initrd> <parameters>
```

### 3. Kernel Module Configuration

```bash
# Load kernel module
load_kernel_module <module>

# Unload kernel module
unload_kernel_module <module>

# Configure module parameters
configure_module_parameters <module> <parameters>

# Blacklist module
blacklist_module <module>

# Whitelist module
whitelist_module <module>
```

### 4. Firmware Configuration

```bash
# Update firmware
update_firmware

# Configure firmware settings
configure_firmware

# Apply firmware updates
apply_firmware_updates
```

## Hardware Integration Patterns

### Pattern 1: GPU Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Intel GPU
if [ "${GPU_FAMILY}" = "intel" ]; then
    set_modprobe_option "i915" "enable_fbc" "1"
    set_modprobe_option "i915" "enable_guc" "3"
    set_modprobe_option "i915" "enable_psr" "2"
    set_modprobe_option "i915" "enable_dc" "2"
fi

# AMD GPU
if [ "${GPU_FAMILY}" = "amd" ]; then
    set_modprobe_option "amdgpu" "ppfeaturemask" "0xffffffff"
    set_modprobe_option "amdgpu" "si_support" "1"
    set_modprobe_option "amdgpu" "cik_support" "1"
fi

# NVIDIA GPU
if [ "${GPU_FAMILY}" = "nvidia" ]; then
    set_modprobe_option "nvidia" "NVreg_UsePageAttributeTable" "1"
    set_modprobe_option "nvidia" "NVreg_EnableMSI" "1"
fi
```

### Pattern 2: Audio Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"

# PulseAudio/PipeWire configuration
set_pulseaudio_module_option "module-udev-detect" "tsched" "0"
set_pulseaudio_module_option "module-udev-detect" "ignore_dB" "1"

# ALSA configuration
update_file_if_distinct "${REPO_RC_DIR}/alsa/asound.conf" "/etc/asound.conf"
```

### Pattern 3: Power Management

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# CPU frequency scaling
set_config_value "/etc/default/cpufrequtils" "GOVERNOR" "powersave"

# TLP configuration
if is_package_installed "tlp"; then
    set_config_value "/etc/tlp.conf" "CPU_SCALING_GOVERNOR_ON_AC" "performance"
    set_config_value "/etc/tlp.conf" "CPU_SCALING_GOVERNOR_ON_BAT" "powersave"
    set_config_value "/etc/tlp.conf" "CPU_BOOST_ON_AC" "1"
    set_config_value "/etc/tlp.conf" "CPU_BOOST_ON_BAT" "0"
fi

# Battery device optimisations
if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
    set_config_value "/etc/tlp.conf" "START_CHARGE_THRESH_BAT0" "75"
    set_config_value "/etc/tlp.conf" "STOP_CHARGE_THRESH_BAT0" "80"
fi
```

### Pattern 4: GRUB Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"
source "scripts/common/config.sh"

# Base kernel parameters
local kernel_params="mitigations=off random.trust_cpu=on fsck.repair=yes"

# Intel-specific
if [ "${GPU_FAMILY}" = "intel" ]; then
    kernel_params="${kernel_params} i915.enable_guc=3 i915.enable_fbc=1 i915.enable_psr=2"
fi

# AMD-specific
if [ "${GPU_FAMILY}" = "amd" ]; then
    kernel_params="${kernel_params} amdgpu.ppfeaturemask=0xffffffff"
fi

# Battery device
if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
    kernel_params="${kernel_params} intel_idle.max_cstate=1"
fi

# Resume from swap
if [ -f /swapfile ]; then
    kernel_params="${kernel_params} resume=/swapfile"
fi

# Apply to GRUB
set_config_value "/etc/default/grub" "GRUB_CMDLINE_LINUX_DEFAULT" "${kernel_params} quiet loglevel=3"
set_config_value "/etc/default/grub" "GRUB_TIMEOUT" "5"
set_config_value "/etc/default/grub" "GRUB_DEFAULT" "saved"
set_config_value "/etc/default/grub" "GRUB_SAVEDEFAULT" "true"

# Update GRUB
update_grub
```

## Host and Composition Invariants

1. **Hardware detection first** — All hardware config based on `system-info.sh` exports
2. **Idempotent operations** — Module parameters use `set_modprobe_option`
3. **Platform awareness** — Different configs for different GPU families
4. **Privilege separation** — Boot/kernel config via `run_as_su`
5. **No runtime templating** — Config files deployed verbatim
6. **Single source of truth** — Each setting derived in exactly one place

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `set_modprobe_option` | Module not loaded | Creates config, loads on next boot |
| `update_grub` | GRUB not installed | Error message, returns 1 |
| `load_kernel_module` | Module not found | Error message, returns 1 |
| `configure_module_parameters` | Invalid parameters | Error message, returns 1 |

## Performance Considerations

- **Lazy module loading** — Modules loaded on demand
- **Batch GRUB updates** — Single `update-grub` call per session
- **Minimal reboots** — Config changes take effect on next boot
- **Conditional config** — Only apply configs for detected hardware

## Security Considerations

- **Kernel parameter validation** — Parameters validated before setting
- **Module signature verification** — Only signed modules loaded
- **Privilege separation** — Boot config via `run_as_su`
- **No arbitrary code** — Hardware config is declarative

## Testing

### Unit Tests

```bash
function test_set_modprobe_option() {
    local temp_dir=$(mktemp -d)
    export ROOT_ETC="${temp_dir}"

    set_modprobe_option "test_module" "param1" "value1"
    assertTrue "modprobe.d file created" "[ -f ${temp_dir}/modprobe.d/test_module.conf ]"
    assertEquals "options test_module param1=value1" "$(cat ${temp_dir}/modprobe.d/test_module.conf)"

    rm -rf "${temp_dir}"
}

function test_update_grub() {
    # Test GRUB update
    update_grub
    assertTrue "GRUB updated" "[ -f /boot/grub/grub.cfg ]"
}
```

### Integration Tests

```bash
function test_hardware_detection() {
    detect_gpu_family
    assertNotNull "GPU_FAMILY is set" "${GPU_FAMILY}"

    detect_is_battery_device
    assertTrue "IS_BATTERY_DEVICE is boolean" "[ '${IS_BATTERY_DEVICE}' = 'true' ] || [ '${IS_BATTERY_DEVICE}' = 'false' ]"
}
```

## Future Enhancements

1. **Dynamic hardware detection** — Hotplug hardware detection
2. **Firmware update automation** — Automatic firmware updates
3. **Boot entry management** — Add/remove boot entries programmatically
4. **Kernel parameter validation** — Validate kernel parameters against schema
5. **Hardware profiles** — Predefined hardware profiles for common devices
6. **Thermal management** — Advanced thermal management policies