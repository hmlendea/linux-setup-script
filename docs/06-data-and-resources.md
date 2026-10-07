# 06 — Data and Resources

Complete inventory of static data files, resource templates, and their roles in the provisioning process.

## 6.1 Data Files (`data/`)

### `data/steam-names.txt`
**Format**: `APP_ID=Game Name` (one per line)
**Purpose**: Maps Steam AppIDs to human-readable game names
**Used by**: Not directly referenced in scripts; likely for external tooling or documentation
**Sample entries**:
```
8930=Civilisation V
289070=Civilisation VI
374320=Dark Souls III
813780=Age of Empires II
1206560=WorldBox
```

### `data/steam-wmclasses.txt`
**Format**: `APP_ID=WM_CLASS` (one per line)
**Purpose**: Maps Steam AppIDs to X11 WM_CLASS values for window matching
**Used by**: Not directly referenced in scripts; likely for window manager rules or gaming scripts
**Sample entries**:
```
730=csgo_linux64
8930=Civ5XP
20920=witcher2
262060=Darkest Dungeon
108600=Project Zomboid
```

---

## 6.2 Resource Templates (`resources/`)

### 6.2.1 Firefox (`resources/firefox/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `containers.json` | Profile `/containers.json` | Container tabs configuration (personal, work, banking, shopping) |
| `userChrome.css` | Profile `/chrome/userChrome.css` | Custom UI styling (tab bar, toolbar, sidebar modifications) |
| `icons/*.png` | Profile `/chrome/icons/` | Custom icons for container tabs and UI elements |

**Deployment**: `update-resources.sh` → `get_firefox_profile_dir()` → copies if profile exists

### 6.2.2 Git Hooks (`resources/git/hooks/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `post-checkout` | `~/.config/git/hooks/post-checkout` | Runs after `git checkout`; updates submodules, regenerates build files |
| `prepare-commit-msg` | `~/.config/git/hooks/prepare-commit-msg` | Prepares commit message template with branch name, issue refs |

**Deployment**: `update-resources.sh` → makes executable (`chmod +x`)

### 6.2.3 LXPanel (`resources/lxpanel/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `applications.png` | `~/.config/lxpanel/LXDE/panels/applications.png` | Application menu icon (default) |
| `applications_ro.png` | `~/.config/lxpanel/LXDE/panels/applications_ro.png` | Application menu icon (Romanian locale) |
| `power.png` | `~/.config/lxpanel/LXDE/panels/power.png` | Power button icon |
| `lxde-logout-gnomified.desktop` | `~/.local/share/applications/lxde-logout-gnomified.desktop` | Custom logout dialog desktop entry |

**Deployment**: `update-resources.sh` (if `lxpanel` binary exists)

### 6.2.4 Plank (`resources/plank/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `dock.theme` | `~/.local/share/plank/themes/Hori/dock.theme` | Custom dock theme (colors, size, behavior) |
| `autostart.desktop` | `~/.config/autostart/plank.desktop` | Autostart entry for Plank dock |

**Deployment**: `update-resources.sh` (if `plank` binary exists)

### 6.2.5 neofetch (`resources/neofetch/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `ascii-arch` | `~/.config/neofetch/ascii` | Arch Linux ASCII logo |
| `ascii-lineageos` | `~/.config/neofetch/ascii` | LineageOS ASCII logo |

**Deployment**: `update-resources.sh` → selects based on `DISTRO` (Arch Linux or LineageOS)

### 6.2.6 PCManFM (`resources/pcmanfm/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `open-in-code.desktop` | `~/.local/share/file-manager/actions/open-in-code.desktop` | "Open in VS Code" context menu action |
| `open-in-terminal.desktop` | `~/.local/share/file-manager/actions/open-in-terminal.desktop` | "Open in Terminal" context menu action |

**Deployment**: `update-resources.sh` (if `pcmanfm` + `code-oss`/`lxterminal` exist)

### 6.2.7 Templates (`resources/templates/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `file` | `~/Templates/Blank file` | Empty file template |
| `doc` | `~/Templates/Microsoft Document.doc` | MS Word template (if LibreOffice installed) |
| `odt` | `~/Templates/Document.odt` | LibreOffice Writer template (if LibreOffice installed) |

**Deployment**: `update-resources.sh` (GUI only); removes doc/odt if LibreOffice not installed

### 6.2.8 udev Rules (`resources/udev/`)
| File | Destination | Condition | Purpose |
|------|-------------|-----------|---------|
| `wifi_powersave.rules` | `/etc/udev/rules.d/873-wifi_powersave.rules` | Laptop only | Enables WiFi power saving |
| `ioschedulers.rules` | `/etc/udev/rules.d/873-ioschedulers.rules` | Always | Sets I/O scheduler (BFQ for HDD, none for NVMe/SSD) |
| `pci_pm.rules` | `/etc/udev/rules.d/873-pci_pm.rules` | Always | Enables PCI power management |
| `usb_powersave.rules` | `/etc/udev/rules.d/873-usb_powersave.rules` | Battery device only | Enables USB autosuspend |

**Deployment**: `update-resources.sh` (root context on Linux)

---

## 6.3 RC Templates (`rc/`)

