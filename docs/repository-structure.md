# Repository Structure

This document describes the source tree layout, module organisation, and naming
conventions of the linux-setup-script repository.

## Source Tree Layout

```
linux-setup-script/
├── run.sh                          # Primary entry point (orchestrator)
├── data/                           # Static data files (reference only)
│   ├── steam-names.txt             # Steam AppID → Game name mapping
│   └── steam-wmclasses.txt         # Steam AppID → WM_CLASS mapping
├── docs/                           # Technical documentation (this directory)
├── profiles/                       # /etc/profile.d scripts
│   ├── cmake.sh                    # MAKEFLAGS for parallel builds
│   └── dotnet.sh                   # DOTNET_ROOT, MSBuildSDKsPath, PATH
├── rc/                             # Configuration templates (deployed to target)
│   ├── boot_firmware_config_argononeup.txt  # Argon ONE UP firmware config
│   ├── firefox-policies.json       # Firefox enterprise policies
│   ├── gitconfig                   # Git configuration
│   ├── inputrc                     # Readline configuration
│   ├── lxde-dock                   # LXPanel dock panel config
│   ├── lxde-panel                  # LXPanel main panel config
│   ├── nanorc                      # nano editor configuration
│   ├── profile                     # Shell profile (XDG, PATH, env vars)
│   ├── vimrc                       # vim editor configuration
│   ├── gimp/                       # GIMP configuration
│   │   ├── gimprc
│   │   ├── sessionrc
│   │   └── toolrc
│   ├── grub/                       # GRUB multi-boot entry templates
│   │   ├── 25_windows              # Windows boot entry
│   │   ├── 29_android              # Android boot entry
│   │   ├── 29_blissos              # Bliss OS boot entry
│   │   ├── 29_phoenixos            # Phoenix OS boot entry
│   │   ├── 29_primeos              # Prime OS boot entry
│   │   └── 99_power                # Power off / Reboot / Firmware
│   ├── hidden-files/               # .hidden files for directory hiding
│   │   ├── home                    # English locale
│   │   ├── home-ro                 # Romanian locale
│   │   ├── home-documents
│   │   └── home-downloads
│   ├── keyboard-layouts/           # X11 keyboard layouts
│   │   ├── ro                      # Standard Romanian
│   │   └── ro-argononeup           # Argon ONE UP variant
│   ├── network-manager/            # NetworkManager configuration
│   │   └── mac-randomisation.conf  # Disable MAC randomisation
│   └── shell/                      # Bash shell configuration
│       ├── aliases
│       ├── bash_profile
│       ├── bashrc
│       ├── functions
│       ├── opts
│       ├── processes
│       └── prompt
├── resources/                      # Resource templates (deployed to target)
│   ├── fetch/                      # Fastfetch/neofetch logos (subdirectories)
│   │   ├── fastfetch/logos/
│   │   └── neofetch/logos/
│   ├── firefox/                    # Firefox profile resources
│   │   ├── containers.json         # Container tabs config
│   │   ├── userChrome.css          # Custom UI styling
│   │   └── icons/                  # Custom icons for containers/UI
│   ├── git/                        # Git hooks
│   │   └── hooks/
│   │       ├── post-checkout
│   │       └── prepare-commit-msg
│   ├── lxpanel/                    # LXPanel resources
│   │   ├── applications.png
│   │   ├── applications_ro.png
│   │   ├── power.png
│   │   └── lxde-logout-gnomified.desktop
│   ├── neofetch/                   # neofetch ASCII logos
│   │   ├── ascii-arch
│   │   └── ascii-lineageos
│   ├── pcmanfm/                    # PCManFM file manager actions
│   │   ├── open-in-code.desktop
│   │   └── open-in-terminal.desktop
│   ├── plank/                      # Plank dock resources
│   │   ├── autostart.desktop
│   │   └── dock.theme
│   ├── templates/                  # XDG user templates
│   │   ├── doc                     # Microsoft Word template
│   │   ├── file                    # Blank file template
│   │   └── odt                     # LibreOffice Writer template
│   └── udev/                       # udev rules (system-level)
│       ├── ioschedulers.rules      # I/O scheduler selection
│       ├── pci_pm.rules            # PCI power management
│       ├── usb_powersave.rules     # USB autosuspend
│       └── wifi_powersave.rules    # WiFi power saving
├── scripts/                        # Executable scripts
│   ├── assign-users-and-groups.sh  # User/group assignment (unused?)
│   ├── clean-files.sh              # File cleanup (unused?)
│   ├── clean-packages.sh           # Package cache cleanup
│   ├── configure-autostart-apps.sh # User autostart .desktop entries
│   ├── configure-default-apps.sh   # Default applications (mimeapps.list)
│   ├── configure-directories.sh    # XDG dirs, hidden files, symlinks
│   ├── configure-hardware-integration.sh  # Device-specific hardware setup
│   ├── configure-launchers.sh      # .desktop file modifications
│   ├── configure-locale.sh         # Locale, console font, keymap, X11 layouts
│   ├── configure-permissions.sh    # Flatpak/GNOME app permissions
│   ├── configure-repositories.sh   # Package repository configuration
│   ├── configure-services-system.sh # System service enable/disable
│   ├── configure-services-user.sh  # User service mask/disable
│   ├── configure-system.sh         # Comprehensive system configuration
│   ├── configure-time.sh           # Timezone and RTC sync
│   ├── install-packages.sh         # Curated package installation
│   ├── uninstall-packages.sh       # Package removal and DE deduplication
│   ├── update-grub.sh              # GRUB config regeneration
│   ├── update-packages.sh          # System/Flatpak/Cargo/GNOME extension updates
│   ├── update-profiles.sh          # /etc/profile.d deployment
│   ├── update-rcs.sh               # User/root RC file deployment
│   ├── update-repositories.sh      # Package database refresh
│   ├── update-resources.sh         # Resource template deployment
│   ├── common/                     # Foundation modules (sourced, not executed)
│   │   ├── apps.sh                 # Firefox profile detection
│   │   ├── common.sh               # Privilege escalation, script execution
│   │   ├── config.sh               # Config file manipulation (INI, JSON, XML, GSettings, modprobe)
│   │   ├── filesystem.sh           # Path resolution, constants, file utilities
│   │   ├── github.sh               # GitHub API helpers
│   │   ├── package-management.sh   # Unified package manager abstraction
│   │   ├── permissions.sh          # Flatpak/GNOME/Android permission management
│   │   ├── service-management.sh   # systemd/OpenRC service control
│   │   └── system-info.sh          # Hardware/environment detection
│   └── git/                        # Git setup scripts
│       ├── setup-gpg-key.sh        # GPG key configuration for Git signing
│       └── setup-ssh-key.sh        # SSH key generation for GitHub
```

