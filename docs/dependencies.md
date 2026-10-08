# Dependencies

This document catalogues all external and internal dependencies of the
linux-setup-script repository.

## External Dependencies

### Required System Utilities (Assumed Present)

| Utility | Purpose | Platform Availability |
|---------|---------|----------------------|
| `bash` | Script interpreter | All (v4+ for associative arrays) |
| `coreutils` | `cp`, `mv`, `rm`, `mkdir`, `cat`, `grep`, `sed`, `awk`, `cut`, `sort`, `find`, `xargs` | All |
| `findutils` | `find`, `xargs` | All |
| `grep` | Pattern matching | All |
| `sed` | Stream editing | All |
| `awk` | Text processing | All |
| `curl` / `wget` | HTTP downloads (GitHub releases, Flatpak) | All |
| `git` | Version control, submodules | All |
| `sudo` / `su` | Privilege escalation | Linux / Android |
| `uname` | OS/arch detection | All |
| `lscpu` / `/proc/cpuinfo` | CPU detection | Linux |
| `lsblk` / `blkid` | Block device detection | Linux |
| `dmidecode` | Hardware detection (chassis, BIOS) | Linux (root) |
| `lspci` | PCI device detection (GPU, audio, WiFi) | Linux |
| `glxinfo` | OpenGL/GPU detection | Linux (GUI) |
| `xrandr` / `xdpyinfo` | X11 screen detection | Linux (X11) |
| `wayland-info` | Wayland screen detection | Linux (Wayland) |
| `systemd-detect-virt` | Virtualization detection | Linux (systemd) |
| `flatpak` | Flatpak package management | Linux (GUI) |
| `cargo` | Rust package management | All (if Rust installed) |
| `code` / `codium` / `code-oss` | VS Code extensions | Linux (GUI) |
| `gnome-shell-extension-installer` | GNOME extensions | Linux (GNOME) |
| `jq` | JSON manipulation (preferred) | Linux (optional, fallback to sed) |
| `grub-mkconfig` / `update-grub` | GRUB config generation | Linux (GRUB) |
| `mkinitcpio` | Initramfs generation | Arch/Alpine |
| `update-initramfs` | Initramfs generation | Debian/Ubuntu |
| `hwclock` | RTC sync | Linux |
| `localectl` / `timedatectl` | Locale/time configuration | Linux (systemd) |

### Package Manager Dependencies (Per Platform)

| Platform | Native Manager | AUR Helper | Additional |
|----------|----------------|------------|------------|
| Arch | `pacman` | `paru` (preferred), `yay`, `yaourt` | `pacman-contrib` (paccache) |
| Debian/Ubuntu | `apt` | — | `apt-transport-https`, `ca-certificates`, `gnupg` |
| Alpine | `apk` | — | — |
| Android/Termux | `pkg` | — | `termux-api`, `termux-tools`, `proot-distro` |
| SteamOS | `rpm-ostree` | — | Flatpak (primary) |
| Immutable (Silverblue/Kinoite) | `rpm-ostree` | — | Flatpak, Toolbox/Distrobox |

### Runtime Dependencies (Installed by Scripts)

#### Development Tools
- `git`, `github-cli` (gh), `automake`, `autoconf`, `binutils`, `make`, `fakeroot`, `patch`, `gcc`, `pkgconf`
- `dotnet-sdk` (.NET), `nodejs`/`npm`, `python`, `rust`/`cargo`, `go`, `java` (OpenJDK)
- `docker`, `podman`, `buildah` (containers)
- `cmake`, `meson`, `ninja` (build systems)

#### Editors & Terminals
- `code` (VS Code), `neovim`, `micro`
- `alacritty`, `kitty`, `gnome-terminal`, `foot`, `lxterminal`
- `zsh`, `fish`, `starship`, `zoxide`, `fzf`, `bat`, `eza`

#### GUI Applications
- Browsers: `firefox`, `librewolf`, `chromium`, `brave`, `vivaldi`
- IDEs: `jetbrains-toolbox`, `android-studio`
- Media: `vlc`, `mpv`, `celluloid`, `strawberry`, `lollypop`
- Chat: `discord`, `signal-desktop`, `telegram-desktop`, `element-desktop`
- Email: `thunderbird`, `evolution`, `geary`
- Office: `libreoffice`, `onlyoffice`
- Virtualization: `virt-manager`, `gnome-boxes`, `qemu`
- Gaming: `steam`, `lutris`, `heroic-games-launcher`, `prismlauncher`

