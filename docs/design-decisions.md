# Design Decisions

This document records key architectural and design choices with their rationale.

## 1. Bash as Implementation Language

**Decision**: All scripts written in Bash (not Python, Ansible, etc.)

**Rationale**:
- Universal availability on all target platforms (including minimal Alpine, Android/Termux)
- No runtime dependencies beyond standard POSIX utilities
- Direct system interaction (file ops, process management, privilege escalation) is idiomatic
- Easy to debug and modify on target machines without development toolchain
- `run.sh` can execute on fresh install with only `bash` package

**Trade-offs**:
- Complex data structures require workarounds (associative arrays in Bash 4+)
- Error handling more verbose than exceptions
- No static analysis/type checking

## 2. Monolithic Orchestrator (`run.sh`) vs Modular Tools

**Decision**: Single `run.sh` orchestrates all phases in strict sequence

**Rationale**:
- Guarantees correct dependency ordering (repos → packages → config → system)
- Single entry point for users; no need to remember script sequence
- Atomic "full provisioning" operation; partial runs via individual scripts
- Failure isolation: individual script failures don't halt `run.sh` (no `set -e`)

**Trade-offs**:
- Long execution time for full run (~10-30 minutes)
- Harder to parallelise independent operations
- All-or-nothing perception (though individual scripts are runnable)

## 3. Privilege Separation: Explicit `run_script` vs `run_script_as_su`

**Decision**: Every script execution explicitly chooses user or root context via
`run_script` / `run_script_as_su` helpers

**Rationale**:
- Clear audit trail: `Executing as root: '/path/to/script.sh'...`
- No ambient authority; each script declares its privilege needs
- `run_script_as_su` returns immediately if `HAS_SU_PRIVILEGES=false`
- Works uniformly across sudo (Linux) and su (Android/Termux)

**Trade-offs**:
- Scripts must be designed for specific privilege level
- Some scripts run twice (user + root) with different operations
- Root context loses user environment (HOME, XDG vars) — mitigated by `HOME_REAL`

## 4. Platform Abstraction via `DISTRO_FAMILY` and `OS`

**Decision**: All platform-specific logic branches on `DISTRO_FAMILY` (Arch, Debian,
Ubuntu, Alpine, Android) and `OS` (Linux, Android, Windows/WSL)

**Rationale**:
- Single codebase supports 8+ platforms
- Package manager dispatch centralised in `call_package_manager`
- GUI operations guarded by `HAS_GUI` and `IS_WAYLAND`/`IS_X11`
- Android/Termux gets early-exit for system-level config

**Trade-offs**:
- Large `case`/`if` blocks in package/config scripts
- Platform-specific bugs require testing on each target
- New platforms require updates across multiple scripts

## 5. Idempotency via Content Comparison (`update_file_if_distinct`)

**Decision**: All file deployments use `update_file_if_distinct(src, dst)` which
only writes if content differs

**Rationale**:
- Safe to re-run `run.sh` multiple times
- Preserves file metadata (timestamps, permissions) on no-op
- Avoids unnecessary systemd reloads, service restarts
- Works for both user and root deployments

**Implementation**:
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

**Trade-offs**:
- Requires source templates to be canonical (no runtime templating)
- Binary files need `update_file_if_binary_exists` guard
- Content comparison adds I/O overhead (negligible for config files)

## 6. Declarative Configuration Templates

**Decision**: Target state described in static files under `rc/`, `resources/`,
`profiles/` — deployed verbatim (with `update_file_if_distinct`)

**Rationale**:
- Configuration is visible, reviewable, version-controlled
- No runtime templating logic to debug
- Easy to diff against target system
- Supports platform-specific variants (e.g., `home` vs `home-ro`)

**Trade-offs**:
- No variable interpolation in templates (e.g., `${USER}` not expanded)
- Platform-specific variants multiply files
- Large templates (e.g., `configure-launchers.sh` with 100+ .desktop mods) are
  imperative, not declarative

## 7. Hardware Detection at Source Time (`system-info.sh`)

**Decision**: All hardware/environment detection runs once when `system-info.sh`
is sourced; results exported as global variables