## Module Organisation

### Foundation Modules (`scripts/common/`)

These are **sourced** by other scripts, never executed directly. They provide
shared utilities and have a strict dependency hierarchy:

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
permissions.sh → config.sh, package-management.sh
    ↑
github.sh (no deps)
```

**Sourcing convention**: Every script begins with path resolution, then sources
required modules in dependency order:

```bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

source "${SCRIPT_DIR}/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"  # Most scripts
# ... additional modules as needed
```

### Phase Scripts (`scripts/`)

These are **executed** by `run.sh` in strict sequence. They are organised by
provisioning phase:

| Phase | Scripts | Execution Context |
|-------|---------|-------------------|
| 1: Repos & Packages | configure-repositories, update-repositories, uninstall-packages, update-packages, install-packages, clean-packages | Root (repos) / User (packages) |
| 2: Config Deployment | update-rcs, update-profiles, update-resources | User + Root |
| 3: System Config | configure-system, configure-launchers, configure-autostart-apps, configure-default-apps, configure-permissions, configure-directories, configure-locale, configure-time, configure-services-user, configure-services-system, configure-hardware-integration, update-grub | User + Root |
| 4: Git Setup | setup-gpg-key, setup-ssh-key | User |

### Resource Templates (`resources/`, `rc/`, `profiles/`, `data/`)

These are **deployed** (copied) to target locations, not sourced or executed.

| Directory | Deployment Script | Target Locations |
|-----------|-------------------|------------------|
| `rc/shell/` | `update-rcs.sh` | `~/.local/share/bash/`, `~/.bashrc`, `~/.bash_profile`, `~/.config/readline/` |
| `rc/gitconfig` | `update-rcs.sh` | `~/.config/git/config` |
| `rc/gimp/`, `rc/nanorc`, `rc/vimrc` | `update-rcs.sh` | `~/.config/GIMP/`, `~/.nanorc`, `~/.vimrc` |
| `rc/grub/` | `update-grub.sh` | `/etc/grub.d/` |
| `rc/keyboard-layouts/` | `configure-locale.sh` | `/usr/share/X11/xkb/symbols/` |
| `rc/network-manager/` | `update-resources.sh` (root) | `/etc/NetworkManager/conf.d/` |
| `rc/hidden-files/` | `configure-directories.sh` | `~/.hidden`, `~/Documents/.hidden`, `~/Downloads/.hidden` |
| `profiles/` | `update-profiles.sh` (root) | `/etc/profile.d/` |
| `resources/firefox/` | `update-resources.sh` | Firefox profile directory |
| `resources/git/hooks/` | `update-resources.sh` | `~/.config/git/hooks/` |
| `resources/lxpanel/` | `update-resources.sh` | `~/.config/lxpanel/`, `~/.local/share/applications/` |
| `resources/plank/` | `update-resources.sh` | `~/.local/share/plank/`, `~/.config/autostart/` |
| `resources/neofetch/` | `update-resources.sh` | `~/.config/neofetch/` |
| `resources/pcmanfm/` | `update-resources.sh` | `~/.local/share/file-manager/actions/` |
| `resources/templates/` | `update-resources.sh` | `~/Templates/` |
| `resources/udev/` | `update-resources.sh` (root) | `/etc/udev/rules.d/` |
| `data/` | Not deployed | Reference only |

## Naming Conventions

### Scripts
- **Phase scripts**: `kebab-case.sh` (e.g., `configure-system.sh`, `install-packages.sh`)
- **Foundation modules**: `kebab-case.sh` (e.g., `package-management.sh`, `system-info.sh`)
- **Git scripts**: `kebab-case.sh` in `scripts/git/` (e.g., `setup-gpg-key.sh`)

### Functions (within scripts)
- **snake_case** (e.g., `run_script_as_su`, `install_native_package`, `get_screen_width`)
- **Prefix by module**: `set_flatpak_permission`, `call_package_manager`, `set_modprobe_option`

### Variables
- **Exported constants**: `UPPER_SNAKE_CASE` (e.g., `REPO_DIR`, `DISTRO_FAMILY`, `GTK_THEME`)
- **Local variables**: `snake_case` (e.g., `script_dir`, `package_list`)
- **Boolean flags**: `IS_*`, `HAS_*`, `USING_*` (e.g., `IS_ANDROID`, `HAS_GUI`, `USING_NVIDIA_GPU`)

### Files and Directories
- **Directories**: `kebab-case` (e.g., `scripts/common/`, `resources/firefox/`)
- **Config templates**: Descriptive names (e.g., `gitconfig`, `nanorc`, `vimrc`)
- **GRUB templates**: Numeric prefix for ordering (e.g., `25_windows`, `29_android`, `99_power`)
- **udev rules**: Numeric prefix for priority (e.g., `873-wifi_powersave.rules`)
- **Data files**: `kebab-case.txt` (e.g., `steam-names.txt`)

### Deployment Targets
- **User config**: `~/.config/`, `~/.local/share/`, `~/Templates/`
- **System config**: `/etc/`, `/usr/share/`, `/boot/`, `/etc/grub.d/`
- **XDG compliance**: All user config follows XDG Base Directory Specification

## File Size and Complexity

| Category | File Count | Typical Size | Complexity |
|----------|------------|--------------|------------|
| Foundation modules | 9 | 200-800 lines | High (shared utilities) |
| Phase scripts | 18 | 100-500 lines | Medium (orchestration) |
| Git scripts | 2 | 50-100 lines | Low (focused) |
| Resource templates | 30+ | 10-200 lines | Low (declarative) |
| RC templates | 20+ | 10-300 lines | Low (declarative) |
| Data files | 2 | 1000+ lines | Reference only |

## Unused/Orphaned Files

The following files exist but are not referenced in `run.sh` or any phase script:

- `scripts/assign-users-and-groups.sh` — No invocation found
- `scripts/clean-files.sh` — No invocation found
- `rc/firefox-policies.json` — Not deployed (Firefox uses `containers.json` + `userChrome.css`)
- `rc/boot_firmware_config_argononeup.txt` — Deployed by `configure-hardware-integration.sh` (not `update-grub.sh`)
- `rc/lxde-dock` — Referenced in `update-rcs.sh` but commented out

These may be legacy, experimental, or intended for manual invocation.