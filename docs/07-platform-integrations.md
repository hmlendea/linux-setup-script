# 07 — Platform Integrations

Comprehensive documentation of all external platform integrations: package managers, display servers, desktop environments, hardware, and bootloaders.

## 7.1 Package Manager Abstraction Layer

### 7.1.1 Unified Dispatch (`scripts/common/package-management.sh`)

**Entry point**: `call_package_manager <operation> [packages...]`

| Distro Family | Native Manager | AUR Helper | Flatpak | Cargo | GitHub Releases | VS Code Ext | GNOME Ext |
|---------------|----------------|------------|---------|-------|-----------------|-------------|-----------|
| Arch | `pacman` | `paru`/`yay` | ✓ | ✓ | ✓ | ✓ | ✓ |
| Debian/Ubuntu | `apt` | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| Alpine | `apk` | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| Android/Termux | `pkg` | — | — | ✓ | ✓ | — | — |

**Operations**: `install`, `uninstall`, `update`, `query`, `search`, `clean`

### 7.1.2 Native Package Operations

```bash
# Install
call_package_manager install package1 package2

# Uninstall (with DE deduplication)
call_package_manager uninstall package1 package2

# Update all
call_package_manager update

# Query installed
call_package_manager query package
```

### 7.1.3 Specialized Installers

| Function | Source | Use Case |
|----------|--------|----------|
| `install_flatpak` | Flathub | GUI apps, sandboxed |
| `install_cargo_package` | crates.io | Rust CLI tools |
| `install_github_release` | GitHub Releases | Binaries not in repos |
| `install_vscode_extension` | VS Code Marketplace | Editor extensions |
| `install_gnome_extension` | extensions.gnome.org | GNOME Shell extensions |
| `install_aur_package` | AUR (paru/yay) | Arch-only packages |

### 7.1.4 Query Functions

| Function | Returns | Platform |
|----------|---------|----------|
| `is_package_installed` | 0/1 | Native (distro-aware) |
| `is_flatpak_installed` | 0/1 | Flatpak |
| `is_cargo_package_installed` | 0/1 | Cargo |
| `is_vscode_extension_installed` | 0/1 | VS Code |
| `is_gnome_extension_installed` | 0/1 | GNOME |

---

## 7.2 Display Server & Desktop Environment Detection

### 7.2.1 Detection Logic (`scripts/common/system-info.sh`)

```bash
# Display server
if [ -n "$WAYLAND_DISPLAY" ]; then DISPLAY_SERVER="wayland"
elif [ -n "$DISPLAY" ]; then DISPLAY_SERVER="x11"
else DISPLAY_SERVER="tty"; fi

# Desktop environment (priority order)
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ "$GDMSESSION" = "gnome" ]; then DESKTOP_ENV="gnome"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then DESKTOP_ENV="kde"
elif [ "$XDG_CURRENT_DESKTOP" = "MATE" ]; then DESKTOP_ENV="mate"
elif [ "$XDG_CURRENT_DESKTOP" = "LXDE" ]; then DESKTOP_ENV="lxde"
elif [ "$XDG_CURRENT_DESKTOP" = "phosh" ]; then DESKTOP_ENV="phosh"
else DESKTOP_ENV="unknown"; fi

# Session type
SESSION_TYPE="${XDG_SESSION_TYPE:-$DISPLAY_SERVER}"
```

### 7.2.2 Exported Environment Variables

| Variable | Values | Used By |
|----------|--------|---------|
| `DISPLAY_SERVER` | `wayland`, `x11`, `tty` | All GUI config scripts |
| `DESKTOP_ENV` | `gnome`, `kde`, `mate`, `lxde`, `phosh`, `unknown` | Theme, launcher, autostart |
| `SESSION_TYPE` | `wayland`, `x11`, `tty` | Firefox, input methods |
| `HAS_GUI` | `true`/`false` | Phase 2/3 guards |
| `IS_WAYLAND` | `true`/`false` | Input config, scaling |

---

## 7.3 Desktop Environment Integrations

### 7.3.1 GNOME (`configure-system.sh`, `configure-launchers.sh`, `configure-permissions.sh`)

| Integration | Implementation |
|-------------|----------------|
| **Themes** | `gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'` |
| **Icons** | `gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'` |
| **Fonts** | `gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'` |
| **Monospace** | `gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 11'` |
| **Scaling** | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.0` |
| **Night Light** | `gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true` |
| **Animations** | `gsettings set org.gnome.desktop.interface enable-animations true` |
| **Window Controls** | `gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'` |
| **Workspaces** | `gsettings set org.gnome.mutter dynamic-workspaces true` |
| **Hot Corners** | `gsettings set org.gnome.desktop.interface enable-hot-corners true` |

**Launcher modifications** (`configure-launchers.sh`):
- Terminal: `org.gnome.Terminal` → custom profile
- Files: `org.gnome.Nautilus` → new window behavior
- Settings: `org.gnome.ControlCenter` → hidden panels

