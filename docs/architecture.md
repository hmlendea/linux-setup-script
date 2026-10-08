# Architecture

This document describes the high-level architecture of the linux-setup-script
repository, complementing the repository overview with deeper structural
analysis.

## Architectural Decomposition

```
┌─────────────────────────────────────────────────────────────────┐
│                        run.sh (Orchestrator)                    │
│  Phase 0: Env Setup → Phase 1: Packages → Phase 2: Config       │
│  → Phase 3: System Config → Phase 4: Git Setup (optional)       │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Foundation   │    │  Phase Scripts│    │  Resources    │
│  Layer        │    │  (scripts/)   │    │  (resources/) │
│  (common/)    │    │               │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                    ┌───────────────────┐
                    │  Target System    │
                    │  (/etc, /home,    │
                    │   /boot, etc.)    │
                    └───────────────────┘
```

## Component Relationships

### Foundation Layer (`scripts/common/`)

| Module | Responsibility | Consumers |
|--------|----------------|-----------|
| `filesystem.sh` | Path resolution, constants, file utilities | All scripts |
| `common.sh` | Privilege escalation, script execution, shell setup | All scripts |
| `system-info.sh` | Hardware/environment detection, exported variables | All scripts |
| `package-management.sh` | Unified package manager abstraction | Package scripts |
| `config.sh` | Config file manipulation (INI, JSON, XML, GSettings, modprobe) | Config scripts |
| `service-management.sh` | systemd/OpenRC service control | Service scripts |
| `apps.sh` | Firefox profile detection | Firefox config |
| `permissions.sh` | Flatpak/GNOME/Android permission management | Permission scripts |
| `github.sh` | GitHub API helpers | GitHub release installer |

### Phase Scripts (`scripts/`)

| Phase | Scripts | Privilege | Platform |
|-------|---------|-----------|----------|
| 1: Repos & Packages | configure-repositories, update-repositories, uninstall-packages, update-packages, install-packages, clean-packages | Root (repos) / User (packages) | Linux |
| 2: Config Deployment | update-rcs, update-profiles, update-resources | User + Root | Linux + Android |
| 3: System Config | configure-system, configure-launchers, configure-autostart-apps, configure-default-apps, configure-permissions, configure-directories, configure-locale, configure-time, configure-services-user, configure-services-system, configure-hardware-integration, update-grub | User + Root | Linux (GUI subset) |
| 4: Git Setup | setup-gpg-key, setup-ssh-key | User | All |

### Resource Templates (`resources/`, `rc/`, `profiles/`, `data/`)

| Category | Purpose | Deployment |
|----------|---------|------------|
| `resources/firefox/` | Firefox containers, userChrome, icons | update-resources.sh |
| `resources/git/hooks/` | Git hooks | update-resources.sh |
| `resources/lxpanel/` | LXPanel icons, logout entry | update-resources.sh |
| `resources/plank/` | Plank theme, autostart | update-resources.sh |
| `resources/neofetch/` | ASCII logos | update-resources.sh |
| `resources/pcmanfm/` | File manager actions | update-resources.sh |
| `resources/templates/` | XDG templates | update-resources.sh |
| `resources/udev/` | udev rules (power, I/O, PCI) | update-resources.sh (root) |
| `rc/shell/` | Bash config, aliases, functions, prompt | update-rcs.sh |
| `rc/gitconfig` | Git configuration | update-rcs.sh |
| `rc/gimp/`, `rc/nanorc`, `rc/vimrc` | App configs | update-rcs.sh |
| `rc/grub/` | GRUB multi-boot entries | update-grub.sh |
| `rc/keyboard-layouts/` | X11 keymaps | configure-locale.sh |
| `rc/network-manager/` | MAC randomisation | update-resources.sh |
| `rc/hidden-files/` | .hidden files for directories | configure-directories.sh |
| `profiles/` | /etc/profile.d scripts | update-profiles.sh |
| `data/` | Steam AppID mappings | Reference only |

## Dependency Direction

```
run.sh
    │
    ├──► filesystem.sh (no deps)
    ├──► common.sh ──► filesystem.sh
    ├──► system-info.sh ──► filesystem.sh, common.sh
    ├──► package-management.sh ──► filesystem.sh, common.sh, system-info.sh
    ├──► config.sh ──► filesystem.sh
    ├──► service-management.sh ──► filesystem.sh, common.sh, config.sh
    ├──► apps.sh ──► filesystem.sh
    ├──► permissions.sh ──► config.sh, package-management.sh
    └──► github.sh (no deps)

Phase scripts ──► Foundation modules (as needed)
Phase scripts ──► Resources/RCs (deployed, not sourced)
```

