# Service Management API Reference

This document provides API reference for service management operations in the linux-setup-script repository.

## Service Control Functions

### enable_service

```bash
function enable_service() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        run_as_su rc-update add "${SERVICE}" default
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        run_as_su systemctl enable "${SERVICE}"
    fi
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- Exit code of enable command

**Example:**
```bash
enable_service "sshd"
```

### disable_service

```bash
function disable_service() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        run_as_su rc-update del "${SERVICE}" default
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        run_as_su systemctl disable "${SERVICE}"
    fi
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- Exit code of disable command

**Example:**
```bash
disable_service "sshd"
```

### start_service

```bash
function start_service() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        run_as_su rc-service "${SERVICE}" start
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        run_as_su systemctl start "${SERVICE}"
    fi
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- Exit code of start command

**Example:**
```bash
start_service "sshd"
```

### stop_service

```bash
function stop_service() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        run_as_su rc-service "${SERVICE}" stop
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        run_as_su systemctl stop "${SERVICE}"
    fi
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- Exit code of stop command

**Example:**
```bash
stop_service "sshd"
```

### restart_service

```bash
function restart_service() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        run_as_su rc-service "${SERVICE}" restart
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        run_as_su systemctl restart "${SERVICE}"
    fi
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- Exit code of restart command

**Example:**
```bash
restart_service "sshd"
```

### is_service_enabled

```bash
function is_service_enabled() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        rc-update show default | grep -q "^${SERVICE}$"
        return $?
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        systemctl is-enabled "${SERVICE}" >/dev/null 2>&1
        return $?
    fi

    return 1
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- `0` if service is enabled
- `1` if service is not enabled

**Example:**
```bash
if is_service_enabled "sshd"; then
    echo "sshd is enabled"
fi
```

### is_service_active

```bash
function is_service_active() {
    local SERVICE="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        rc-service "${SERVICE}" status | grep -q "started"
        return $?
    elif [ "${DISTRO_FAMILY}" = 'Arch' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        systemctl is-active "${SERVICE}" >/dev/null 2>&1
        return $?
    fi

    return 1
}
```

**Parameters:**
- `SERVICE` (string): Service name

**Returns:**
- `0` if service is active
- `1` if service is not active

**Example:**
```bash
if is_service_active "sshd"; then
    echo "sshd is active"
fi
```

## User Service Control

### enable_user_service

```bash
function enable_user_service() {
    local SERVICE="${1}"

    systemctl --user enable "${SERVICE}"
}
```

**Parameters:**
- `SERVICE` (string): User service name

**Returns:**
- Exit code of enable command

**Example:**
```bash
enable_user_service "pipewire"
```

### disable_user_service

```bash
function disable_user_service() {
    local SERVICE="${1}"

    systemctl --user disable "${SERVICE}"
}
```

**Parameters:**
- `SERVICE` (string): User service name

**Returns:**
- Exit code of disable command

**Example:**
```bash
disable_user_service "pipewire"
```

### start_user_service

```bash
function start_user_service() {
    local SERVICE="${1}"

    systemctl --user start "${SERVICE}"
}
```

**Parameters:**
- `SERVICE` (string): User service name

**Returns:**
- Exit code of start command

**Example:**
```bash
start_user_service "pipewire"
```

### stop_user_service

```bash
function stop_user_service() {
    local SERVICE="${1}"

    systemctl --user stop "${SERVICE}"
}
```

**Parameters:**
- `SERVICE` (string): User service name

**Returns:**
- Exit code of stop command

**Example:**
```bash
stop_user_service "pipewire"
```

## Error Handling

All service management functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `is_service_enabled` and `is_service_active` for checks
- Handle permission errors gracefully

## See Also

- [components/service-management.md](../components/service-management.md) — Service management details
- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [flows/system-configuration.md](../flows/system-configuration.md) — System configuration flow