**Rationale**:
- Single source of truth for device properties
- Avoids repeated expensive detection (dmidecode, lspci, wayland-info)
- Enables compile-time-like conditional logic in scripts
- Exported variables (`DEVICE_MODEL`, `GPU_FAMILY`, `CHASSIS_TYPE`) used
  throughout

**Trade-offs**:
- Detection runs even for scripts that don't need it
- Stale detection if hardware changes mid-session (rare)
- Global namespace pollution (mitigated by naming convention `IS_*`, `HAS_*`)

## 8. Package Manager Abstraction Layer

**Decision**: `call_package_manager` dispatches to native manager + AUR helper +
Flatpak + Cargo + GitHub releases + VS Code extensions + GNOME extensions

**Rationale**:
- Unified interface: `install_native_package`, `install_flatpak`, etc.
- Platform-specific logic isolated in one module
- Supports "install if not present" semantics via `is_package_installed`
- AUR helper preference order: paru → yay → yaourt → pacman

**Trade-offs**:
- Abstraction leaks: some operations only work on specific managers
- Flatpak/Cargo/GitHub/VS Code/GNOME are orthogonal, not unified
- Version pinning not supported (always latest)

## 9. Configuration File Manipulation via `config.sh`

**Decision**: Generic `get_config_value`/`set_config_value` supporting INI, JSON,
XML, GSettings, modprobe, PulseAudio

**Rationale**:
- Single module handles all config file formats
- `set_ini_config_value` handles sectioned INI (systemd, GRUB, desktop files)
- `set_modprobe_option` generates `/etc/modprobe.d/*.conf` entries
- `call_gsettings`/`set_gsetting` for GNOME/KDE/MATE/Phosh

**Trade-offs**:
- JSON/XML manipulation uses `jq`/`sed` fallbacks (fragile)
- No schema validation
- GSettings requires running session (`has_gsettings_session` guard)

## 10. Theme and Font Resolution in `configure-system.sh`

**Decision**: Theme variant (dark/light) and font sizes computed at runtime based
on `get_theme()`, `get_theme_mode()`, screen resolution, and DPI

**Rationale**:
- Adapts to device capabilities (Steam Deck 800p vs 4K monitor)
- DPI-aware font sizing prevents tiny/unreadable text
- Single source for GTK2/3/4, GNOME, terminal, editor fonts
- Papirus icon colourisation automated (grey folders)

**Trade-offs**:
- Complex derivation logic (100+ lines in `configure-system.sh`)
- Hard to test all resolution/DPI combinations
- Theme name normalisation brittle (string replacement)

## 11. GRUB Multi-Boot via Template Deployment

**Decision**: GRUB entries deployed as `/etc/grub.d/` templates (25_windows,
29_android, etc.) with OS root detection

**Rationale**:
- Standard GRUB mechanism; survives `grub-mkconfig` regeneration
- Priority ordering via numeric prefixes (25, 29, 99)
- OS detection at deploy time (checks for `/Windows/System32`, `/system/build.prop`)
- Post-generation cleanup (rename "Windows Boot Manager" → "Windows")

**Trade-offs**:
- Requires `grub-mkconfig` (not available on all distros)
- Template logic duplicates OS detection
- Android variants (Bliss, Phoenix, Prime) need separate templates

## 12. Android/Termux as First-Class Platform

**Decision**: Full support for Android/Termux with platform guards throughout

**Rationale**:
- Personal use case: phone/tablet development environment
- Path mapping: `/etc` → `$PREFIX/etc`, `/usr` → `$PREFIX`, etc.
- `pkg` package manager integrated in abstraction layer
- Early exit for system config (no systemd, GRUB, kernel params)

**Trade-offs**:
- Significant code paths skipped via `if [ "$IS_ANDROID" = "true" ]`
- No GUI support (Wayland/X11 not available in Termux)
- Flatpak, GNOME extensions, udev, sysctl not applicable

## 13. SteamOS / Immutable Distro Adaptations

**Decision**: Special handling for SteamOS (read-only rootfs, no AUR, Flatpak preferred)

