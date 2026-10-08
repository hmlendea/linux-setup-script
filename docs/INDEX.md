# Linux Setup Script — Documentation Index

This directory contains the comprehensive technical documentation for the
`linux-setup-script` repository. The documentation is intended to serve as a
persistent knowledge base for future coding agents, eliminating the need to
repeatedly reverse-engineer the repository from source.

## Root Document Map

| Document | Location | Purpose |
|----------|----------|---------|
| ARCHITECTURE.md | Repository root | High-level architecture (not present) |
| SECURITY.md | Repository root | Security model and threat mitigations (not present) |
| ROADMAP.md | Repository root | Future development plans (not present) |
| PRIVACY.md | Repository root | Data handling and privacy (not present) |
| LICENSE | Repository root | License terms (not present) |

## Documentation Catalogue

### Core Architecture

| File | Description |
|------|-------------|
| [architecture.md](./architecture.md) | High-level architecture, component relationships, dependency direction |
| [repository-overview.md](./repository-overview.md) | Repository purpose, scope, supported platforms, entry points |
| [repository-structure.md](./repository-structure.md) | Source tree layout, module organisation, naming conventions |
| [design-decisions.md](./design-decisions.md) | Key architectural/design choices and rationale |
| [dependencies.md](./dependencies.md) | External and internal dependencies |

### Configuration & Data

| File | Description |
|------|-------------|
| [configuration.md](./configuration.md) | Configuration schema, sources, precedence, derivation |
| [data-model.md](./data-model.md) | Domain entities, relationships, persistence |
| [state-and-persistence.md](./state-and-persistence.md) | State management, stores, caches, migrations |

### Components

| File | Description |
|------|-------------|
| [components/foundation-layer.md](./components/foundation-layer.md) | Core utilities: filesystem, execution, system-info, package management |
| [components/configuration-management.md](./components/configuration-management.md) | Config file manipulation (INI, JSON, XML, GSettings, modprobe) |
| [components/package-management.md](./components/package-management.md) | Unified package manager abstraction layer |
| [components/service-management.md](./components/service-management.md) | systemd/OpenRC service control |
| [components/permission-management.md](./components/permission-management.md) | Flatpak/GNOME/Android permission management |
| [components/hardware-integration.md](./components/hardware-integration.md) | Device-specific hardware setup (Argon ONE UP, GPU, laptop power) |

### Execution Flows

| File | Description |
|------|-------------|
| [flows/startup-and-provisioning.md](./flows/startup-and-provisioning.md) | Complete run.sh execution flow from entry to completion |
| [flows/package-management.md](./flows/package-management.md) | Repository config, package install/update/cleanup flow |
| [flows/configuration-deployment.md](./flows/configuration-deployment.md) | RC files, resources, profiles deployment flow |
| [flows/system-configuration.md](./flows/system-configuration.md) | Kernel, sysctl, modprobe, GRUB, GNOME configuration flow |
| [flows/git-setup.md](./flows/git-setup.md) | GPG/SSH key generation and Git configuration flow |

### Behaviours

| File | Description |
|------|-------------|
| [behaviour/theme-and-font-resolution.md](./behaviour/theme-and-font-resolution.md) | Theme variant, font sizing, DPI/resolution adaptation |
| [behaviour/desktop-environment-configuration.md](./behaviour/desktop-environment-configuration.md) | GNOME, KDE, MATE, LXDE, Phosh specific configurations |
| [behaviour/application-launcher-customisation.md](./behaviour/application-launcher-customisation.md) | .desktop file modifications for 100+ applications |
| [behaviour/autostart-and-default-apps.md](./behaviour/autostart-and-default-apps.md) | User autostart entries and mimeapps.list associations |
| [behaviour/directory-and-file-management.md](./behaviour/directory-and-file-management.md) | XDG directories, hidden files, symlinks, templates |

### Integrations

| File | Description |
|------|-------------|
| [integrations/package-managers.md](./integrations/package-managers.md) | pacman, apt, apk, pkg, Flatpak, Cargo, GitHub releases |
| [integrations/display-servers.md](./integrations/display-servers.md) | Wayland, X11, tty detection and adaptation |
| [integrations/desktop-environments.md](./integrations/desktop-environments.md) | GNOME, KDE, MATE, LXDE, Phosh integrations |
| [integrations/hardware.md](./integrations/hardware.md) | Argon ONE UP, GPU, laptop power, audio, WiFi |
| [integrations/bootloader.md](./integrations/bootloader.md) | GRUB multi-boot entries, mkinitcpio |
| [integrations/platforms.md](./integrations/platforms.md) | Android/Termux, SteamOS, WSL, immutable distros |

### Cross-Cutting Concerns

| File | Description |
|------|-------------|
| [testing.md](./testing.md) | Test strategy, organisation, coverage (manual verification) |
| [concurrency-and-scheduling.md](./concurrency-and-scheduling.md) | Sequential execution, privilege separation, no parallelism |
| [error-handling.md](./error-handling.md) | Error taxonomy, handling patterns, failure isolation |
| [logging.md](./logging.md) | Logging framework, levels, structured fields, sinks |
| [invariants.md](./invariants.md) | System-wide invariants and contracts |
| [build-and-deployment.md](./build-and-deployment.md) | No build pipeline; direct script execution |
| [security.md](./security.md) | Privilege escalation, SSH/GPG, Flatpak permissions, hardening |
| [ambiguities-and-open-questions.md](./ambiguities-and-open-questions.md) | Unresolved items, TODOs, known gaps |
| [change-guide.md](./change-guide.md) | How to modify common areas safely |
| [documentation-maintenance.md](./documentation-maintenance.md) | How to keep docs current, ownership |

## Navigation Aids

### Start Here (Newcomers)
1. [repository-overview.md](./repository-overview.md) — Understand what this repository does
2. [architecture.md](./architecture.md) — Understand the high-level structure
3. [flows/startup-and-provisioning.md](./flows/startup-and-provisioning.md) — Understand the main execution flow

### Deep Dive (Component Owners)
- [components/foundation-layer.md](./components/foundation-layer.md) — Core utilities
- [components/package-management.md](./components/package-management.md) — Package abstraction
- [components/configuration-management.md](./components/configuration-management.md) — Config manipulation
- [integrations/desktop-environments.md](./integrations/desktop-environments.md) — DE-specific logic

### Flows (Debuggers)
- [flows/startup-and-provisioning.md](./flows/startup-and-provisioning.md) — Full provisioning flow
- [flows/package-management.md](./flows/package-management.md) — Package operations
- [flows/system-configuration.md](./flows/system-configuration.md) — System-level config

## Maintenance Metadata

- **Last reviewed**: 2026-10-08
- **Owner**: Repository maintainer
- **Coverage status**: Comprehensive — all scripts, modules, resources, and integrations documented
- **Source of truth**: This documentation derived from exhaustive reverse-engineering of source code