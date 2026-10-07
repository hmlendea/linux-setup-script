# 05 — Script Inventory

Complete inventory of all executable scripts in the repository, their responsibilities, and invocation patterns.

## 5.1 Entry Point

### `run.sh`
**Location**: Repository root  
**Purpose**: Primary orchestration script; executes all phases in strict sequence  
**Entry**: Direct execution `./run.sh`  
**Privileges**: Mixed (user + root via `run_script_as_su`)  
**Dependencies**: All foundation modules (`filesystem.sh`, `common.sh`, `package-management.sh`, `system-info.sh`)  
**Execution**: See [02-execution-model.md](02-execution-model.md) for complete flow

---

## 5.2 Phase 1: Repository & Package Management

### `scripts/configure-repositories.sh`
**Purpose**: Add package repositories and import GPG keys for all supported distros  
**Context**: Root (via `run_script_as_su`)  
**Platform**: Linux only (skipped on Android/WSL)  
**Operations**:
- Arch: Adds `hmlendea`, `multilib`, `valveaur`, `dx37essentials`, architecture-specific repos
- Debian/Ubuntu: Adds Docker, Microsoft, Julian's repo, Prism Launcher (gaming)
- Raspberry Pi OS: Microsoft, Julian's repo, Docker, Prism Launcher
- Flatpak: Adds flathub and flathub-beta (system + user)
**Key functions**: `add_arch_repository`, `add_apt_repository_deb`, `add_apt_repository_manual`, `add_flatpak_remote`

### `scripts/update-repositories.sh`
**Purpose**: Refresh package databases after repository changes  
**Context**: User  
**Platform**: Linux only  
**Operations**: `pacman -Sy`, `apt update`, `apk update`, `pkg update`

### `scripts/uninstall-packages.sh`
**Purpose**: Remove unwanted/conflicting packages; deduplicate by desktop environment  
**Context**: User  
**Platform**: Linux only  
**Operations**:
- Removes unused dependencies (`pacman -Qdtq`, `apt autoremove`)
- Deduplicates by DE: keeps one archive manager, browser, terminal, etc.
- Removes Flatpak unused runtimes and dependencies
- Removes Cargo packages not in use
**Key function**: `keep_first_installed_package`

### `scripts/update-packages.sh`
**Purpose**: Update all package sources  
**Context**: User  
**Platform**: Linux only  
**Operations**:
- System packages: `pacman -Su`, `apt upgrade`, `apk upgrade`, `pkg upgrade`
- Cargo: `cargo install --force` for all installed packages
- Flatpak: `flatpak update`
- GNOME extensions: `gnome-shell-extension-installer --update`
- Pi-hole (Ubuntu): `pihole -up`

### `scripts/install-packages.sh`
**Purpose**: Install curated package selection based on device profile  
**Context**: User  
**Platform**: Linux + Android  
**Categories**:
- Basics: `coreutils`, `curl`, `wget`, `most`, `bat`, `sudo`/`tsu`, `findutils`
- Base-devel: `autoconf`, `binutils`, `make`, `fakeroot`, `patch`, `gcc`, `pkgconf`
- Package managers: `paru`/`yay` (Arch), `cargo` (Debian/Ubuntu), `flatpak` (GUI)
- Development: `git`, `automake`, `github-cli` (dev devices)
- Runtimes/SDKs: .NET, Node.js, Python, Rust, Go, Java (dev devices)
- Containers: `docker`, `podman`, `buildah` (dev devices)
- Editors: `code`, `neovim`, `micro`
- Terminals: `alacritty`, `kitty`, `gnome-terminal`, `foot`
- Shell: `zsh`, `fish`, `starship`, `zoxide`, `fzf`, `bat`, `eza`
- GUI apps: browsers, IDEs, media players, chat, email, password managers
- Gaming: Steam, Lutris, Heroic, Prism Launcher (gaming devices)
- Fonts: Noto, JetBrains Mono, Fira Code, emoji fonts
- Themes: adw-gtk3, ZorinGrey, Papirus, Vimix cursors
- Hardware: `tlp`, `thermald`, `cpupower`, `argononeup` (Argon ONE UP)

