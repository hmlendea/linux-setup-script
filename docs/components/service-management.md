# Service Management Component

This document provides a deep dive into the service management component,
which abstracts service and daemon management across systemd, OpenRC,
and SysV init systems.

## Overview

**Location**: `scripts/common/service-management.sh`

**Purpose**: Unified service management interface supporting `systemd`,
`OpenRC`, and `SysV init` service managers.

**Consumers**: `configure-services-system.sh`, `configure-services-user.sh`,
`configure-hardware-integration.sh`, `configure-autostart-apps.sh`

## Core Functions

### 1. Service Manager Detection

```bash
# Detect available service manager
detect_service_manager
# Sets: SERVICE_MANAGER, SERVICE_MANAGER_START, SERVICE_MANAGER_STOP,
#       SERVICE_MANAGER_ENABLE, SERVICE_MANAGER_DISABLE,
#       SERVICE_MANAGER_STATUS, SERVICE_MANAGER_RESTART

# Check if a service is enabled
is_service_enabled <service_name>

# Check if a service is running
is_service_running <service_name>
```

### 2. Service Operations

```bash
# Start a service
start_service <service_name>

# Stop a service
stop_service <service_name>

# Restart a service
restart_service <service_name>

# Reload a service
reload_service <service_name>

# Enable a service (start on boot)
enable_service <service_name>

# Disable a service (don't start on boot)
disable_service <service_name>

# Enable and start a service
enable_and_start_service <service_name>

# Disable and stop a service
disable_and_stop_service <service_name>
```

### 3. Service Status

```bash
# Get service status
get_service_status <service_name>
# Returns: "running", "stopped", "enabled", "disabled", "failed"

# Check if service is active
is_service_active <service_name>

# Check if service is failed
is_service_failed <service_name>
```

### 4. User Services

```bash
# Start a user service
start_user_service <service_name>

# Stop a user service
stop_user_service <service_name>

# Enable a user service
enable_user_service <service_name>

# Disable a user service
disable_user_service <service_name>

# Enable and start a user service
enable_and_start_user_service <service_name>
```

### 5. Service File Management

```bash
# Install a systemd service file
install_systemd_service <service_file> <destination>

# Install a systemd user service file
install_systemd_user_service <service_file> <destination>

# Install an OpenRC service file
install_openrc_service <service_file> <destination>

# Install a SysV init script
install_init_script <script_file> <destination>

# Remove a service file
remove_service_file <service_name>
```

## Supported Service Managers

### Systemd (Linux)

```bash
SERVICE_MANAGER="systemd"
SERVICE_MANAGER_START="systemctl start"
SERVICE_MANAGER_STOP="systemctl stop"
SERVICE_MANAGER_ENABLE="systemctl enable"
SERVICE_MANAGER_DISABLE="systemctl disable"
SERVICE_MANAGER_STATUS="systemctl status"
SERVICE_MANAGER_RESTART="systemctl restart"
```

### OpenRC (Alpine Linux)

```bash
SERVICE_MANAGER="openrc"
SERVICE_MANAGER_START="rc-service start"
SERVICE_MANAGER_STOP="rc-service stop"
SERVICE_MANAGER_ENABLE="rc-update add"
SERVICE_MANAGER_DISABLE="rc-update del"
SERVICE_MANAGER_STATUS="rc-service status"
SERVICE_MANAGER_RESTART="rc-service restart"
```

### SysV Init (Legacy)

```bash
SERVICE_MANAGER="sysvinit"
SERVICE_MANAGER_START="service start"
SERVICE_MANAGER_STOP="service stop"
SERVICE_MANAGER_ENABLE="update-rc.d enable"
SERVICE_MANAGER_DISABLE="update-rc.d disable"
SERVICE_MANAGER_STATUS="service status"
SERVICE_MANAGER_RESTART="service restart"
```

## Service Management Patterns

### Pattern 1: System Services

