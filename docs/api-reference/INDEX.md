# API Reference Index

This directory contains API reference documentation for the linux-setup-script
repository.

## Overview

The API reference provides detailed documentation for all public interfaces,
functions, and data structures exposed by the linux-setup-script framework.

## Documentation Catalogue

### Foundation Layer APIs

| File | Description |
|------|-------------|
| [filesystem.md](./filesystem.md) | Path resolution, file operations, directory management |
| [common.md](./common.md) | Execution primitives, privilege escalation, logging |
| [system-info.md](./system-info.md) | Platform detection, environment variables |
| [package-management.md](./package-management.md) | Package manager abstraction, operations |
| [config.md](./config.md) | Configuration file manipulation |
| [service-management.md](./service-management.md) | Service control, systemd/OpenRC |
| [apps.md](./apps.md) | Application management, installation |
| [github.md](./github.md) | GitHub integration, releases, CLI |

### Script APIs

| File | Description |
|------|-------------|
| [configure-system.md](./configure-system.md) | System configuration functions |
| [configure-locale.md](./configure-locale.md) | Locale configuration |
| [configure-time.md](./configure-time.md) | Time and timezone configuration |
| [configure-repositories.md](./configure-repositories.md) | Repository configuration |
| [install-packages.md](./install-packages.md) | Package installation |
| [update-rcs.md](./update-rcs.md) | RC file deployment |
| [update-resources.md](./update-resources.md) | Resource deployment |
| [update-profiles.md](./update-profiles.md) | Profile script deployment |
| [configure-launchers.md](./configure-launchers.md) | Desktop launcher modification |
| [configure-autostart-apps.md](./configure-autostart-apps.md) | Autostart configuration |
| [configure-default-apps.md](./configure-default-apps.md) | Default application configuration |
| [configure-directories.md](./configure-directories.md) | Directory configuration |
| [configure-services-system.md](./configure-services-system.md) | System service configuration |
| [configure-services-user.md](./configure-services-user.md) | User service configuration |
| [configure-hardware-integration.md](./configure-hardware-integration.md) | Hardware configuration |
| [update-grub.md](./update-grub.md) | GRUB configuration |
| [configure-permissions.md](./configure-permissions.md) | Permission management |

## Usage Patterns

### Foundation Layer Usage

```bash
# Source foundation modules
source "${REPO_DIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
```

### Privilege Escalation

```bash
# Run as root (via sudo/su)
run_as_su command

# Run script as root
run_script_as_su /path/to/script.sh
```

### File Operations

```bash
# Update file if content differs
update_file_if_distinct "${source}" "${target}"

# Ensure directory exists
ensure_directory "${dir}"
```

### Package Operations

```bash
# Install package
install_package "package-name"

# Check if package installed
is_package_installed "package-name"

# Update package manager
call_package_manager update
```

## Data Structures

### Environment Variables

| Variable | Type | Description |
|----------|------|-------------|
| `REPO_DIR` | string | Absolute path to repository root |
| `DISTRO_FAMILY` | string | Arch, Debian, Ubuntu, Alpine, Android |
| `HAS_SU_PRIVILEGES` | boolean | true if can escalate to root |
| `RUN_AS_SU` | string | Command prefix for root operations |
| `DESKTOP_ENVIRONMENT` | string | GNOME, KDE, MATE, LXDE, Phosh |
| `HAS_GUI` | boolean | true if graphical environment |
| `GTK_THEME` | string | Current GTK theme name |
| `GTK_THEME_VARIANT` | string | dark or light |

## Error Handling

All APIs follow consistent error handling patterns:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `assert_*` functions for validation
- Continue on non-critical failures

## See Also

- [](../architecture.md) — High-level architecture
- [](../flows/startup-and-provisioning.md) — Main execution flow
- [](../components/foundation-layer.md) — Foundation layer details