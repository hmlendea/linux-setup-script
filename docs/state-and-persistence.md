# State and Persistence

This document describes state management, stores, caches, and migration
strategies in the linux-setup-script repository.

## State Categories

### 1. Runtime State (In-Memory, Ephemeral)

**Exported Environment Variables** (from `system-info.sh` at source time):

| Variable | Scope | Lifetime | Mutability |
|----------|-------|----------|------------|
| `OS`, `DISTRO`, `DISTRO_FAMILY` | Global | Process | Read-only |
| `ARCH`, `ARCH_FAMILY` | Global | Process | Read-only |
| `DEVICE_MODEL`, `CHASSIS_TYPE` | Global | Process | Read-only |
| `HAS_GUI`, `DESKTOP_ENVIRONMENT`, `DISPLAY_SERVER` | Global | Process | Read-only |
| `GPU_FAMILY`, `IS_BATTERY_DEVICE` | Global | Process | Read-only |
| `POWERFUL_PC`, `IS_DEVELOPMENT_DEVICE`, `IS_GAMING_DEVICE` | Global | Process | Read-only |
| `HAS_SU_PRIVILEGES` | Global | Process | Read-only |
| `REPO_DIR`, `ROOT_*`, `HOME_REAL`, `XDG_*` | Global | Process | Read-only |
| `SCREEN_RESOLUTION_W/H`, `SCREEN_DPI` | Global | Process | Read-only |

**Derived State** (computed in `configure-system.sh`):

| Variable | Derived From | Lifetime |
|----------|--------------|----------|
| `GTK_THEME`, `GTK_THEME_VARIANT` | `get_theme()`, `get_theme_mode()` | Process |
| `INTERFACE_FONT`, `MONOSPACE_FONT`, etc. | Screen height, DPI | Process |
| `TERMINAL_SIZE_COLS/ROWS` | Screen resolution | Process |
| `ZOOM_LEVEL` | Screen height | Process |
| `USING_INTEL_GPU`, `USING_NVIDIA_GPU` | `GPU_FAMILY` | Process |
| `IS_SERVER` | Screen resolution | Process |

### 2. Persistent State (Survives Reboot)

#### Package State

| Store | Location | Format | Management |
|-------|----------|--------|------------|
| Native packages | `/var/lib/pacman`, `/var/lib/dpkg`, `/var/lib/apk` | SQLite, dpkg, apk DB | Package manager |
| Flatpak | `/var/lib/flatpak`, `~/.local/share/flatpak` | OSTree | `flatpak` |
| Cargo | `~/.cargo` | Git registry + installed crates | `cargo` |
| GitHub releases | `/usr/local/bin` | Binary files | Manual |
| VS Code extensions | `~/.vscode/extensions`, `~/.vscode-oss/extensions` | VS Code DB | `code` |
| GNOME extensions | `~/.local/share/gnome-shell/extensions` | Extension dirs | `gnome-extensions` |

#### Configuration State

| Store | Location | Format | Management |
|-------|----------|--------|------------|
| GSettings | `~/.config/dconf/user` | Binary dconf | `gsettings` |
| GTK config | `~/.config/gtk-*/settings.ini` | INI | File deploy |
| Shell config | `~/.profile`, `~/.bashrc`, `~/.config/git/config` | Shell, INI | File deploy |
| System config | `/etc/*` | Various (INI, conf, rules) | File deploy (root) |
| Firefox | `~/.mozilla/firefox/*/`, `~/.var/app/*/firefox/` | JSON, CSS, SQLite | File deploy |
| Terminal emulators | Various | Various | File deploy / gsettings |

#### Service State

| Store | Location | Format | Management |
|-------|----------|--------|------------|
| systemd system | `/etc/systemd/system/`, `/usr/lib/systemd/system/` | Unit files + symlinks | `systemctl enable/disable` |
| systemd user | `~/.config/systemd/user/` | Unit files + symlinks | `systemctl --user enable/disable/mask` |
| OpenRC | `/etc/init.d/`, `/etc/runlevels/` | Scripts + symlinks | `rc-update` |

#### Boot State

| Store | Location | Format | Management |
|-------|----------|--------|------------|
| GRUB | `/boot/grub/grub.cfg`, `/etc/grub.d/` | Config + scripts | `grub-mkconfig` |
| Initramfs | `/boot/initramfs-*.img` | CPIO archive | `mkinitcpio`/`update-initramfs` |
| Kernel params | `/etc/modprobe.d/*.conf`, `/etc/sysctl.d/*.conf` | INI | File deploy |
| Firmware (Argon) | `/boot/firmware/config.txt` | Text | File deploy |

### 3. Cache State (Recreatable)

| Cache | Location | Purpose | Cleanup |
|-------|----------|---------|---------|
| Package cache | `/var/cache/pacman`, `/var/cache/apt`, `/var/cache/apk` | Downloaded packages | `clean-packages.sh` |
| Cargo cache | `~/.cargo/registry/cache` | Crate downloads | `cargo clean` |
| Flatpak cache | `/var/cache/flatpak`, `~/.cache/flatpak` | Runtime downloads | `flatpak uninstall --unused` |
| Font cache | `~/.cache/fontconfig` | Fontconfig | `fc-cache -f` |
| Icon cache | `~/.cache/icon-theme.cache` | GTK icons | `gtk-update-icon-cache` |
| Desktop cache | `~/.cache/desktop-*.cache` | .desktop files | `update-desktop-database` |