**Rationale**:
- Steam Deck is a target device
- rpm-ostree for base layer, Flatpak for apps
- User-level configs only (`~/.config`, `~/.local`)
- No `/etc` mutation

**Trade-offs**:
- Divergent code paths for immutable vs mutable
- `configure-repositories.sh` has rpm-ostree logic
- Package installation uses `rpm-ostree install` + Flatpak

## 14. No Build Pipeline / Direct Execution

**Decision**: Scripts executed directly; no compilation, packaging, or CI/CD

**Rationale**:
- Bash scripts are source = artifact
- Provisioning runs on target machine, not build server
- Version control is the deployment mechanism
- Zero infrastructure required

**Trade-offs**:
- No automated testing (manual verification only)
- No linting/formatting enforcement (shellcheck not integrated)
- Syntax errors only caught at runtime

## 15. Logging via `echo` / `printf` (No Structured Logging)

**Decision**: Simple `echo` statements for progress; no log levels, JSON, or
correlation IDs

**Rationale**:
- Human-readable output for interactive runs
- No logging framework dependency
- `run.sh` output serves as execution log
- Errors visible in terminal

**Trade-offs**:
- No machine-parseable logs
- No log levels (debug/info/warn/error)
- No correlation across script invocations
- No retention/rotation

## 16. Flatpak/GNOME Permission Management

**Decision**: `permissions.sh` manages both Flatpak permissions (via `flatpak
permission-set`) and GNOME portal permissions (via `gsettings`)

**Rationale**:
- Flatpak permissions control sandbox access
- GNOME portal permissions control desktop integration (notifications, location)
- Unified `set_linux_permission(app, permission, state)` API
- PulseAudio socket logic: enable if mic OR speakers granted

**Trade-offs**:
- Two separate permission systems with different schemas
- GNOME permissions require running GNOME session
- Flatpak permissions require Flatpak installed
- Application list hardcoded in `configure-permissions.sh`

## 17. Service Management Abstraction (systemd + OpenRC)

**Decision**: `service-management.sh` provides unified `enable_service`,
`disable_service`, `mask_user_service` for systemd and OpenRC

**Rationale**:
- Alpine uses OpenRC; other distros use systemd
- Same API for both init systems
- User services (systemd --user) handled separately

**Trade-offs**:
- OpenRC support limited (no masking, no user services)
- `does_service_exist` checks multiple paths
- No support for other init systems (runit, s6, dinit)

## 18. Firefox Profile Detection Heuristics

**Decision**: `apps.sh` searches multiple locations for Firefox/LibreWolf profiles
(Flatpak, native, custom paths)

**Rationale**:
- Firefox can be installed via distro package, Flatpak, or manual
- LibreWolf (fork) has different paths
- Profile ID extracted from `profiles.ini`
- Falls back gracefully if no profile found

**Trade-offs**:
- Heuristic-based; may miss custom installations
- Only detects default profile
- Flatpak paths hardcoded (may change with Flatpak version)

## 19. udev Rules for Power Management

**Decision**: udev rules deployed for WiFi, USB, PCI, I/O scheduler power
management (battery devices only)

**Rationale**:
- Kernel-level power management; no userspace daemon needed
- Persistent across reboots
- Conditional deployment: `wifi_powersave` and `usb_powersave` only on laptops
- I/O scheduler: BFQ for HDD, none for NVMe/SSD

**Trade-offs**:
- Requires root; deployed via `update-resources.sh` (root context)
- Rules may conflict with TLP/thermald
- No runtime toggling (requires rule modification + reload)

## 20. Git Hooks as Resources

**Decision**: Git hooks (`post-checkout`, `prepare-commit-msg`) deployed as
resources to `~/.config/git/hooks/`

**Rationale**:
- Centralised hook management
- `post-checkout` updates submodules, regenerates build files
- `prepare-commit-msg` adds branch name, issue references
- Deployed via `update-resources.sh` with `chmod +x`

**Trade-offs**:
- Requires `core.hooksPath` in Git config (set in `rc/gitconfig`)
- Hooks run in repository context, not global
- No versioning of hooks per repository