#### Fonts & Themes
- `noto-fonts`, `noto-fonts-emoji`, `noto-fonts-cjk`
- `ttf-jetbrains-mono`, `ttf-fira-code`, `ttf-font-awesome`
- `adw-gtk3-theme`, `zorin-gtk-theme`, `papirus-icon-theme`, `vimix-cursors`

#### System Utilities
- `tlp`, `thermald`, `cpupower`, `powertop` (laptop power)
- `pipewire`, `wireplumber`, `pipewire-pulse`, `pipewire-alsa` (audio)
- `networkmanager`, `netctl`, `dhcpcd`, `iwd` (network)
- `chrony`, `ntp`, `systemd-timesyncd` (time sync)
- `fail2ban`, `sshguard` (security)
- `fstrim.timer` (SSD trim)

### Optional Dependencies

| Dependency | Used By | Fallback |
|------------|---------|----------|
| `jq` | `config.sh` (JSON) | `sed`-based parsing |
| `gnome-shell-extension-installer` | `update-packages.sh` | Skip GNOME extension updates |
| `paccache` | `clean-packages.sh` (Arch) | `pacman -Sc` |
| `wayland-info` | `system-info.sh` (Wayland) | `xdpyinfo`/`xrandr` fallback |
| `xdpyinfo` | `system-info.sh` (X11 DPI) | Hardcoded defaults |
| `dmidecode` | `system-info.sh` (chassis) | `systemd-detect-virt` fallback |
| `flatpak` | `package-management.sh`, `permissions.sh` | Skip Flatpak operations |
| `cargo` | `package-management.sh` | Skip Cargo operations |
| `code` | `package-management.sh`, `resources/pcmanfm/` | Skip VS Code operations |
| `lxpanel` | `resources/lxpanel/` | Skip LXPanel resources |
| `plank` | `resources/plank/` | Skip Plank resources |
| `pcmanfm` | `resources/pcmanfm/` | Skip PCManFM actions |
| `neofetch` | `resources/neofetch/` | Skip neofetch ASCII |
| `libreoffice` | `resources/templates/` (doc/odt) | Remove doc/odt templates |

## Internal Dependencies

### Foundation Module Dependency Graph

```
filesystem.sh (no internal deps)
    │
    ├── common.sh
    │       └── filesystem.sh
    │
    ├── system-info.sh
    │       ├── filesystem.sh
    │       └── common.sh
    │
    ├── package-management.sh
    │       ├── filesystem.sh
    │       ├── common.sh
    │       └── system-info.sh
    │
    ├── config.sh
    │       └── filesystem.sh
    │
    ├── service-management.sh
    │       ├── filesystem.sh
    │       ├── common.sh
    │       └── config.sh
    │
    ├── apps.sh
    │       └── filesystem.sh
    │
    ├── permissions.sh
    │       ├── config.sh
    │       └── package-management.sh (for is_flatpak_installed)
    │
    └── github.sh (no internal deps)
```

### Phase Script Dependencies on Foundation Modules

| Phase Script | Foundation Modules Sourced |
|--------------|---------------------------|
| `configure-repositories.sh` | filesystem, common, system-info, package-management |
| `update-repositories.sh` | filesystem, common, system-info, package-management |
| `uninstall-packages.sh` | filesystem, common, system-info, package-management |
| `update-packages.sh` | filesystem, common, system-info, package-management |
| `install-packages.sh` | filesystem, common, system-info, package-management |
| `clean-packages.sh` | filesystem, common, system-info, package-management |
| `update-rcs.sh` | filesystem, common, system-info, config, apps |
| `update-profiles.sh` | filesystem, common, system-info |
| `update-resources.sh` | filesystem, common, system-info, config, apps, permissions |
| `configure-system.sh` | filesystem, common, system-info, config, service-management, package-management |
| `configure-launchers.sh` | filesystem, common, system-info, config |
| `configure-autostart-apps.sh` | filesystem, common, system-info, config |
| `configure-default-apps.sh` | filesystem, common, system-info, config |
| `configure-permissions.sh` | filesystem, common, system-info, config, permissions, package-management |
| `configure-directories.sh` | filesystem, common, system-info, config |
| `configure-locale.sh` | filesystem, common, system-info, config |
| `configure-time.sh` | filesystem, common, system-info, config |
| `configure-services-user.sh` | filesystem, common, system-info, service-management |
| `configure-services-system.sh` | filesystem, common, system-info, service-management |
| `configure-hardware-integration.sh` | filesystem, common, system-info, config, package-management |
| `update-grub.sh` | filesystem, common, system-info, config |
| `setup-gpg-key.sh` | filesystem, common, config |
| `setup-ssh-key.sh` | filesystem, common, config |

