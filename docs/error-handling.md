# Error Handling

This document describes the error handling strategies, patterns, and practices
in the linux-setup-script repository.

## Overview

The repository uses a layered error handling approach with consistent patterns
across all scripts and modules.

## Error Handling Layers

### 1. Foundation Layer (common.sh)

```bash
# scripts/common/common.sh

# Fatal error - exit immediately
die() {
    log_error "$1"
    exit 1
}

# Assert condition - die if false
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"

    if ! eval "${condition}"; then
        die "${message}"
    fi
}

# Check command exists
assert_command() {
    local cmd="$1"
    local message="${2:-Command not found: ${cmd}}"

    if ! command_exists "${cmd}"; then
        die "${message}"
    fi
}

# Check file exists
assert_file() {
    local path="$1"
    local message="${2:-File not found: ${path}}"

    if [ ! -f "${path}" ]; then
        die "${message}"
    fi
}

# Check directory exists
assert_directory() {
    local path="$1"
    local message="${2:-Directory not found: ${path}}"

    if [ ! -d "${path}" ]; then
        die "${message}"
    fi
}
```

### 2. Module Layer (config.sh, package-management.sh, etc.)

```bash
# scripts/common/config.sh

# Return codes:
# 0 = success
# 1 = general error
# 2 = file not found / permission denied
# 3 = invalid arguments

update_file_if_distinct() {
    local src="$1"
    local dst="$2"

    # Validate arguments
    if [ $# -ne 2 ]; then
        log_error "update_file_if_distinct requires 2 arguments"
        return 3
    fi

    # Check source exists
    if [ ! -f "${src}" ]; then
        log_error "Source file not found: ${src}"
        return 2
    fi

    # Check destination directory exists
    local dst_dir=$(dirname "${dst}")
    if [ ! -d "${dst_dir}" ]; then
        log_error "Destination directory not found: ${dst_dir}"
        return 2
    fi

    # Compare and update
    if cmp -s "${src}" "${dst}" 2>/dev/null; then
        return 1  # Unchanged
    fi

    if ! cp "${src}" "${dst}"; then
        log_error "Failed to copy ${src} to ${dst}"
        return 2
    fi

    return 0  # Updated
}
```

### 3. Script Layer (configure-system.sh, etc.)

```bash
# scripts/configure-system.sh

# Script-level error handling
main() {
    # Setup error handling
    set -euo pipefail
    trap 'handle_error $? $LINENO' ERR

    # Run configuration steps
    configure_locale
    configure_time
    configure_grub
    configure_sysctl
    configure_systemd
}

handle_error() {
    local exit_code=$1
    local line_number=$2

    log_error "Error in ${BASH_SOURCE[0]} at line ${line_number}: exit code ${exit_code}"

    # Attempt recovery
    case "${exit_code}" in
        1)
            log_warn "General error, continuing..."
            ;;
        2)
            log_warn "File/permission error, skipping..."
            ;;
        124)
            log_warn "Timeout, skipping..."
            ;;
        *)
            log_error "Fatal error, aborting"
            exit "${exit_code}"
            ;;
    esac
}
```

## Error Handling Patterns

### 1. Guard Clauses

```bash
# Early validation
function configure_gpu() {
    # Guard: only run if GPU detected
    if [ -z "${GPU_FAMILY}" ]; then
        log_debug "No GPU detected, skipping GPU configuration"
        return 0
    fi

    # Guard: only run if module exists
    if ! module_exists "i915" && [ "${GPU_FAMILY}" = "intel" ]; then
        log_warn "i915 module not available, skipping Intel GPU config"
        return 0
    fi

    # Actual configuration
    set_modprobe_option "i915" "enable_guc" "3"
}
```

### 2. Try-Catch Pattern

```bash
# Bash doesn't have try-catch, but we can simulate
try() {
    "$@"
    return $?
}

catch() {
    local exit_code=$?
    if [ ${exit_code} -ne 0 ]; then
        "$@"
        return $?
    fi
    return 0
}

# Usage
try install_package "docker" || catch log_warn "Docker installation failed, continuing"
```

### 3. Retry Pattern

```bash
# Retry with exponential backoff
retry() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local command=("$@")

    local attempt=1
    while [ ${attempt} -le ${max_attempts} ]; do
        if "${command[@]}"; then
            return 0
        fi

        log_warn "Attempt ${attempt}/${max_attempts} failed: ${command[*]}"

        if [ ${attempt} -lt ${max_attempts} ]; then
            sleep ${delay}
            delay=$((delay * 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    log_error "All ${max_attempts} attempts failed: ${command[*]}"
    return 1
}

# Usage
retry 3 2 install_package "docker"
```

### 4. Circuit Breaker Pattern

```bash
# Prevent repeated failures
declare -A FAILURE_COUNT=()
declare -A LAST_FAILURE=()

circuit_breaker() {
    local operation="$1"
    shift
    local command=("$@")

    local max_failures=3
    local reset_timeout=300  # 5 minutes

    local now=$(date +%s)
    local failures=${FAILURE_COUNT[${operation}]:-0}
    local last_failure=${LAST_FAILURE[${operation}]:-0}

    # Reset counter if timeout passed
    if [ $((now - last_failure)) -gt ${reset_timeout} ]; then
        failures=0
    fi

    if [ ${failures} -ge ${max_failures} ]; then
        log_error "Circuit breaker open for ${operation}, skipping"
        return 1
    fi

    if "${command[@]}"; then
        FAILURE_COUNT[${operation}]=0
        return 0
    else
        FAILURE_COUNT[${operation}]=$((failures + 1))
        LAST_FAILURE[${operation}]=${now}
        return 1
    fi
}

# Usage
circuit_breaker "github-api" github_list_repos
```