### `scripts/clean-packages.sh`
**Purpose**: Clean package caches  
**Context**: Root (Arch) / User (others)  
**Operations**:
- Arch: `paccache -ruk0`, `paccache -rk1`, `pacman -Scc`
- Debian/Ubuntu: `apt autoremove`
- Alpine: `apk cache clean`

---

## 5.3 Phase 2: Configuration Deployment

### `scripts/update-rcs.sh`
**Purpose**: Deploy all user-level configuration files (dotfiles, shell, SSH, Git, app configs)  
**Context**: User (also root on Linux)  
**Operations**:
- `.profile`: XDG directories, PATH, environment variables
- Shell: `.bashrc`, `.bash_profile`, `.bash_prompt`, variables, aliases, functions, options, prompt, processes
- SSH: `config`, `config.d/linux-setup-script.conf` (AddKeysToAgent)
- Git: `config` (user, core, merge, credential, push, pull, diff, rebase, init, color, help, http, alias)
- Application configs: GIMP, nano, vim, lxpanel
- Firefox: policies.json, containers.json, userChrome.css, icons
- npm: `.npmrc` (prefix, cache, tmp, init-module)
- Shell variables: EDITOR, PACKAGE_MANAGER, BAT_THEME, DOTNET_*, GPU vars, Steam vars
- Hardware-specific: Argon ONE UP firmware config, Raspberry Pi GPU memory

### `scripts/update-profiles.sh`
**Purpose**: Deploy system-wide profile.d scripts  
**Context**: Root (non-Android)  
**Operations**:
- `dotnet.sh`: Sets `DOTNET_ROOT`, `MSBuildSDKsPath`, adds dotnet tools to PATH
- `cmake.sh`: Sets `MAKEFLAGS="-j$(nproc)"`

### `scripts/update-resources.sh`
**Purpose**: Deploy resource templates (Firefox, Git hooks, LXPanel, Plank, neofetch, PCManFM, templates, udev rules)  
**Context**: User + Root (Linux)  
**Operations**:
- Firefox: containers.json, userChrome.css, icons
- Git hooks: post-checkout, prepare-commit-msg
- LXPanel: panel images, logout desktop entry
- Plank: dock theme
- neofetch: ASCII logos (Arch, LineageOS)
- PCManFM: "Open in Code", "Open in Terminal" actions
- Templates: Blank file, Microsoft Document.doc, Document.odt
- udev rules: wifi_powersave (laptop), ioschedulers, pci_pm, usb_powersave (battery devices)

---

## 5.4 Phase 3: System Configuration

### `scripts/configure-system.sh`
**Purpose**: Comprehensive system configuration (kernel, sysctl, modprobe, fonts, themes, shell, GRUB, GNOME)  
**Context**: User + Root (Linux)  
**Operations**:
- Theme resolution: GTK theme, variant, icon, cursor, sound themes
- Font resolution: Interface, document, titlebar, menu, monospace, subtitles, text editor, browser, emoji (resolution/DPI aware)
- Terminal config: size, scrollback, colors, cursor shape
- Default shell: `chsh` to bash
- Papirus icon colourisation (grey folders)
- mkinitcpio: COMPRESSION=lz4
- modprobe.d: Intel GPU (i915), NVIDIA (nvidia-drm), Bluetooth, USB autosuspend, audio, WiFi, blacklist (pcmcia, yenta_socket, uhci_hcd)
- sysctl.d: Network (BBR, cake), IPv6 disable, kernel (coredump disable, NMI watchdog), memory (laptop vs desktop, SD card)
- systemd: journald (volatile on SD), logind (KillUserProcesses), system.conf timeouts
- GRUB: timeout, theme, cmdline (mitigations=off, random.trust_cpu=on, intel_idle.max_cstate=1, resume=/swapfile)
- GNOME: animations, calendar, datetime, clock, hot corners, toolbar, fonts, theme, icon, cursor, battery %, color-scheme, touchpad, privacy, remote desktop

### `scripts/configure-launchers.sh`
**Purpose**: Modify .desktop files for installed applications  
**Context**: User (Linux GUI, non-WSL)  
**Operations**: Sets Name, Name[ro], Categories, Icon, NoDisplay, StartupWMClass, Keywords for 100+ applications across categories:
- AI (LM Studio), App Stores, Archive Managers, Audio Players, Browsers, Calculators, Cameras, Chat, Code Editors, Database, Disk, Email, File Managers, Games, IDEs, Image Viewers, Media Players, Messengers, Notes, Office, Password Managers, Remote Desktop, Screenshots, Settings, Terminals, Text Editors, Video Players, Virtualization, VPN, Web Apps

