# Common API Reference

This document provides API reference for common utilities in the linux-setup-script repository.

## Privilege Escalation

### run_as_su

```bash
function run_as_su() {
    local COMMAND="${*}"

    if [ "${HAS_SU_PRIVILEGES}" = 'true' ]; then
        eval "${COMMAND}"
    else
        su -c "${COMMAND}" 2>/dev/null || sudo -n eval "${COMMAND}" 2>/dev/null
    fi
}
```

**Parameters:**
- `COMMAND` (string): Command to run as root

**Returns:**
- Exit code of the command

**Example:**
```bash
run_as_su "systemctl restart myservice"
```

### run_script_as_su

```bash
function run_script_as_su() {
    local SCRIPT_PATH="${1}"

    if [ "${HAS_SU_PRIVILEGES}" = 'true' ]; then
        bash "${SCRIPT_PATH}"
    else
        su -c "bash ${SCRIPT_PATH}" 2>/dev/null || sudo -n bash "${SCRIPT_PATH}" 2>/dev/null
    fi
}
```

**Parameters:**
- `SCRIPT_PATH` (string): Path to script to run as root

**Returns:**
- Exit code of the script

**Example:**
```bash
run_script_as_su "/path/to/script.sh"
```

## Privilege Detection

### HAS_SU_PRIVILEGES

```bash
HAS_SU_PRIVILEGES='false'
sudo -n true 2>/dev/null && HAS_SU_PRIVILEGES='true'
su -c 'true' 2>/dev/null && HAS_SU_PRIVILEGES='true'
[ "${UID}" = '0' ] && HAS_SU_PRIVILEGES='true'
```

**Values:**
- `true` - Can escalate to root
- `false` - Cannot escalate to root

## Logging

### log_info

```bash
function log_info() {
    local MESSAGE="${*}"

    echo "[INFO] ${MESSAGE}"
}
```

**Parameters:**
- `MESSAGE` (string): Message to log

**Example:**
```bash
log_info "Starting configuration"
```

### log_error

```bash
function log_error() {
    local MESSAGE="${*}"

    echo "[ERROR] ${MESSAGE}" >&2
}
```

**Parameters:**
- `MESSAGE` (string): Error message to log

**Example:**
```bash
log_error "Failed to create directory"
```

### log_warning

```bash
function log_warning() {
    local MESSAGE="${*}"

    echo "[WARNING] ${MESSAGE}" >&2
}
```

**Parameters:**
- `MESSAGE` (string): Warning message to log

**Example:**
```bash
log_warning "Configuration file not found"
```

## Execution Primitives

### run_command

```bash
function run_command() {
    local COMMAND="${*}"

    eval "${COMMAND}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `COMMAND` (string): Command to execute

**Returns:**
- Exit code of the command

**Example:**
```bash
run_command "ls -la"
```

### run_script

```bash
function run_script() {
    local SCRIPT_PATH="${1}"

    bash "${SCRIPT_PATH}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `SCRIPT_PATH` (string): Path to script to execute

**Returns:**
- Exit code of the script

**Example:**
```bash
run_script "/path/to/script.sh"
```

## Guarded Sourcing

### Guard Pattern

```bash
if [ "${COMMON_SOURCED}" != 'true' ]; then
    COMMON_SOURCED='true'
    # Source common modules
fi
```

**Purpose:**
- Prevents double-sourcing of common modules
- Ensures idempotent sourcing

## Error Handling

All common functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `log_warning` for non-critical issues
- Continue on non-critical failures

## See Also

- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [components/filesystem.md](../components/filesystem.md) — Filesystem operations
- [components/system-info.md](../components/system-info.md) — Environment detection