```bash
#!/bin/bash
source "scripts/common/service-management.sh"

# Enable and start system services
enable_and_start_service "NetworkManager"
enable_and_start_service "lightdm"
enable_and_start_service "bluetooth"
enable_and_start_service "cups"
enable_and_start_service "pipewire"
enable_and_start_service "pipewire-pulse"
enable_and_start_service "pipewire-jack"
enable_and_start_service "fstrim.timer"
enable_and_start_service "logrotate.timer"
enable_and_start_service "man-db.timer"
enable_and_start_service "pkgfile-update.timer"
enable_and_start_service "reflector.timer"
enable_and_start_service "systemd-tmpfiles-clean.timer"
enable_and_start_service "systemd-update-calamares.timer"
```

### Pattern 2: User Services

```bash
#!/bin/bash
source "scripts/common/service-management.sh"

# Enable and start user services
enable_and_start_user_service "pipewire"
enable_and_start_user_service "pipewire-pulse"
enable_and_start_user_service "xdg-desktop-portal"
enable_and_start_user_service "xdg-desktop-portal-wlr"
enable_and_start_user_service "polkit-gnome-authentication-agent-1"
```

### Pattern 3: Service File Installation

```bash
#!/bin/bash
source "scripts/common/service-management.sh"
source "scripts/common/filesystem.sh"

# Install custom systemd service
install_systemd_service \
    "${REPO_DIR}/resources/systemd/my-service.service" \
    "/etc/systemd/system/my-service.service"

# Reload systemd daemon
systemctl daemon-reload

# Enable and start
enable_and_start_service "my-service"
```

### Pattern 4: Service Cleanup

```bash
#!/bin/bash
source "scripts/common/service-management.sh"

# Disable and stop services
disable_and_stop_service "cups"
disable_and_stop_service "bluetooth"
disable_and_stop_service "avahi-daemon"
disable_and_stop_service "ModemManager"
```

## Service Management Invariants

1. **Idempotency** — `is_service_enabled` / `is_service_running` checks before operations
2. **Platform abstraction** — Same interface across all service managers
3. **Privilege separation** — System services via `run_as_su`, user services directly
4. **Error propagation** — Failures in service ops are reported
5. **Graceful degradation** — Falls back to available service manager
6. **Service file management** — Standardised installation/removal

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `start_service` | Service not found | Error message, returns 1 |
| `start_service` | Permission denied | Error message, returns 1 |
| `enable_service` | Service not found | Error message, returns 1 |
| `is_service_enabled` | Service not found | Returns 1 |
| `is_service_running` | Service not found | Returns 1 |
| `detect_service_manager` | No service manager | Error, exits |

## Performance Considerations

- **Batch operations** — Enable/start multiple services in one call
- **Status caching** — Service status cached during session
- **Parallel operations** — Independent services can be managed in parallel
- **Skip enabled** — `is_service_enabled` check avoids redundant work

## Security Considerations

- **Privilege separation** — System services via `run_as_su`
- **Service file validation** — Service files validated before installation
- **No arbitrary code** — Service management is declarative
- **User vs system** — Clear separation between user and system services

## Testing

### Unit Tests

```bash
function test_is_service_enabled() {
    # Test with known enabled service
    assertTrue "NetworkManager is enabled" "is_service_enabled NetworkManager"

    # Test with known disabled service
    assertFalse "fake-service is not enabled" "is_service_enabled fake-service-12345"
}

function test_start_service() {
    # Test starting a service
    start_service "NetworkManager"
    assertTrue "NetworkManager started successfully" "is_service_running NetworkManager"
}
```

### Integration Tests

```bash
function test_service_manager_detection() {
    detect_service_manager
    assertNotNull "SERVICE_MANAGER is set" "${SERVICE_MANAGER}"
    assertTrue "SERVICE_MANAGER_START is set" "[ -n '${SERVICE_MANAGER_START}' ]"
    assertTrue "SERVICE_MANAGER_ENABLE is set" "[ -n '${SERVICE_MANAGER_ENABLE}' ]"
}
```

## Future Enhancements

1. **Service dependencies** — Manage service dependencies programmatically
2. **Service templates** — Support systemd template units
3. **Service timers** — Manage systemd timers
4. **Service sockets** — Manage systemd socket activation
5. **Service logs** — Access service logs via journalctl
6. **Service masking** — Mask/unmask services
7. **Service presets** — Apply systemd presets