### Resource/RC Deployment Dependencies

| Deployment Script | Resources/RCs Deployed | Conditions |
|-------------------|------------------------|------------|
| `update-rcs.sh` (user) | `rc/shell/*`, `rc/gitconfig`, `rc/gimp/*`, `rc/nanorc`, `rc/vimrc`, `rc/lxde-panel` | Always (user) |
| `update-rcs.sh` (root) | `rc/profile` → `/etc/profile.d/linux-setup-script.sh` | Linux only |
| `update-profiles.sh` (root) | `profiles/cmake.sh`, `profiles/dotnet.sh` | Non-Android, binary exists |
| `update-resources.sh` (user) | `resources/firefox/*`, `resources/git/hooks/*`, `resources/lxpanel/*`, `resources/plank/*`, `resources/neofetch/*`, `resources/pcmanfm/*`, `resources/templates/*` | GUI only, binary exists |
| `update-resources.sh` (root) | `resources/udev/*`, `rc/network-manager/*`, `rc/keyboard-layouts/*` | Linux only |
| `configure-locale.sh` (root) | `rc/keyboard-layouts/*` → `/usr/share/X11/xkb/symbols/` | Linux, GUI |
| `update-grub.sh` (root) | `rc/grub/*` → `/etc/grub.d/` | Linux, grub-mkconfig exists |
| `configure-hardware-integration.sh` (root) | `rc/boot_firmware_config_argononeup.txt` → `/boot/firmware/config.txt` | Argon ONE UP only |
| `configure-directories.sh` | `rc/hidden-files/*` → `~/.hidden`, `~/Documents/.hidden`, `~/Downloads/.hidden` | GUI + Android |

### Cross-Script Data Flow

```
run.sh
    │
    ├──► system-info.sh (exports: OS, DISTRO_FAMILY, ARCH, DEVICE_MODEL, CHASSIS_TYPE,
    │       HAS_GUI, DESKTOP_ENVIRONMENT, DISPLAY_SERVER, GPU_FAMILY, IS_BATTERY_DEVICE,
    │       POWERFUL_PC, IS_DEVELOPMENT_DEVICE, IS_GAMING_DEVICE, HAS_SU_PRIVILEGES,
    │       REPO_DIR, ROOT_*, HOME_REAL, XDG_*)
    │
    ├──► Phase 1: Package Management
    │       configure-repositories.sh ──► Adds repos/keys (root)
    │       update-repositories.sh ──► Refreshes databases
    │       uninstall-packages.sh ──► Removes unwanted (user)
    │       update-packages.sh ──► Updates all sources (user)
    │       install-packages.sh ──► Installs curated selection (user)
    │       uninstall-packages.sh ──► Second pass (user)
    │       clean-packages.sh ──► Cleans caches (root/user)
    │
    ├──► Phase 2: Config Deployment
    │       update-rcs.sh (user) ──► Deploys user RCs
    │       update-rcs.sh (root) ──► Deploys /etc/profile.d script
    │       update-resources.sh (user) ──► Deploys user resources
    │       update-resources.sh (root) ──► Deploys system resources (udev, NM, keymaps)
    │       update-profiles.sh (root) ──► Deploys /etc/profile.d/cmake.sh, dotnet.sh
    │
    ├──► Phase 3: System Configuration
    │       configure-system.sh (user) ──► User-level GNOME, terminal, theme
    │       configure-system.sh (root) ──► Kernel, sysctl, modprobe, GRUB, systemd
    │       configure-launchers.sh ──► Modifies .desktop files (user, GUI)
    │       configure-autostart-apps.sh ──► Autostart entries (user, GUI)
    │       configure-default-apps.sh ──► mimeapps.list (user, GUI)
    │       configure-permissions.sh ──► Flatpak/GNOME perms (user, GUI)
    │       configure-directories.sh ──► XDG dirs, hidden files, symlinks (user)
    │       configure-locale.sh ──► Locale, keymap, X11 layouts (root)
    │       configure-time.sh ──► Timezone, RTC (root)
    │       configure-services-user.sh ──► Mask user services (user)
    │       configure-services-system.sh ──► Enable/disable system services (root)
    │       configure-hardware-integration.sh ──► Argon ONE UP, GPU (root)
    │       update-grub.sh ──► Regenerates GRUB (root)
    │
    └──► Phase 4: Git Setup (manual)
            setup-gpg-key.sh ──► GPG signing config
            setup-ssh-key.sh ──► SSH key generation
```

