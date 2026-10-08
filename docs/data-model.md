# Data Model

This document describes the domain entities, relationships, and persistence
mechanisms in the linux-setup-script repository.

## Domain Entities

### 1. System Environment (Detected at Runtime)

| Entity | Attributes | Source | Persistence |
|--------|------------|--------|-------------|
| `OperatingSystem` | `os`, `distro`, `distro_family`, `version` | `/etc/os-release`, `uname` | In-memory (exported vars) |
| `Architecture` | `arch`, `arch_family` | `uname -m`, `lscpu` | In-memory |
| `Device` | `model`, `chassis_type`, `is_battery_device` | Device tree, dmidecode, systemd | In-memory |
| `Display` | `server` (wayland/x11/tty), `width`, `height`, `dpi` | `wayland-info`, `xrandr`, `xdpyinfo` | In-memory |
| `DesktopEnvironment` | `name` (gnome/kde/mate/lxde/phosh), `session_type` | `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION` | In-memory |
| `GPU` | `family` (intel/nvidia/amd/qualcomm), `driver` | `lspci`, `glxinfo` | In-memory |
| `Network` | `wifi_driver`, `audio_driver` | `lspci -k`, `iw dev` | In-memory |
| `Storage` | `is_sd_card` | `/sys/block/*/device/type` | In-memory |
| `Privileges` | `has_su_privileges`, `uid` | `sudo -n`, `su -c`, `id -u` | In-memory |

**Relationships**:
```
OperatingSystem 1──* Architecture
OperatingSystem 1──1 Device
Device 1──1 Display
Device 1──1 DesktopEnvironment (if GUI)
Device 1──1 GPU
Device 1──1 Network
Device 1──1 Storage
Device 1──1 Privileges
```

### 2. Package Management

| Entity | Attributes | Source | Persistence |
|--------|------------|--------|-------------|
| `NativePackage` | `name`, `manager` (pacman/apt/apk/pkg), `installed` | Package DB query | Package DB |
| `FlatpakPackage` | `app_id`, `remote` (flathub), `installed` | `flatpak list` | Flatpak DB |
| `CargoPackage` | `name`, `version`, `installed` | `cargo install --list` | Cargo registry |
| `GitHubRelease` | `repo`, `version`, `asset_url`, `installed` | GitHub API, binary check | Filesystem (`/usr/local/bin`) |
| `VSCodeExtension` | `id`, `version`, `installed` | `code --list-extensions` | VS Code DB |
| `GNOMEExtension` | `uuid`, `version`, `installed` | `gnome-extensions list` | GNOME DB |
| `AURPackage` | `name`, `version`, `installed` | AUR helper query | Package DB |

**Relationships**:
```
PackageManager 1──* NativePackage
Flatpak 1──* FlatpakPackage
Cargo 1──* CargoPackage
GitHub 1──* GitHubRelease
VSCode 1──* VSCodeExtension
GNOME 1──* GNOMEExtension
AUR 1──* AURPackage
```

### 3. Configuration State

| Entity | Attributes | Source | Persistence |
|--------|------------|--------|-------------|
| `ThemeConfig` | `gtk_theme`, `variant`, `icon_theme`, `cursor_theme`, `sound_theme` | `get_theme()`, `get_theme_mode()` | GSettings, GTK config files |
| `FontConfig` | `interface`, `document`, `titlebar`, `menu`, `monospace`, `subtitles`, `editor`, `browser`, `emoji` | Computed from resolution/DPI | GSettings, fontconfig |
| `TerminalConfig` | `cols`, `rows`, `scrollback`, `colors`, `cursor_shape` | Computed from resolution | Terminal emulator config |
| `LocaleConfig` | `lang`, `lc_ctype`, `lc_*`, `keymap`, `console_font` | Hardcoded + `get_os_language()` | `/etc/locale.conf`, `/etc/vconsole.conf`, X11 keymaps |
| `TimeConfig` | `timezone`, `rtc_sync` | Hardcoded (Europe/Bucharest) | `/etc/timezone`, hwclock |
| `KernelConfig` | `modules`, `parameters`, `mkinitcpio_compression` | Hardcoded per GPU/hardware | `/etc/modprobe.d/`, `/etc/mkinitcpio.conf` |
| `SysctlConfig` | `network`, `ipv6`, `kernel`, `memory` | Hardcoded per device type | `/etc/sysctl.d/00-system.conf` |
| `SystemdConfig` | `journald`, `logind`, `system` | Hardcoded per storage type | `/etc/systemd/*.conf` |
| `GRUBConfig` | `timeout`, `theme`, `cmdline`, `entries` | Hardcoded + OS detection | `/etc/default/grub`, `/etc/grub.d/` |
| `ShellConfig` | `xdg_dirs`, `path`, `aliases`, `functions`, `prompt` | `rc/shell/*`, `rc/gitconfig` | `~/.profile`, `~/.bashrc`, `~/.config/git/config` |
| `AppConfig` | `firefox_containers`, `firefox_chrome`, `git_hooks`, `lxpanel`, `plank`, `neofetch` | `resources/*` | App-specific config dirs |

### 4. Hardware Integration

| Entity | Attributes | Source | Persistence |
|--------|------------|--------|-------------|
| `ArgonONEUP` | `fan_thresholds`, `i2c_address`, `firmware_config` | Device detection | `/boot/firmware/config.txt`, `/usr/local/bin/argononeup-fan` |
| `GPUTuning` | `intel_params`, `nvidia_params`, `amd_params` | `GPU_FAMILY` | `/etc/modprobe.d/gpu.conf` |
| `PowerManagement` | `tlp_config`, `thermald_config`, `udev_rules` | `IS_BATTERY_DEVICE`, `CHASSIS_TYPE` | `/etc/tlp.conf`, `/etc/thermald/`, `/etc/udev/rules.d/` |
| `AudioConfig` | `pipewire`, `pulseaudio_modules` | `GPU_FAMILY`, `audio_driver` | `/etc/pipewire/`, PulseAudio config |

