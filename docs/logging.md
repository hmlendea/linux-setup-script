# Logging

This document describes the logging framework, log levels, formatting,
and practices in the linux-setup-script repository.

## Overview

The repository uses a structured logging system built on top of the
`common.sh` foundation module.

## Log Levels

| Level | Constant | Use Case |
|-------|----------|----------|
| DEBUG | `DEBUG=1` | Detailed diagnostic information |
| INFO | Default | General operational information |
| WARN | Default | Potential issues, non-blocking |
| ERROR | Default | Errors that block operations |
| SUCCESS | Default | Successful completion of operations |

## Log Functions

```bash
# scripts/common/common.sh

# Debug logging (only if DEBUG=1)
log_debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" >&2
    fi
}

# Info logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

# Warning logging
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Error logging
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Success logging
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Section header
log_section() {
    echo -e "\n${BOLD}${MAGENTA}=== $1 ===${NC}\n" >&2
}

# Subsection header
log_subsection() {
    echo -e "${BOLD}${CYAN}--- $1 ---${NC}" >&2
}
```

## Log Formatting

### Colour Codes

```bash
# Colour constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Colour
```

### Structured Format

```
[INFO] 2024-01-15 10:30:45 Starting system configuration
[WARN] 2024-01-15 10:30:46 GPU not detected, skipping GPU config
[ERROR] 2024-01-15 10:30:47 Failed to install docker: network timeout
[SUCCESS] 2024-01-15 10:30:48 Locale configured successfully

=== Phase 2: System Configuration ===
--- Configure Repositories ---
[INFO] Adding Arch Linux repositories
[SUCCESS] Repositories configured
```

## Logging Patterns

### 1. Phase Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

log_section "Phase 2: System Configuration"

log_subsection "Configure Repositories"
configure_repositories

log_subsection "Install Packages"
install_packages

log_subsection "Configure Services"
configure_services

log_success "Phase 2 complete"
```

### 2. Step Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

log_info "Configuring locale..."
if configure_locale; then
    log_success "Locale configured"
else
    log_error "Failed to configure locale"
    return 1
fi
```

### 3. Debug Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

# Enable debug for this script
export DEBUG=1

log_debug "Checking package: ${package}"
if is_package_installed "${package}"; then
    log_debug "Package ${package} already installed"
else
    log_info "Installing package: ${package}"
    install_package "${package}"
fi
```

### 4. Progress Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

log_section "Installing packages"

total=${#packages[@]}
current=0

for package in "${packages[@]}"; do
    ((current++))
    log_info "[${current}/${total}] Installing ${package}..."

    if install_package "${package}"; then
        log_success "[${current}/${total}] ${package} installed"
    else
        log_error "[${current}/${total}] Failed to install ${package}"
    fi
done
```

## Log Output Control

### 1. Verbosity Levels

```bash
# Verbosity levels
VERBOSE=0    # Errors only
VERBOSE=1    # Errors + warnings
VERBOSE=2    # Errors + warnings + info (default)
VERBOSE=3    # All including debug

# Filter by verbosity
should_log() {
    local level="$1"
    local level_num=0

    case "${level}" in
        ERROR) level_num=1 ;;
        WARN)  level_num=2 ;;
        INFO)  level_num=3 ;;
        DEBUG) level_num=4 ;;
    esac

    [ ${level_num} -le ${VERBOSE} ]
}
```

### 2. Quiet Mode

```bash
# Suppress all output except errors
QUIET=0

log_info() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_warn() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
}

log_success() {
    if [ "${QUIET:-0}" -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    fi
}

log_error() {
    # Always show errors
    echo -e "${RED}[ERROR]${NC} $1" >&2
}
```

### 3. Log File Output

```bash
# Optional log file
LOG_FILE="${LOG_FILE:-/var/log/linux-setup-script.log}"

log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${level}] ${timestamp} ${message}" >> "${LOG_FILE}"
}

# Wrapper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
    log_to_file "INFO" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    log_to_file "ERROR" "$1"
}
```

## Log Rotation

```bash
# Rotate log file if too large
rotate_log() {
    local max_size=10485760  # 10MB

    if [ -f "${LOG_FILE}" ] && [ $(stat -c%s "${LOG_FILE}") -gt ${max_size} ]; then
        mv "${LOG_FILE}" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S)"
        touch "${LOG_FILE}"
    fi
}
```

## Logging Invariants

1. **Consistent format** — All logs use the same format
2. **Appropriate levels** — DEBUG for diagnostics, INFO for operations, WARN for issues, ERROR for failures
3. **Actionable messages** — Logs include enough context to debug
4. **No sensitive data** — Passwords, tokens, keys never logged
5. **Performance** — Debug logging disabled by default
6. **Structured output** — Machine-parseable when needed

## Security Considerations

### 1. Secret Masking

```bash
# Mask sensitive values in logs
mask_secrets() {
    local message="$1"

    # Mask passwords
    message=$(echo "${message}" | sed 's/password=[^ ]*/password=****/g')
    message=$(echo "${message}" | sed 's/token=[^ ]*/token=****/g')
    message=$(echo "${message}" | sed 's/key=[^ ]*/key=****/g')
    message=$(echo "${message}" | sed 's/secret=[^ ]*/secret=****/g')

    echo "${message}"
}

log_info() {
    local masked=$(mask_secrets "$1")
    echo -e "${BLUE}[INFO]${NC} ${masked}" >&2
}
```

### 2. Audit Logging

```bash
# Audit log for security-relevant operations
audit_log() {
    local action="$1"
    local target="$2"
    local result="$3"
    local user="${USER:-unknown}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "AUDIT ${timestamp} user=${user} action=${action} target=${target} result=${result}" \
        >> /var/log/linux-setup-script-audit.log
}

# Usage
audit_log "package_install" "docker" "success"
audit_log "config_change" "/etc/ssh/sshd_config" "success"
audit_log "user_add" "developer" "success"
```

## Testing Logging

### Unit Tests

```bash
@test "log_info outputs to stderr" {
    run log_info "Test message"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Test message" ]]
}

@test "log_debug outputs only when DEBUG=1" {
    DEBUG=0 run log_debug "Test message"
    [ "$status" -eq 0 ]
    [ -z "${output}" ]

    DEBUG=1 run log_debug "Test message"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Test message" ]]
}

@test "log_error always outputs" {
    run log_error "Test error"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Test error" ]]
}
```

## Future Enhancements

1. **Structured logging** — JSON output for log aggregation
2. **Log levels per module** — Granular verbosity control
3. **Remote logging** — Syslog, journald, Loki integration
4. **Log correlation** — Request IDs for tracing
5. **Metrics export** — Prometheus metrics from logs
6. **Log compression** — Compress rotated logs