**Permissions** (`configure-permissions.sh`):
- Flatpak: `flatpak permission-set` for camera, microphone, location
- GNOME: `gsettings` for geoclue, tracker, ibus

### 7.3.2 KDE Plasma (`configure-system.sh`, `configure-launchers.sh`)

| Integration | Implementation |
|-------------|----------------|
| **Global Theme** | `lookandfeeltool -a org.kde.breezedark.desktop` |
| **Color Scheme** | `kwriteconfig5 --file kdeglobals --group Colors --key ColorScheme BreezeDark` |
| **Window Decoration** | `kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze` |
| **Font** | `kwriteconfig5 --file kdeglobals --group General --key font "Noto Sans,10,-1,5,50,0,0,0,0,0"` |
| **Cursor** | `kwriteconfig5 --file kdeglobals --group KDE --key CursorTheme breeze_cursors` |

**Launcher modifications**: `.desktop` files in `~/.local/share/applications/` override system entries

### 7.3.3 MATE (`configure-system.sh`)

| Integration | Implementation |
|-------------|----------------|
| **Theme** | `gsettings set org.mate.interface gtk-theme 'Menta'` |
| **Icons** | `gsettings set org.mate.interface icon-theme 'mate'` |
| **Font** | `gsettings set org.mate.interface font-name 'Ubuntu 11'` |
| **Panel** | `mate-panel --reset` + custom layout |

### 7.3.4 LXDE (`configure-system.sh`, `resources/lxpanel/`)

| Integration | Implementation |
|-------------|----------------|
| **Panel Config** | `rc/lxde-panel` → `~/.config/lxpanel/LXDE/panels/panel` |
| **Dock Config** | `rc/lxde-dock` → `~/.config/lxpanel/LXDE/panels/dock` |
| **Logout Dialog** | `lxde-logout-gnomified.desktop` custom entry |
| **Openbox** | `~/.config/openbox/lxde-rc.xml` keybindings |

### 7.3.5 Phosh (Mobile) (`configure-system.sh`)

| Integration | Implementation |
|-------------|----------------|
| **Scale** | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.5` |
| **Keyboard** | `gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"` |
| **Power** | `gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'` |

---

## 7.4 Hardware Integrations

### 7.4.1 Argon ONE UP (`configure-hardware-integration.sh`, `rc/boot_firmware_config_argononeup.txt`)

**Detection**: `DEVICE_MODEL="Argon ONE UP"` from `/proc/device-tree/model`

**Fan Controller** (`/usr/local/bin/argononeup-fan`):
```bash
# Temperature thresholds (°C)
OFF=35
LOW=45
MEDIUM=55
HIGH=65
CRITICAL=75

# I2C address: 0x1a
# Registers: 0x00=fan speed, 0x01=temperature
```

**Boot Firmware** (`/boot/firmware/config.txt`):
```
dtoverlay=argononeup
dtparam=fan_temp0=35,fan_temp1=45,fan_temp2=55,fan_temp3=65
dtparam=fan_speed0=0,fan_speed1=30,fan_speed2=60,fan_speed3=100
enable_uart=1
```

**Power Button**: systemd service `argononeup-power-button.service` monitors GPIO

### 7.4.2 GPU-Specific Kernel Parameters (`configure-system.sh`)

| GPU | Module | Parameters | Purpose |
|-----|--------|------------|---------|
| Intel | `i915` | `enable_guc=3`, `enable_fbc=1`, `enable_psr=1` | GuC/HuC firmware, frame buffer compression, panel self-refresh |
| NVIDIA | `nvidia` | `NVreg_UsePageAttributeTable=1`, `NVreg_EnableGpuFirmware=1` | PAT, GSP firmware |
| AMD | `amdgpu` | `ppfeaturemask=0xffffffff`, `gpu_recovery=1` | All power features, GPU reset |

**Modprobe deployment**: `/etc/modprobe.d/gpu.conf` via `set_modprobe_option()`

### 7.4.3 Laptop Power Management (`configure-system.sh`, `resources/udev/`)

**TLP** (`/etc/tlp.conf`):
```
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_HWP_ON_AC=balance_performance
CPU_HWP_ON_BAT=power
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power
```

**thermald**: `/etc/thermald/thermal-conf.xml` for Intel thermal daemon

**udev Rules** (battery-only deployment):
- `wifi_powersave.rules`: `iw dev $INTERFACE set power_save on`
- `usb_powersave.rules`: `ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"`
- `pci_pm.rules`: `ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"`
- `ioschedulers.rules`: BFQ for rotational, none for NVMe/SSD

### 7.4.4 Audio (`configure-system.sh`)

**PipeWire** (preferred):
- `wireplumber` session manager
- `pipewire-pulse` for PulseAudio compatibility
- `pipewire-alsa` for ALSA compatibility

**PulseAudio fallback**: Module options via `set_pulseaudio_module_option()`

---

## 7.5 Bootloader Integration (GRUB)