## Version Constraints

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| `bash` | 4.0 | Associative arrays used in `package-management.sh` |
| `git` | 2.0 | Submodule support, hooks |
| `systemd` | 230 | `systemctl --user`, `logind.conf` options |
| `flatpak` | 1.0 | Permission management, flathub remotes |
| `grub` | 2.02 | Multi-boot entries, `grub-mkconfig` |
| `mkinitcpio` | 30 | `COMPRESSION=lz4`/`zstd` |
| `NetworkManager` | 1.10 | MAC randomisation config |
| `pipewire` | 0.3 | Audio stack (preferred over PulseAudio) |

## Dependency Installation Order

The `install-packages.sh` script installs packages in this order to satisfy
dependencies:

1. **Basics**: coreutils, curl, wget, most, bat, sudo/tsu, findutils
2. **Base-devel**: autoconf, binutils, make, fakeroot, patch, gcc, pkgconf
3. **Package managers**: paru/yay (Arch), cargo (Debian/Ubuntu), flatpak (GUI)
4. **Development**: git, github-cli, automake
5. **Runtimes/SDKs**: .NET, Node.js, Python, Rust, Go, Java (dev devices)
6. **Containers**: docker, podman, buildah (dev devices)
7. **Editors/Terminals/Shell**: code, neovim, alacritty, zsh, starship, etc.
8. **GUI apps**: browsers, media, chat, office, etc. (GUI devices)
9. **Gaming**: steam, lutris, heroic, prism (gaming devices)
10. **Fonts/Themes**: noto, jetbrains-mono, adw-gtk3, papirus, vimix
11. **Hardware**: tlp, thermald, argononeup (laptop/Argon)

## Known Dependency Conflicts

| Conflict | Resolution |
|----------|------------|
| `paru` vs `yay` (AUR helpers) | Preference order: paru → yay → yaourt → pacman |
| `pipewire` vs `pulseaudio` | PipeWire preferred; PulseAudio modules configured as fallback |
| `NetworkManager` vs `netctl` | NetworkManager for GUI, netctl+dhcpcd for non-GUI |
| `chrony` vs `ntpd` vs `systemd-timesyncd` | Priority: chrony → ntpd → systemd-timesyncd |
| `flatpak` system vs user remotes | Both added; user remotes take precedence |
| `grub-mkconfig` vs `update-grub` | Tries `update-grub` first, falls back to `grub-mkconfig` |
| `rpm-ostree` vs `dnf` (immutable) | rpm-ostree for base, Flatpak for apps |

## Missing/Unverified Dependencies

The following are referenced but not verified as installed:

- `argononeup` fan controller (cloned from GitHub in `configure-hardware-integration.sh`)
- `argononeup-automatic-shutdown` (cloned from GitHub)
- `gnome-shell-extension-installer` (Python script, installed via pipx/cargo)
- `paccache` (from `pacman-contrib` on Arch)
- `wayland-info` (from `wayland-utils`)
- `xdpyinfo` (from `xorg-xdpyinfo`)
- `dmidecode` (requires root)
- `lspci` (from `pciutils`)
- `glxinfo` (from `mesa-demos` or `glxinfo` package)