## State Management Patterns

### 1. Idempotent Deployment

All persistent state modifications use **content comparison** before write:

```bash
function update_file_if_distinct() {
    local src="$1" dst="$2"
    if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
        cp "$src" "$dst"
        return 0  # Changed
    fi
    return 1  # Unchanged
}
```

**Guarantees**:
- Re-running scripts produces identical state
- File metadata (mtime, permissions) preserved on no-op
- No unnecessary service reloads/restarts

### 2. Existence Guards

Before deploying application-specific config:

```bash
function update_file_if_binary_exists() {
    local binary="$1" src="$2" dst="$3"
    if command -v "$binary" >/dev/null 2>&1; then
        update_file_if_distinct "$src" "$dst"
    fi
}
```

**Applied to**: Firefox, Git hooks, LXPanel, Plank, neofetch, PCManFM, templates

### 3. Platform Guards

```bash
if ${HAS_GUI}; then
    # GUI-only config
fi

if [ "$IS_ANDROID" = "true" ]; then
    # Android-specific or skip
fi
```

### 4. Privilege Separation

| Operation | Context | Mechanism |
|-----------|---------|-----------|
| User config deploy | User | Direct execution |
| System config deploy | Root | `run_as_su` / `run_script_as_su` |
| Package install (system) | Root | `call_package_manager` via `run_as_su` |
| Package install (user/AUR) | User | `call_package_manager` direct |
| Service enable (system) | Root | `enable_service` via `run_as_su` |
| Service mask (user) | User | `mask_user_service` direct |

### 5. Detection Once, Use Many

`system-info.sh` runs detection **once at source time**, exports globals.
All scripts source it and read exported variables.

**Benefits**:
- Avoids repeated expensive operations (dmidecode, lspci, wayland-info)
- Consistent view across all scripts
- Single source of truth

## Migration Strategies

### 1. Configuration Migration

**No automated migration**. Configuration is **redeployed from templates** on each run.

- Templates in `rc/`, `resources/`, `profiles/` are source of truth
- `update_file_if_distinct` ensures only changes are written
- Manual edits to deployed files are overwritten on next run

**To preserve customisations**:
1. Modify template in `rc/` or `resources/`
2. Run relevant deployment script
3. Or use `git` to track local modifications

### 2. Package Migration

**No automated migration**. Package selection defined in `install-packages.sh`.

- Adding packages: Edit `install-packages.sh`, run it
- Removing packages: Edit `uninstall-packages.sh`, run it
- Version pinning: Not supported (always latest)

### 3. System Configuration Migration

**No automated migration**. Kernel params, sysctl, systemd, GRUB redeployed from
hardcoded values in `configure-system.sh`, `update-grub.sh`.

- Changes: Edit script, run it
- GRUB entries: Templates in `rc/grub/` deployed, then `grub-mkconfig`

### 4. Hardware Integration Migration

**Argon ONE UP**: Clones and builds from GitHub on each run
(`configure-hardware-integration.sh`). No state migration needed.

**GPU tuning**: Modprobe options redeployed from hardcoded values.

## Backup and Restore

### No Built-in Backup

The framework **does not backup** existing configuration before deployment.

**User responsibility**:
- Backup `/etc` before first run
- Backup `~/.config`, `~/.local` before first run
- Use version control for dotfiles

### Restore Strategy

1. **Re-run `run.sh`** — Restores all managed configuration from templates
2. **Manual restore** — Copy from backup
3. **Package reinstall** — `install-packages.sh` reinstalls all packages

## State Consistency Invariants

1. **Single writer per file** — Each target file deployed by exactly one script
2. **Content-addressed writes** — `update_file_if_distinct` prevents drift
3. **Atomic deployment per script** — Script either completes or fails; no partial state
4. **Ordering guarantees** — `run.sh` enforces phase order (repos → packages → config → system)
5. **No cross-script dependencies** — Phase scripts don't depend on each other's output
6. **Detection immutability** — Hardware/env detected once, never changes during run

## Cache Invalidation

| Cache | Invalidation Trigger | Mechanism |
|-------|---------------------|-----------|
| Package cache | `clean-packages.sh` | `paccache -ruk0`, `apt autoremove`, `apk cache clean` |
| Font cache | Font config change | `fc-cache -f` (not automated) |
| Icon cache | Icon theme change | `gtk-update-icon-cache` (not automated) |
| Desktop cache | .desktop file change | `update-desktop-database` (not automated) |
| Initramfs | Kernel/module change | `mkinitcpio`/`update-initramfs` (in `update-grub.sh`) |
| GRUB config | Entry change | `grub-mkconfig` (in `update-grub.sh`) |

## Known State Issues

1. **No transactional semantics** — Partial failure leaves system in intermediate state
2. **No rollback** — Failed deployment requires manual fix or re-run
3. **User modifications lost** — Direct edits to managed files overwritten
4. **No state verification** — No `check` mode to verify current state matches desired
5. **Cache not auto-cleaned** — Font/icon/desktop caches not invalidated on config change
6. **Service state not verified** — `enable_service` doesn't verify service actually started