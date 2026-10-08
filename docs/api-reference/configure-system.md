# Configure System API Reference

This document provides API reference for system configuration operations in the linux-setup-script repository.

## System Configuration Functions

### configure_system

```bash
function configure_system() {
    # Configure kernel parameters
    configure_kernel_parameters

    # Configure sysctl
    configure_sysctl

    # Configure modprobe
    configure_modprobe

    # Configure GRUB
    configure_grub

    # Configure GNOME
    configure_gnome
}
```

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
configure_system
```

### configure_kernel_parameters

```bash
function configure_kernel_parameters() {
    local GRUB_CMDLINE_LINUX_DEFAULT=""

    # Add kernel parameters based on hardware
    if [ "${GPU_FAMILY}" = "nvidia" ]; then
        GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} nvidia-drm.modeset=1"
    fi

    if [ "${IS_BATTERY_DEVICE}" = "true" ]; then
        GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} pcie_aspm=force"
    fi

    # Auto-repair filesystem errors at boot
    GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} fsck.repair=yes"

    # Update GRUB configuration
    update_grub_config "${GRUB_CMDLINE_LINUX_DEFAULT}"
}
```

**Returns:**
- `0` on success
- Non-zero on failure

### configure_sysctl

```bash
function configure_sysctl() {
    local SYSCTL_FILE="/etc/sysctl.d/99-linux-setup-script.conf"

    create_file "${SYSCTL_FILE}"

    cat > "${SYSCTL_FILE}" << EOF
# Network
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# Memory
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF

    run_as_su sysctl --system
}
```

**Returns:**
- `0` on success
- Non-zero on failure

### configure_modprobe

```bash
function configure_modprobe() {
    local MODPROBE_DIR="/etc/modprobe.d"

    ensure_directory "${MODPROBE_DIR}"

    # Configure NVIDIA
    if [ "${GPU_FAMILY}" = "nvidia" ]; then
        create_file "${MODPROBE_DIR}/nvidia.conf"
        cat > "${MODPROBE_DIR}/nvidia.conf" << EOF
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
EOF
    fi

    # Configure audio
    create_file "${MODPROBE_DIR}/audio.conf"
    cat > "${MODPROBE_DIR}/audio.conf" << EOF
options snd_hda_intel power_save=1
EOF
}
```

**Returns:**
- `0` on success
- Non-zero on failure

### configure_grub

```bash
function configure_grub() {
    local GRUB_FILE="/etc/default/grub"

    if does_file_exist "${GRUB_FILE}"; then
        # Update GRUB configuration
        sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' "${GRUB_FILE}"
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' "${GRUB_FILE}"

        run_as_su update-grub
    fi
}
```

**Returns:**
- `0` on success
- Non-zero on failure

### configure_gnome

```bash
function configure_gnome() {
    if [ "${DESKTOP_ENVIRONMENT}" != "GNOME" ]; then
        return 0
    fi

    # Configure GNOME settings
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME}"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-${GTK_THEME_VARIANT}"
    gsettings set org.gnome.desktop.interface font-name "Cantarell 11"
    gsettings set org.gnome.desktop.interface monospace-font-name "Monospace 10"
}
```

**Returns:**
- `0` on success
- Non-zero on failure

## Error Handling

All configure system functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `run_as_su` for privileged operations
- Continue on non-critical failures

## See Also

- [components/host-and-composition.md](../components/host-and-composition.md) — Host and composition
- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [flows/system-configuration.md](../flows/system-configuration.md) — System configuration flow