### 6.3.1 Shell (`rc/shell/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `aliases` | `~/.local/share/bash/aliases` | Shell aliases (ls, grep, git, docker, systemctl shortcuts) |
| `bash_profile` | `~/.bash_profile` | Sources `.bashrc` if bash |
| `bashrc` | `~/.bashrc` | Main bash config; sources variables, aliases, functions, prompt, options, processes, ble.sh, pkgfile, zoxide |
| `functions` | `~/.local/share/bash/functions` | Shell functions (extract, mkcd, weather, cheat, etc.) |
| `opts` | `~/.local/share/bash/options` | Shell options (histappend, checkwinsize, globstar, etc.) |
| `processes` | `~/.local/share/bash/processes` | Process management functions (psgrep, killport, etc.) |
| `prompt` | `~/.local/share/bash/prompt` | Custom PS1 with git status, exit code, timer |
| `inputrc` | `~/.config/readline/inputrc` | Readline config (vi mode, completion, history search) |

### 6.3.2 Git (`rc/gitconfig`)
**Destination**: `~/.config/git/config`
**Sections**: user, core, merge, credential, push, pull, diff, rebase, init, color, help, http, alias
**Key aliases**: `co=checkout`, `br=branch`, `ci=commit`, `st=status`, `lg=log --graph`, `unstage=reset HEAD`

### 6.3.3 Application Configs
| App | Source Files | Destination |
|-----|--------------|-------------|
| GIMP | `gimprc`, `sessionrc`, `toolrc` | `~/.config/GIMP/2.10/` + Flatpak equivalent |
| nano | `nanorc` | `~/.nanorc` |
| vim | `vimrc` | `~/.vimrc` |
| lxpanel | `lxde-panel` | `~/.config/lxpanel/LXDE/panels/panel` |
| lxpanel | `lxde-dock` | `~/.config/lxpanel/LXDE/panels/dock` (commented) |

### 6.3.4 GRUB (`rc/grub/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `25_windows` | `/etc/grub.d/25_windows` | Windows boot entry |
| `29_android` | `/etc/grub.d/29_android` | Android (generic) boot entry |
| `29_blissos` | `/etc/grub.d/29_blissos` | Bliss OS boot entry |
| `29_phoenixos` | `/etc/grub.d/29_phoenixos` | Phoenix OS boot entry |
| `29_primeos` | `/etc/grub.d/29_primeos` | Prime OS boot entry |
| `99_power` | `/etc/grub.d/99_power` | Power off / Reboot / Firmware entries |

**Deployment**: `update-grub.sh` → `update_grub_rc()` copies if target OS root exists

### 6.3.5 Keyboard Layouts (`rc/keyboard-layouts/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `ro` | `/usr/share/X11/xkb/symbols/ro` | Standard Romanian keyboard layout |
| `ro-argononeup` | `/usr/share/X11/xkb/symbols/ro` | Argon ONE UP variant (function key fixes) |

**Deployment**: `configure-locale.sh` (root, GUI only)

### 6.3.6 Network Manager (`rc/network-manager/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `mac-randomisation.conf` | `/etc/NetworkManager/conf.d/mac-randomisation.conf` | Disables MAC randomisation for stable WiFi identity |

### 6.3.7 Hidden Files (`rc/hidden-files/`)
| File | Destination | Purpose |
|------|-------------|---------|
| `home` | `~/.hidden` | Hides standard directories in English locales |
| `home-ro` | `~/.hidden` | Hides standard directories in Romanian locales |
| `home-documents` | `~/Documents/.hidden` | Hides files in Documents |
| `home-downloads` | `~/Downloads/.hidden` | Hides files in Downloads |

**Deployment**: `configure-directories.sh` (selects `home` vs `home-ro` based on `XDG_DOWNLOAD_DIR`)

### 6.3.8 Boot Firmware (`rc/boot_firmware_config_argononeup.txt`)
**Destination**: `/boot/firmware/config.txt` (Argon ONE UP only)
**Purpose**: Raspberry Pi firmware config for Argon ONE UP fan/controller

---

## 6.4 Profile Scripts (`profiles/`)

| File | Destination | Trigger | Purpose |
|------|-------------|---------|---------|
| `cmake.sh` | `/etc/profile.d/cmake.sh` | `make` binary exists | Sets `MAKEFLAGS="-j$(nproc)"` for parallel builds |
| `dotnet.sh` | `/etc/profile.d/dotnet.sh` | `dotnet` binary exists | Sets `DOTNET_ROOT`, `MSBuildSDKsPath`, adds `~/.dotnet/tools` to PATH, sets `DOTNET_BUNDLE_EXTRACT_BASE_DIR` |

**Deployment**: `update-profiles.sh` (root, non-Android)

---

## 6.5 Deployment Invariants

1. **Idempotency**: All deployments use `update_file_if_distinct` (content comparison before write)
2. **Binary guards**: `update_file_if_binary_exists` checks command existence before deploying app configs
3. **Platform guards**: GUI-only resources wrapped in `if ${HAS_GUI}; then`
4. **Root separation**: System paths (`/etc`, `/usr`, `/boot`) deployed via `run_as_su` / `run_script_as_su`
5. **Distro awareness**: neofetch ASCII, keyboard layouts, font faces adapt to `DISTRO_FAMILY`
6. **Device awareness**: Argon ONE UP gets special firmware config, keyboard layout, hardware integration
7. **Cleanup**: Obsolete resources removed (e.g., `usb_powersave.rules` on non-battery, doc/odt templates without LibreOffice)