### `scripts/configure-autostart-apps.sh`
**Purpose**: Configure user autostart .desktop entries  
**Context**: User (Linux GUI)  
**Applications**: Discord (disabled), ElectronMail, Planify, Plank, Signal, Telegram

### `scripts/configure-default-apps.sh`
**Purpose**: Set default applications via mimeapps.list  
**Context**: User (Linux GUI)  
**Associations**: Browser, disk image mounter, document viewer, email client, Facebook Messenger, file manager, GIMP, IDE, image viewers, media players, PDF viewer, text editor, video player, archive manager

### `scripts/configure-permissions.sh`
**Purpose**: Configure Flatpak/GNOME application permissions  
**Context**: User (Linux GUI)  
**Permissions managed**: background, camera, all-devices, shared-memory, filesystem-home, microphone, speakers, location, network, notification, notification_lockscreen  
**Applications**: AI apps, API clients, audio players, browsers, calculators, cameras, chat (gaming/regular), code editors, database, disk, email, file managers, games, IDEs, image viewers, media players, messengers, notes, office, password managers, remote desktop, screenshots, settings, terminals, text editors, video players, virtualization, VPN, web apps

### `scripts/configure-directories.sh`
**Purpose**: Configure XDG directories, hidden files, symlinks, Minecraft screenshots  
**Context**: User (Linux GUI + Android)  
**Operations**:
- Hidden files: `.hidden` configs for home, Documents, Downloads (Romanian/English variants)
- user-dirs.conf, user-dirs.dirs, user-dirs.locale
- Directory icons (folder-projects)
- Minecraft: Symlinks instance screenshots to shared directory
- Android: Symlinks emulated storage to XDG dirs

### `scripts/configure-locale.sh`
**Purpose**: Configure system locale, console font, keymap, X11 keyboard layouts  
**Context**: Root (Linux)  
**Configuration**:
- vconsole.conf: FONT=eurlatgr, KEYMAP=ro-std
- locale.conf: LANG=en_GB.UTF-8, LC_CTYPE=en_US.UTF-8, LC_*=ro_RO.UTF-8
- locale.gen: en_GB, en_US, ro_RO
- X11 keymaps: ro (standard), ro-argononeup (Argon ONE UP)

### `scripts/configure-time.sh`
**Purpose**: Configure timezone and RTC sync  
**Context**: Root (Linux)  
**Configuration**: Timezone=Europe/Bucharest, RTC sync via hwclock

### `scripts/configure-services-user.sh`
**Purpose**: Mask/disable unwanted user systemd services  
**Context**: User (Linux)  
**Services masked (GNOME)**: gnome-software, gnome-software-monitor, ibus, SettingsDaemon (Sharing, Smartcard, UsbProtection, Wacom), tracker-miner-fs/extract/store (non-powerful), localsearch-3, obex, filter-chain

### `scripts/configure-services-system.sh`
**Purpose**: Enable/disable system services  
**Context**: Root (Linux/Android)  
**Enabled**: bluetooth, cups, docker, fail2ban, fstrim.timer, repo-synchroniser.timer, sshd, systemd-timesyncd, thermald, NetworkManager (GUI), netctl-auto@wlan0 + dhcpcd (non-GUI), chrony/ntpd/systemd-timesyncd (priority), tlp (laptop), sshd (Raspberry Pi)  
**Disabled**: nfs-blkmap, rpcbind, pcscd, avahi-daemon, ModemManager, NetworkManager-wait-online

### `scripts/configure-hardware-integration.sh`
**Purpose**: Device-specific hardware setup  
**Context**: Root (Linux)  
**Argon ONE UP**: Clones and installs argon-oneup fan controller, argononeup-automatic-shutdown, disables argononeupd service

### `scripts/update-grub.sh`
**Purpose**: Regenerate GRUB config with custom entries  
**Context**: Root (Linux, if grub-mkconfig exists)  
**Operations**:
- Deploys grub.d scripts: 25_windows, 29_android, 29_blissos, 29_phoenixos, 29_primeos, 99_power
- Runs `update-grub` or `grub-mkconfig`
- Renames "Windows Boot Manager" → "Windows"
- Removes "Advanced options" submenu