**Key invariant**: Foundation modules have no circular dependencies. Phase scripts depend on foundation modules but not on each other.

## Runtime Topology

### Execution Contexts

| Context | Scripts | Environment |
|---------|---------|-------------|
| User (interactive) | run.sh, package scripts, update-rcs, update-resources (user), configure-system (user), configure-launchers, configure-autostart-apps, configure-default-apps, configure-permissions, configure-directories, configure-services-user, git setup | $HOME, $XDG_CONFIG_HOME, $XDG_DATA_HOME |
| Root (sudo/su) | configure-repositories, update-rcs (root), update-resources (root), configure-system (root), configure-locale, configure-time, update-profiles, configure-services-system, configure-hardware-integration, update-grub, clean-packages (Arch) | /etc, /usr, /boot, /var |

### Privilege Boundaries

```
User Context                          Root Context
─────────────────                     ─────────────────
~/.bashrc, ~/.profile                 /etc/profile.d/
~/.config/                            /etc/udev/rules.d/
~/.local/share/                       /etc/modprobe.d/
~/.ssh/                               /etc/sysctl.d/
~/.gnupg/                             /etc/systemd/
Flatpak user installs                 Flatpak system installs
systemd --user services               systemd system services
cargo install                         pacman/apt/apk install (system)
```

## Major State

### Exported Environment Variables (from `system-info.sh`)

| Variable | Scope | Mutability |
|----------|-------|------------|
| `OS`, `DISTRO`, `DISTRO_FAMILY` | Global | Read-only after detection |
| `ARCH`, `ARCH_FAMILY` | Global | Read-only |
| `DEVICE_MODEL`, `CHASSIS_TYPE` | Global | Read-only |
| `HAS_GUI`, `DESKTOP_ENVIRONMENT`, `DISPLAY_SERVER` | Global | Read-only |
| `GPU_FAMILY`, `IS_BATTERY_DEVICE` | Global | Read-only |
| `POWERFUL_PC`, `IS_DEVELOPMENT_DEVICE`, `IS_GAMING_DEVICE` | Global | Read-only |
| `HAS_SU_PRIVILEGES` | Global | Read-only |
| `REPO_DIR`, `ROOT_*`, `HOME_REAL`, `XDG_*` | Global | Read-only |

### Derived State (in `configure-system.sh`)

| Variable | Derived From | Purpose |
|----------|--------------|---------|
| `GTK_THEME`, `GTK_THEME_VARIANT` | `get_theme()`, `get_theme_mode()` | Theme selection |
| `INTERFACE_FONT`, `MONOSPACE_FONT`, etc. | Screen height, DPI | Font sizing |
| `TERMINAL_SIZE_COLS/ROWS` | Screen resolution | Terminal geometry |
| `ZOOM_LEVEL` | Screen height | UI scaling |
| `USING_INTEL_GPU`, `USING_NVIDIA_GPU` | `GPU_FAMILY` | GPU-specific config |
| `IS_SERVER` | Screen resolution | Headless detection |

## Major Integrations

| Integration | Layer | Configuration |
|-------------|-------|---------------|
| Package managers | Foundation | `package-management.sh` dispatch |
| Display servers | Detection | `system-info.sh` → `DISPLAY_SERVER` |
| Desktop environments | Detection + Config | `DESKTOP_ENVIRONMENT` → gsettings/kwriteconfig |
| GPU drivers | Kernel params | `configure-system.sh` → modprobe.d |
| Bootloader | Config | `update-grub.sh` → /etc/grub.d/ |
| Hardware (Argon) | Detection + Config | `configure-hardware-integration.sh` |
| Android/Termux | Platform guard | `IS_ANDROID` → skip system config |

## System-Wide Invariants

1. **Idempotency** — All file operations use `update_file_if_distinct` (content comparison)
2. **Privilege separation** — Explicit `run_script` vs `run_script_as_su`; no ambient authority
3. **Platform guards** — GUI config wrapped in `if ${HAS_GUI}`; Android guarded by `IS_ANDROID`
4. **Binary existence checks** — `update_file_if_binary_exists` before deploying app configs
5. **Ordering** — `run.sh` enforces strict phase sequence; dependencies flow forward
6. **Failure isolation** — No `set -e` at top level; individual script failures don't halt orchestration
7. **Environment consistency** — `LANG=en_US.UTF-8` forced for deterministic command output
8. **Distro awareness** — All package operations dispatch via `DISTRO_FAMILY`
9. **Resolution awareness** — All sizing derives from detected screen dimensions
10. **Device awareness** — Special handling for Argon ONE UP, Steam Deck, Raspberry Pi