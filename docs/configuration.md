# Configuration

This document describes the configuration schema, sources, precedence, and
derivation logic for all configurable aspects of the provisioning framework.

## Configuration Sources and Precedence

```
Highest Priority (Runtime)
├── Environment variables (USER, HOME, DISPLAY, WAYLAND_DISPLAY, XDG_*)
├── Command-line arguments (none currently)
├── Hardware detection (system-info.sh at source time)
│       ├── DEVICE_MODEL, CHASSIS_TYPE, GPU_FAMILY
│       ├── Screen resolution, DPI, battery status
│       └── Distro family, OS, architecture
├── Distro-specific defaults (DISTRO_FAMILY branches)
├── Device-type heuristics (POWERFUL_PC, IS_DEVELOPMENT_DEVICE, etc.)
├── Theme detection (get_theme(), get_theme_mode())
└── Hardcoded defaults (Lowest Priority)
```

**Key principle**: Configuration is **derived**, not declared. There is no
central configuration file. All settings are computed from detected environment
and hardcoded preferences.

## Configuration Categories

### 1. Theme Configuration (`configure-system.sh`)

**Source of truth**: `get_theme()` and `get_theme_mode()` from `system-info.sh`

| Variable | Derivation | Values |
|----------|------------|--------|
| `GTK_THEME_VARIANT` | `get_theme_mode()` | 'dark' or 'light' |
| `GTK_THEME` | `get_theme()` + variant suffix | 'adw-gtk3', 'ZorinGrey', etc. |
| `GTK2_THEME` | `GTK_THEME` with name normalisation | 'AdwaitaDark' for 'adw-gtk3-dark' |
| `GTK3_THEME` | `GTK_THEME` | Same as base |
| `GTK4_THEME` | `GTK_THEME` with fallback | 'Adwaita-dark' if ZorinGrey (no GTK4 support) |
| `ICON_THEME` | Hardcoded | 'Papirus-Dark' |
| `ICON_THEME_DIRECTORY_COLOUR` | Hardcoded | 'grey' |
| `CURSOR_THEME` | Hardcoded | 'Vimix-white-cursors' |
| `SOUND_THEME` | Hardcoded + package check | 'freedesktop' or 'Pop' (if pop-sound-theme-bin) |
| `DESKTOP_THEME_IS_DARK` | `GTK_THEME_VARIANT == 'dark'` | Boolean |
| `DESKTOP_THEME_IS_DARK_BINARY` | Boolean → 1/0 | Integer |
| `GTK_THEME_BG_COLOUR` | Theme-specific | '#202020' (ZorinGrey), '#1c1c1f' (adw-gtk3) |

**Theme name normalisation**:
```bash
GTK2_THEME=$(echo "${GTK2_THEME}" | sed \
    -e 's/adw-gtk3/AdwaitaDark/g' \
    -e 's/Dark-dark/Dark/g')
```

**Applied via**:
- GNOME: `gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME}"`
- GTK2/3/4 config files: `~/.config/gtk-*/settings.ini`

### 2. Font Configuration (`configure-system.sh`)

**Base fonts**: Interface, Document, Titlebar, Menu, MenuHeader, Monospace, Subtitles, Text Editor, Browser, Emoji

**Resolution-dependent sizing**:

| Screen Height | Interface | Titlebar | Monospace | Subtitles | Terminal Cols/Rows |
|---------------|-----------|----------|-----------|-----------|-------------------|
| ≤ 800 | 11 | 11 | 12 | 17 | 80×24 |
| ≤ 1080 | 11 | 11 | 12 | 17 | 110×32 |
| ≤ 1440 | 11 | 12 | 13 | 20 | 128×32 |
| ≤ 2160 | 11 | 12 | 13 | 20 | 150×45 |
| > 2160 | 12 | 12 | 13 | 20 | 150×45 |