### 5. Resource Templates (Static)

| Entity | Attributes | Source | Persistence |
|--------|------------|--------|-------------|
| `FirefoxResource` | `containers.json`, `userChrome.css`, `icons/*` | `resources/firefox/` | Firefox profile dir |
| `GitHook` | `post-checkout`, `prepare-commit-msg` | `resources/git/hooks/` | `~/.config/git/hooks/` |
| `LXPanelResource` | `applications.png`, `applications_ro.png`, `power.png`, `logout.desktop` | `resources/lxpanel/` | `~/.config/lxpanel/`, `~/.local/share/applications/` |
| `PlankResource` | `dock.theme`, `autostart.desktop` | `resources/plank/` | `~/.local/share/plank/`, `~/.config/autostart/` |
| `NeofetchResource` | `ascii-arch`, `ascii-lineageos` | `resources/neofetch/` | `~/.config/neofetch/` |
| `PCManFMAction` | `open-in-code.desktop`, `open-in-terminal.desktop` | `resources/pcmanfm/` | `~/.local/share/file-manager/actions/` |
| `Template` | `file`, `doc`, `odt` | `resources/templates/` | `~/Templates/` |
| `UdevRule` | `wifi_powersave`, `ioschedulers`, `pci_pm`, `usb_powersave` | `resources/udev/` | `/etc/udev/rules.d/` |
| `RCFile` | `shell/*`, `gitconfig`, `gimp/*`, `nanorc`, `vimrc`, `lxde-panel` | `rc/` | `~/.config/`, `~/.local/share/`, `/etc/profile.d/` |
| `GRUBTemplate` | `25_windows`, `29_android`, `29_blissos`, `29_phoenixos`, `29_primeos`, `99_power` | `rc/grub/` | `/etc/grub.d/` |
| `KeyboardLayout` | `ro`, `ro-argononeup` | `rc/keyboard-layouts/` | `/usr/share/X11/xkb/symbols/` |
| `NetworkManagerConfig` | `mac-randomisation.conf` | `rc/network-manager/` | `/etc/NetworkManager/conf.d/` |
| `HiddenFile` | `home`, `home-ro`, `home-documents`, `home-downloads` | `rc/hidden-files/` | `~/.hidden`, `~/Documents/.hidden`, `~/Downloads/.hidden` |
| `ProfileScript` | `cmake.sh`, `dotnet.sh` | `profiles/` | `/etc/profile.d/` |
| `BootFirmwareConfig` | `config.txt` | `rc/boot_firmware_config_argononeup.txt` | `/boot/firmware/config.txt` |

## Data Flow

```
┌─────────────────┐
│  Hardware/Env   │
│  Detection      │
│  (system-info)  │
└────────┬────────┘
         │ Exported vars
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Configuration  │────►│  Target System  │
│  Derivation     │     │  (Files, DBs,   │
│  (scripts)      │     │   Services)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Resource/RC    │     │  Runtime State  │
│  Templates      │     │  (Services,     │
│  (Static)       │     │   Processes)    │
└─────────────────┘     └─────────────────┘
```

## Persistence Mechanisms

| Mechanism | Scope | Format | Management |
|-----------|-------|--------|------------|
| Filesystem | User config | INI, JSON, CSS, shell | `update_file_if_distinct` |
| Filesystem | System config | INI, conf, rules | `run_as_su` + `update_file_if_distinct` |
| GSettings | Desktop settings | Key-value | `gsettings set` |
| systemd | Services | Unit files | `systemctl enable/disable/mask` |
| Package DB | Packages | SQLite (pacman), dpkg (apt) | Package manager |
| Flatpak DB | Flatpaks | OSTree | `flatpak` |
| Cargo registry | Crates | Git index | `cargo` |
| GRUB | Boot entries | Config + scripts | `grub-mkconfig` |
| Initramfs | Kernel modules | CPIO archive | `mkinitcpio`/`update-initramfs` |

## State Transitions

### Provisioning Flow

```
Initial State (Fresh Install)
         │
         ▼
┌────────────────────────┐
│ Phase 1: Packages      │
│ - Repos configured     │
│ - Packages installed   │
│ - Caches cleaned       │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Phase 2: Config Deploy │
│ - RC files deployed    │
│ - Resources deployed   │
│ - Profiles deployed    │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Phase 3: System Config │
│ - Kernel params set    │
│ - Sysctl applied       │
│ - Systemd configured   │
│ - GRUB regenerated     │
│ - Services enabled     │
│ - Hardware integrated  │
└───────────┬────────────┘
            │
            ▼
Target State (Fully Configured)
```

### Idempotency Guarantees

| Operation | Idempotency Mechanism |
|-----------|----------------------|
| File deploy | `update_file_if_distinct` (content compare) |
| Package install | `is_package_installed` check before install |
| Service enable | `is_service_enabled` check before enable |
| Config value set | `get_config_value` compare before set |
| Symlink create | `create_symlink` (overwrites) |
| Directory create | `create_directory` (`mkdir -p`) |

## Data Invariants

1. **Single source of truth** — Each configuration value derived in exactly one place
2. **No runtime templating** — Templates deployed verbatim; no variable interpolation
3. **Platform-specific variants** — Separate files for variants (e.g., `home` vs `home-ro`)
4. **Binary guards** — App configs only deployed if binary exists
5. **Root/user separation** — System paths via `run_as_su`, user paths directly
6. **Content-addressed deployment** — Files only written if content differs
7. **Detection at source time** — Hardware/env detected once, exported as globals