---

## 5.5 Optional Git Setup

### `scripts/git/setup-gpg-key.sh`
**Purpose**: Configure Git signing with existing GPG key  
**Context**: User  
**Operations**: Reads key ID from `~/.local/share/gnupg/github_key_id.txt`, sets `user.signingkey` and `commit.gpgsign`

### `scripts/git/setup-ssh-key.sh`
**Purpose**: Generate ed25519 SSH key for GitHub  
**Context**: User  
**Operations**: Generates `github_${HOSTNAME}_id_ed25519`, adds to agent, creates SSH config with AddKeysToAgent, opens GitHub keys page

---

## 5.6 Foundation Modules (`scripts/common/`)

| Module | Purpose | Key Exports |
|--------|---------|-------------|
| `filesystem.sh` | Path constants, directory/file utilities | `REPO_DIR`, `ROOT_*`, `HOME_REAL`, `XDG_*`, `create_directory`, `create_file`, `remove`, `update_file_if_distinct`, `create_symlink` |
| `common.sh` | Privilege escalation, script execution, shell detection | `run_as_su`, `run_script`, `run_script_as_su`, `get_preferred_script_shell`, `LANG=en_US.UTF-8` |
| `system-info.sh` | Hardware/environment detection | `get_screen_width/height/dpi`, `get_arch/family`, `get_device_model`, `get_chassis_type`, `get_cpu/gpu/audio/wifi`, `get_display_server`, `get_os_language`, `get_uptime_text`, `is_system_storage_sd_card` |
| `package-management.sh` | Unified package manager abstraction | `call_package_manager`, `install_native_package(s)`, `uninstall_native_package(s)`, `install_flatpak(s)`, `install_cargo_package`, `install_github_package`, `install_aur_package_manually`, `install_vscode_extension`, `call_gnome_extensions`, `is_package_installed`, `is_native_package_installed`, `is_flatpak_installed`, `is_github_package_installed`, `is_webapp_installed`, `is_android_package_installed`, `is_vscode_extension_installed`, `is_steam_app_installed`, `get_latest_github_release_assets` |
| `config.sh` | Configuration file manipulation (INI, JSON, XML, Firefox, GSettings, modprobe, pulseaudio) | `get_config_value`, `set_config_value`, `set_config_values`, `set_ini_config_value`, `set_json_property`, `set_xml_node`, `set_firefox_config`, `set_modprobe_option`, `set_pulseaudio_module_option`, `has_gsettings_session`, `call_gsettings`, `get_gsetting`, `set_gsetting`, `set_gsettings` |
| `service-management.sh` | systemd/OpenRC service control | `does_service_exist`, `is_service_enabled`, `enable_service(s)`, `disable_service(s)`, `disable_user_service`, `mask_user_service(s)`, `unmask_user_service`, `set_service_property` |
| `apps.sh` | Firefox profile detection | `get_firefox_profiles_dir`, `get_firefox_profile_id`, `get_firefox_profile_dir` |
| `permissions.sh` | Flatpak/GNOME/Android permission management | `set_linux_permission`, `set_flatpak_permission`, `set_flatpak_shared`, `set_flatpak_device`, `set_flatpak_filesystem`, `set_flatpak_socket`, `get_flatpak_permission`, `get_flatpak_metadata_value`, `get_android_permission` |

---

## 5.7 Invocation Patterns

### Direct Execution
```bash
./run.sh                          # Full provisioning
./scripts/install-packages.sh     # Package installation only
./scripts/update-rcs.sh           # Config deployment only
```

### Via run.sh Helpers
```bash
run_script "scripts/configure-system.sh"        # User context
run_script_as_su "scripts/configure-system.sh"  # Root context
```

### Foundation Module Sourcing
Every script sources in order:
```bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"  # Most scripts
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"  # Package scripts
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"       # Config scripts
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"  # Service scripts
source "${REPO_SCRIPTS_COMMON_DIR}/apps.sh"         # Firefox scripts
source "${REPO_SCRIPTS_COMMON_DIR}/permissions.sh"  # Permission scripts
```