### 5. Fallback Pattern

```bash
# Try primary, fall back to secondary
with_fallback() {
    local primary=("$1")
    local fallback=("$2")

    if "${primary[@]}"; then
        return 0
    fi

    log_warn "Primary failed, trying fallback: ${fallback[*]}"
    "${fallback[@]}"
}

# Usage
with_fallback \
    "install_aur_package paru" \
    "install_aur_package yay"
```

## Error Classification

### 1. Recoverable Errors

```bash
# Errors that can be retried or worked around
RECOVERABLE_ERRORS=(
    "network timeout"
    "package database locked"
    "temporary file busy"
    "service not ready"
)

is_recoverable() {
    local error_msg="$1"

    for pattern in "${RECOVERABLE_ERRORS[@]}"; do
        if [[ "${error_msg}" =~ ${pattern} ]]; then
            return 0
        fi
    done

    return 1
}
```

### 2. Non-Recoverable Errors

```bash
# Errors that require manual intervention
NON_RECOVERABLE_ERRORS=(
    "permission denied"
    "disk full"
    "invalid configuration"
    "missing dependency"
    "unsupported platform"
)

is_non_recoverable() {
    local error_msg="$1"

    for pattern in "${NON_RECOVERABLE_ERRORS[@]}"; do
        if [[ "${error_msg}" =~ ${pattern} ]]; then
            return 0
        fi
    done

    return 1
}
```

### 3. Warning vs Error

```bash
# Warning: non-blocking issue
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Error: blocking issue
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Fatal: exit immediately
die() {
    log_error "$1"
    exit 1
}
```

## Error Context

### 1. Structured Error Information

```bash
# Error context structure
declare -A ERROR_CONTEXT=()

set_error_context() {
    local key="$1"
    local value="$2"
    ERROR_CONTEXT[${key}]="${value}"
}

get_error_context() {
    local key="$1"
    echo "${ERROR_CONTEXT[${key}]:-}"
}

clear_error_context() {
    ERROR_CONTEXT=()
}

# Usage
set_error_context "script" "configure-system.sh"
set_error_context "step" "configure-grub"
set_error_context "package" "grub"
```

### 2. Error Reporting

```bash
report_error() {
    local exit_code=$1
    local message="$2"

    local context=""
    for key in "${!ERROR_CONTEXT[@]}"; do
        context="${context}${key}=${ERROR_CONTEXT[${key}]} "
    done

    log_error "${message} (${context}exit_code=${exit_code})"

    # Send to monitoring if configured
    if [ -n "${ERROR_WEBHOOK}" ]; then
        curl -X POST "${ERROR_WEBHOOK}" \
            -H "Content-Type: application/json" \
            -d "{\"message\":\"${message}\",\"context\":\"${context}\",\"exit_code\":${exit_code}}"
    fi
}
```

## Error Handling Invariants

1. **Explicit returns** — All functions return meaningful exit codes
2. **Error propagation** — Errors bubble up unless explicitly handled
3. **Context preservation** — Error context maintained through call stack
4. **No silent failures** — All failures logged at appropriate level
5. **Graceful degradation** — Non-critical failures don't block critical path
6. **Idempotent recovery** — Recovery operations safe to retry

## Error Handling Best Practices

### Do

```bash
# Check return codes
if ! install_package "docker"; then
    log_error "Failed to install docker"
    return 1
fi

# Use descriptive messages
log_error "Failed to configure GRUB: /etc/default/grub not writable"

# Provide recovery hints
log_warn "Skipping GPU config: i915 module not loaded. Run 'modprobe i915' first."

# Clean up on error
trap 'cleanup_temp_files' ERR EXIT
```

### Don't

```bash
# Don't ignore errors
install_package "docker"  # Missing check!

# Don't use bare exit
exit 1  # No context!

# Don't suppress errors
command 2>/dev/null  # Hides failures!

# Don't use generic messages
log_error "Failed"  # Not actionable!
```

## Testing Error Handling

### Unit Tests for Error Cases

```bash
@test "update_file_if_distinct returns 2 for missing source" {
    run update_file_if_distinct "/nonexistent" "/tmp/dest"
    [ "$status" -eq 2 ]
}

@test "install_package returns 1 for unknown package" {
    run install_package "nonexistent-package-12345"
    [ "$status" -eq 1 ]
}

@test "die exits with code 1" {
    run die "Test error"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "Test error" ]]
}
```

### Integration Tests for Error Scenarios

```bash
@test "configure-system handles missing GRUB gracefully" {
    # Remove GRUB
    run_as_su rm -f /etc/default/grub

    run configure-system.sh

    # Should warn but not fail
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "GRUB not found" ]]
}
```

## Future Enhancements

1. **Structured logging** — JSON error logs for parsing
2. **Error taxonomy** — Standardised error codes
3. **Automated recovery** — Self-healing for common issues
4. **Error analytics** — Track error patterns across runs
5. **Interactive recovery** — Prompt for manual intervention
6. **Rollback support** — Automatic rollback on critical failures