### 7.5.1 GRUB Configuration (`update-grub.sh`, `rc/grub/`)

**Entry templates** (`/etc/grub.d/`):
| File | Priority | OS | Root Detection |
|------|----------|-----|----------------|
| `25_windows` | 25 | Windows | `ntfs` partition with `/Windows/System32` |
| `29_android` | 29 | Android | `ext4` partition with `/system/build.prop` |
| `29_blissos` | 29 | Bliss OS | `ext4` partition with `bliss` in `/system/build.prop` |
| `29_phoenixos` | 29 | Phoenix OS | `ext4` partition with `phoenix` in `/system/build.prop` |
| `29_primeos` | 29 | Prime OS | `ext4` partition with `primeos` in `/system/build.prop` |
| `99_power` | 99 | — | Power off / Reboot / Firmware |

**Deployment logic**:
```bash
for entry in 25_windows 29_android 29_blissos 29_phoenixos 29_primeos 99_power; do
    if os_root_exists_for_entry "$entry"; then
        copy_grub_template "$entry"
    fi
done
grub-mkconfig -o /boot/grub/grub.cfg
```

**Entry renaming**: Post-generation `sed` on `/boot/grub/grub.cfg` for display names

### 7.5.2 mkinitcpio (`configure-system.sh`)

**Hooks**: `base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck`
**Compression**: `zstd`
**Modules**: `i915`, `amdgpu`, `nvidia` (early KMS)

---

## 7.6 Android/Termux Specifics

### 7.6.1 Path Differences
| Standard | Android/Termux |
|----------|----------------|
| `/etc` | `$PREFIX/etc` (`/data/data/com.termux/files/usr/etc`) |
| `/usr` | `$PREFIX` |
| `/var` | `$PREFIX/var` |
| `/home` | `$HOME` (`/data/data/com.termux/files/home`) |
| `/root` | `$HOME` |
| `systemd` | Not available (proot-distro only) |

### 7.6.2 Guards in Scripts
```bash
if [ "$IS_ANDROID" = "true" ]; then
    # Skip systemd, GRUB, udev, sysctl, kernel params
    # Use pkg instead of pacman/apt
    # No GUI operations
fi
```

### 7.6.3 Termux Packages (`install-packages.sh`)
- `termux-api`, `termux-tools`, `proot-distro`
- No Flatpak, no GNOME extensions, no AUR

---

## 7.7 SteamOS / Steam Deck

### 7.7.1 Detection
```bash
if [ -f /etc/os-release ] && grep -q "SteamOS" /etc/os-release; then
    IS_STEAMOS=true
fi
```

### 7.7.2 Adaptations
- **No AUR helper** (immutable rootfs)
- **Flatpak preferred** for user apps
- **Read-only `/etc`** → configs in `~/.config`, `~/.local`
- **Steam Input** integration for controller configs
- **Gamescope** session detection

---

## 7.8 WSL (Windows Subsystem for Linux)

### 7.8.1 Detection
```bash
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi
```

### 7.8.2 Early Exit (`run.sh`)
```bash
if [ "$IS_WSL" = "true" ]; then
    log_warn "WSL detected — skipping system configuration"
    exit 0
fi
```

### 7.8.3 Limitations
- No systemd (WSL1) / limited systemd (WSL2)
- No kernel module loading
- No GRUB, no hardware integration
- No display server (unless WSLg)
- Windows interop via `/mnt/c`

---

## 7.9 Immutable Distros (Silverblue, Kinoite, SteamOS)

### 7.9.1 Strategy
- **rpm-ostree** for base layer packages
- **Flatpak** for all user applications
- **Toolbox/Distrobox** for development environments
- **No `/etc` mutation** → user-level configs only

### 7.9.2 Script Adaptations
- `configure-repositories.sh`: rpm-ostree remote management
- `install-packages.sh`: `rpm-ostree install` + Flatpak
- `update-packages.sh`: `rpm-ostree upgrade` + `flatpak update`
- System configs → user equivalents (systemd --user, GSettings)

---

## 7.10 Integration Matrix

| Feature | Arch | Debian | Alpine | Android | SteamOS | WSL | Immutable |
|---------|------|--------|--------|---------|---------|-----|-----------|
| Native pkg | ✓ | ✓ | ✓ | ✓ | ✓ (ro) | ✓ | rpm-ostree |
| AUR | ✓ | — | — | — | — | — | — |
| Flatpak | ✓ | ✓ | ✓ | — | ✓ | ✓ | ✓ |
| Cargo | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GitHub releases | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| VS Code ext | ✓ | ✓ | ✓ | — | ✓ | ✓ | ✓ |
| GNOME ext | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| systemd | ✓ | ✓ | OpenRC | — | ✓ | partial | ✓ |
| GRUB | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| Kernel params | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| udev | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| Hardware (Argon) | ✓ | ✓ | ✓ | — | — | — | — |
| GPU tuning | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |
| Laptop power | ✓ | ✓ | ✓ | — | ✓ | — | ✓ |