**DPI-dependent interface font size**:
| DPI | Interface Font Size |
|-----|---------------------|
| < 100 | 11 |
| 100–129 | 10 |
| 130–144 | 11 |
| ≥ 145 | 12 |

**Font face defaults**:
- Interface/Document/Titlebar/Menu/MenuHeader/Subtitles: 'Sans'
- Monospace/Text Editor: 'Droid Sans' (Debian: 'Liberation')
- Emoji: 'Apple Color Emoji'

**Computed font strings** (e.g., `INTERFACE_FONT="Sans Regular 11"`)

**Applied via**:
- GNOME: `gsettings set org.gnome.desktop.interface font-name "${INTERFACE_FONT}"`
- Fontconfig: `~/.config/fontconfig/fonts.conf` (if present)

### 3. Terminal Configuration (`configure-system.sh`)

| Variable | Value | Notes |
|----------|-------|-------|
| `TERMINAL_SIZE_COLS` | Resolution-dependent | See table above |
| `TERMINAL_SIZE_ROWS` | Resolution-dependent | See table above |
| `TERMINAL_SCROLLBACK_SIZE` | 15000 | |
| `TERMINAL_BOLD_TEXT_IS_BRIGHT` | false | |
| `TERMINAL_CURSOR_SHAPE` | 'ibeam' | |
| `TERMINAL_BG` | `GTK_THEME_BG_COLOUR` (dark) / default | |
| `TERMINAL_FG` | `FONT_COLOUR` (#FFFFFF) | |
| `TERMINAL_BLACK_D/L` | '#241F31' / '#5E5C64' | Dark/Light variants |
| `TERMINAL_RED_D/L` | '#C01C28' / '#ED333B' | |
| `TERMINAL_GREEN_D/L` | '#2EC27E' / '#57E389' | |
| `TERMINAL_YELLOW_D/L` | '#F5C211' / '#F8E45C' | |
| `TERMINAL_BLUE_D/L` | '#1E78E4' / '#51A1FF' | |
| `TERMINAL_PURPLE_D/L` | '#9841BB' / '#C061CB' | |
| `TERMINAL_CYAN_D/L` | '#0AB9DC' / '#4FD2FD' | |
| `TERMINAL_WHITE_D/L` | '#C0BFBC' / '#F6F5F4' | |

**Applied via**: Terminal emulator config (GNOME Terminal, Alacritty, etc.) via
`update-resources.sh` or direct gsettings.

### 4. Text Editor Configuration

| Variable | Value |
|----------|-------|
| `TEXT_EDITOR_TAB_SPACES` | true |
| `TEXT_EDITOR_TAB_SIZE` | 4 |
| `TEXT_EDITOR_WORD_WRAP` | false |

### 5. Language Configuration

| Variable | Value | Purpose |
|----------|-------|---------|
| `OS_LANGUAGE` | `get_os_language()` | System language |
| `APPS_LANGUAGE` | 'ro_RO' | Application locale |
| `GAMES_LANGUAGE` | 'en_GB' | Game locale |

**Applied via**:
- `/etc/locale.conf`: `LANG=en_GB.UTF-8`, `LC_CTYPE=en_US.UTF-8`, `LC_*=ro_RO.UTF-8`
- `/etc/locale.gen`: Uncomments en_GB, en_US, ro_RO
- `~/.profile`: Exports `LANG`, `LC_ALL`, `LANGUAGE`

### 6. Power Management Constants

| Variable | Value | Purpose |
|----------|-------|---------|
| `DIRTY_WRITEBACK_POWERSAVE_SECS` | 15 | Laptop: aggregate disk I/O |
| `DIRTY_WRITEBACK_DEFAULT_SECS` | 5 | Desktop default |
| `DNS_CACHE_TTL` | 20 | Minutes |
| `DNS_CACHE_SIZE` | 10000 | Entries |

**Applied via**:
- `/etc/sysctl.d/00-system.conf`: `vm.dirty_writeback_centisecs`
- `/etc/systemd/resolved.conf`: `Cache=yes`, `CacheSize=10000`

### 7. Zoom Level

| Screen Height | ZOOM_LEVEL |
|---------------|------------|
| ≤ 2160 | 1.15 |
| ≤ 1440 | 1.10 |
| ≤ 1080 | 1.00 |
| = 0 (headless) | 1.00 |

**Applied via**: `gsettings set org.gnome.desktop.interface text-scaling-factor`

### 8. Kernel Module Parameters (`/etc/modprobe.d/`)

**Intel GPU (i915)**:
```bash
set_modprobe_option i915 enable_fbc 1      # Framebuffer compression
set_modprobe_option i915 enable_guc 3      # GuC/HuC firmware
set_modprobe_option i915 enable_psr 2      # Panel self-refresh
```

**NVIDIA GPU**:
```bash
set_modprobe_option nvidia-drm modset 1    # DRM kernel mode setting
```

**Bluetooth (Xbox One Controller)**:
```bash
set_modprobe_option bluetooth disable_ertm 1
set_modprobe_option btusb enable_autosuspend n
```

**Laptop USB Power Management**:
```bash
set_modprobe_option usbcore autosuspend 1
```

**Audio Power Management**:
```bash
# snd_hda_intel
set_modprobe_option snd_hda_intel power_save_controller Y
set_modprobe_option snd_hda_intel power_save 1

# snd_ac97_codec
set_modprobe_option snd_ac97_codec power_save 1
```

**WiFi (iwlwifi)**:
```bash
set_modprobe_option iwlwifi power_save 1
set_modprobe_option iwlwifi uapsd_disable 0
# iwldvm
set_modprobe_option iwldvm force_cam 0
# iwlmvm
set_modprobe_option iwlmvm power_scheme 3
```

**Disabled Modules (Blacklist)**:
```bash
set_modprobe_option blacklist pcmcia
set_modprobe_option blacklist yenta_socket
set_modprobe_option blacklist uhci_hcd    # USB 1.1
```

### 9. Sysctl Configuration (`/etc/sysctl.d/00-system.conf`)

**Network**:
```bash
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_syncookies = 1
```

**IPv6 (Disabled)**:
```bash
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
net.ipv6.conf.lo.use_tempaddr = 2
```

**Kernel**:
```bash
kernel.core_pattern = |/bin/false        # Disable systemd-coredump
kernel.nmi_watchdog = 0                  # Disable NMI interrupts
```

**Memory (Laptop vs Desktop)**:
```bash
# Laptop
vm.dirty_writeback_centisecs = 1500      # 15 seconds
vm.laptop_mode = 5

# Desktop
vm.dirty_writeback_centisecs = 500       # 5 seconds
vm.laptop_mode = 0

# SD card storage
vm.swappiness = 1
```

### 10. Systemd Configuration

**Journald** (`/etc/systemd/journald.conf`):
```bash
# SD card storage only
Storage = volatile
```

**Logind** (`/etc/systemd/logind.conf`):
```bash
[Login]
KillUserProcesses = yes
```

**System** (`/etc/systemd/system.conf`):
Managed via `set_config_values --section 'Manager'`

### 11. Shell Configuration (via `update-rcs.sh`)

**XDG Base Directories** (`~/.profile`):
```bash
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_DESKTOP_DIR="${HOME}/Desktop"
export XDG_DOCUMENTS_DIR="${HOME}/Documents"
export XDG_DOWNLOAD_DIR="${HOME}/Downloads"
export XDG_MUSIC_DIR="${HOME}/Music"
export XDG_PICTURES_DIR="${HOME}/Pictures"
export XDG_PUBLICSHARE_DIR="${HOME}/Public"
export XDG_TEMPLATES_DIR="${HOME}/Templates"
export XDG_VIDEOS_DIR="${HOME}/Videos"
export PATH="${PATH}:${HOME}/.local/bin:/var/lib/flatpak/exports/bin:..."
```

**Bash Configuration** (`~/.bashrc`):
Sources in order:
1. `~/.profile`
2. `${XDG_DATA_HOME}/bash/variables`
3. `${XDG_DATA_HOME}/bash/aliases`
4. `${XDG_DATA_HOME}/bash/functions`
5. `${XDG_DATA_HOME}/bash/prompt`
6. `${XDG_DATA_HOME}/bash/options`
7. `${XDG_DATA_HOME}/bash/processes`
8. `/usr/share/blesh/ble.sh` (if present)
9. `/usr/share/doc/pkgfile/command-not-found.bash` (if present)
10. `zoxide init bash` (if present)

**Bash Profile** (`~/.bash_profile`):
```bash
if [ -n "${BASH_VERSION}" ] && [ -f "${HOME}/.bashrc" ]; then
    . "${HOME}/.bashrc"
fi
```

**Inputrc** (`~/.config/readline/inputrc`):
From `rc/inputrc`

**Git Config** (`~/.config/git/config`):
From `rc/gitconfig` — includes user, core, merge, credential, push, pull, diff, rebase, init, color, help, http, alias sections

**SSH Config** (`~/.ssh/config`):
Includes `~/.ssh/config.d/linux-setup-script.conf` with:
```bash
Host *
    AddKeysToAgent 8h
```

**Application-Specific RCs**:
| App | Source | Destination |
|-----|--------|-------------|
| GIMP | `rc/gimp/gimprc`, `sessionrc`, `toolrc` | `~/.config/GIMP/2.10/` + Flatpak |
| nano | `rc/nanorc` | `~/.nanorc` |
| vim | `rc/vimrc` | `~/.vimrc` |
| lxpanel | `rc/lxde-panel` | `~/.config/lxpanel/LXDE/panels/panel` |

### 12. Firefox Configuration (via `update-resources.sh`)

**Files Deployed**:
| Source | Destination |
|--------|-------------|
| `resources/firefox/containers.json` | Profile `/containers.json` |
| `resources/firefox/userChrome.css` | Profile `/chrome/userChrome.css` |
| `resources/firefox/icons/*.png` | Profile `/chrome/icons/` |

### 13. GRUB Configuration (`update-grub.sh`)

**GRUB Default** (`/etc/default/grub`):
```bash
GRUB_TIMEOUT=5
GRUB_THEME=/boot/grub/themes/.../theme.txt
GRUB_CMDLINE_LINUX_DEFAULT="mitigations=off random.trust_cpu=on fsck.repair=yes intel_idle.max_cstate=1 resume=/swapfile quiet loglevel=3"
```

**Custom Entries** (`/etc/grub.d/`):
- `25_windows`: Windows boot entry
- `29_android`: Android boot entry
- `29_blissos`: Bliss OS boot entry
- `29_phoenixos`: Phoenix OS boot entry
- `29_primeos`: Prime OS boot entry
- `99_power`: Power off / Reboot / Firmware

### 14. mkinitcpio Configuration

**File**: `/etc/mkinitcpio.conf`
```bash
set_config_value "${MKINITCPIO_CONFIG_FILE}" 'COMPRESSION' '"lz4"'
```

## Configuration Invariants

1. **Idempotency** — All file writes use `update_file_if_distinct` (content comparison)
2. **Platform guards** — GUI-only config wrapped in `if ${HAS_GUI}; then`
3. **Binary existence checks** — `update_file_if_binary_exists` before deploying app configs
4. **Root vs user separation** — System paths written via `run_as_su`, user paths directly
5. **Theme consistency** — Dark variant forces dark GTK theme, terminal bg, icon set
6. **Resolution awareness** — All sizing derives from detected screen dimensions
7. **Distro awareness** — Font faces, package names, paths adapt to `DISTRO_FAMILY`
8. **No runtime templating** — Templates deployed verbatim; no variable interpolation
9. **Single source of truth** — Each setting derived in exactly one place
10. **Explicit over implicit** — All configuration visible in source code