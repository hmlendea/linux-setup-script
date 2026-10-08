# Common Component

This document provides a deep dive into the common component,
which provides execution primitives, logging, and utility functions.

## Overview

**Location**: `scripts/common/common.sh`

**Purpose**: Core execution primitives, logging, error handling, and
utility functions used throughout the repository.

**Consumers**: All scripts in the repository (foundation layer, configuration
scripts, update scripts, profile scripts)

## Core Functions

### 1. Execution Primitives

```bash
# Run command with sudo or su (Android/Termux)
run_as_su <command> [args...]
# Returns exit code of command

# Run command as current user
run_as_user <command> [args...]
# Returns exit code of command

# Run command and capture output
run_capture <command> [args...]
# Returns stdout, sets RUN_CAPTURE_EXIT_CODE

# Run command with timeout
run_with_timeout <timeout_seconds> <command> [args...]
# Returns exit code, kills on timeout
```

### 2. Logging Functions

```bash
# Log info message
log_info <message>

# Log warning message
log_warn <message>

# Log error message
log_error <message>

# Log debug message (only if DEBUG=1)
log_debug <message>

# Log success message
log_success <message>

# Log section header
log_section <title>

# Log subsection header
log_subsection <title>
```

### 3. Error Handling

```bash
# Exit with error message
die <message>

# Check if command succeeded
check_command <command> [args...]
# Returns 0 on success, 1 on failure

# Assert condition
assert <condition> <message>

# Assert file exists
assert_file <path>

# Assert directory exists
assert_directory <path>

# Assert command exists
assert_command <command>
```

### 4. Utility Functions

```bash
# Check if running as root
is_root
# Returns 0 if UID=0, 1 otherwise

# Check if running in container
is_container
# Returns 0 if in container, 1 otherwise

# Check if running in VM
is_vm
# Returns 0 if in VM, 1 otherwise

# Check if command exists
command_exists <command>

# Get command path
get_command_path <command>

# Get OS release info
get_os_release

# Get kernel version
get_kernel_version

# Get architecture
get_architecture

# Get hostname
get_hostname

# Get current user
get_current_user

# Get current user home
get_current_user_home

# Get current user shell
get_current_user_shell
```

### 5. String Utilities

```bash
# Trim whitespace
trim <string>

# Convert to lowercase
to_lower <string>

# Convert to uppercase
to_upper <string>

# Check if string starts with prefix
starts_with <string> <prefix>

# Check if string ends with suffix
ends_with <string> <suffix>

# Check if string contains substring
contains <string> <substring>

# Replace substring
replace <string> <search> <replace>

# Split string by delimiter
split_string <string> <delimiter>

# Join array by delimiter
join_array <delimiter> <array...>
```

### 6. Array Utilities

```bash
# Check if array contains element
array_contains <element> <array...>

# Get array length
array_length <array...>

# Get array element at index
array_get <index> <array...>

# Set array element at index
array_set <index> <value> <array...>

# Append to array
array_append <value> <array...>

# Remove from array
array_remove <value> <array...>

# Reverse array
array_reverse <array...>

# Unique array elements
array_unique <array...>
```

### 7. File Utilities

```bash
# Read file into array
read_file_to_array <path> <array_var>

# Write array to file
write_array_to_file <array_var> <path>

# Get file lines
get_file_lines <path>

# Get file line count
get_file_line_count <path>

# Get file first line
get_file_first_line <path>

# Get file last line
get_file_last_line <path>
```

### 8. Process Utilities

```bash
# Get process ID by name
get_pid <process_name>

# Check if process is running
is_process_running <process_name>

# Kill process by name
kill_process <process_name>

# Kill process by PID
kill_pid <pid>

# Wait for process to exit
wait_for_process <pid> [timeout]

# Get process command line
get_process_cmdline <pid>

# Get process memory usage
get_process_memory <pid>

# Get process CPU usage
get_process_cpu <pid>
```

### 9. Network Utilities

```bash
# Check if host is reachable
is_host_reachable <host> [port]

# Check if port is open
is_port_open <host> <port>

# Get public IP
get_public_ip

# Get local IP
get_local_ip

# Download file
download_file <url> <destination>

# Download file with progress
download_file_progress <url> <destination>
```

### 10. Time Utilities

```bash
# Get current timestamp
get_timestamp

# Get current date
get_date

# Get current time
get_time

# Format timestamp
format_timestamp <timestamp> [format]

# Parse timestamp
parse_timestamp <string> [format]

# Sleep with progress
sleep_progress <seconds>
```

## Logging Patterns

### Pattern 1: Basic Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

log_section "Starting system configuration"

log_info "Configuring locale..."
configure_locale

log_info "Configuring time..."
configure_time

log_success "System configuration complete"
```

### Pattern 2: Debug Logging

```bash
#!/bin/bash
source "scripts/common/common.sh"

# Enable debug logging
export DEBUG=1

log_debug "Checking package: ${package}"
if is_package_installed "${package}"; then
    log_debug "Package ${package} already installed"
else
    log_info "Installing package: ${package}"
    install_package "${package}"
fi
```

### Pattern 3: Error Handling

```bash
#!/bin/bash
source "scripts/common/common.sh"

# Check prerequisites
assert_command "git" "Git is required"
assert_command "curl" "Curl is required"
assert_directory "${REPO_DIR}" "Repository directory not found"

# Run with error handling
if ! run_as_su systemctl enable NetworkManager; then
    log_error "Failed to enable NetworkManager"
    die "NetworkManager setup failed"
fi

log_success "NetworkManager enabled"
```

## Common Invariants

1. **Single source** — All execution primitives in `common.sh`
2. **Privilege abstraction** — `run_as_su` handles sudo/su automatically
3. **Consistent logging** — Standardised log levels and formatting
4. **Error propagation** — Functions return exit codes, `die` for fatal errors
5. **No global state** — Functions are stateless, use parameters
6. **Platform awareness** — Container/VM detection for conditional logic

## Error Handling

| Function | Failure Mode | Handling |
|----------|--------------|----------|
| `run_as_su` | No sudo/su | Error message, returns 1 |
| `run_as_su` | Command fails | Returns command exit code |
| `run_capture` | Command fails | Sets RUN_CAPTURE_EXIT_CODE |
| `run_with_timeout` | Timeout | Kills process, returns 124 |
| `die` | Called | Exits with code 1 |
| `assert` | Condition false | Calls `die` with message |

## Performance Considerations

- **Lazy evaluation** — Functions only compute when called
- **Command caching** — `command_exists` caches results
- **Minimal subprocesses** — Built-in bash operations preferred
- **Batch operations** — Multiple operations in single function calls

## Security Considerations

- **No eval/exec** on user input
- **Command validation** — `assert_command` before use
- **Privilege separation** — `run_as_su` for elevated operations
- **Path validation** — File operations use `filesystem.sh` utilities

## Testing

### Unit Tests

```bash
function test_run_as_su() {
    # Test with simple command
    run_as_su true
    assertEquals "run_as_su true succeeds" 0 $?

    # Test with failing command
    run_as_su false
    assertEquals "run_as_su false fails" 1 $?
}

function test_log_functions() {
    # Test logging functions don't crash
    log_info "Test info"
    log_warn "Test warn"
    log_error "Test error"
    log_debug "Test debug"
    log_success "Test success"
    log_section "Test section"
    log_subsection "Test subsection"
}

function test_string_utils() {
    assertEquals "trim" "hello" "$(trim "  hello  ")"
    assertEquals "to_lower" "hello" "$(to_lower "HELLO")"
    assertEquals "to_upper" "HELLO" "$(to_upper "hello")"
    assertTrue "starts_with" "$(starts_with "hello world" "hello")"
    assertTrue "ends_with" "$(ends_with "hello world" "world")"
    assertTrue "contains" "$(contains "hello world" "lo wo")"
    assertEquals "replace" "hello there" "$(replace "hello world" "world" "there")"
}
```

### Integration Tests

```bash
function test_privilege_detection() {
    if is_root; then
        assertTrue "Running as root" "is_root"
    else
        assertFalse "Not running as root" "is_root"
    fi
}

function test_command_detection() {
    assertTrue "bash exists" "command_exists bash"
    assertFalse "fake-command exists" "command_exists fake-command-12345"
}
```

## Future Enhancements

1. **Structured logging** — JSON/logfmt output support
2. **Log levels** — Configurable log level filtering
3. **Log rotation** — Automatic log file rotation
4. **Metrics collection** — Performance metrics collection
5. **Tracing** — Distributed tracing support
6. **Progress bars** — Visual progress indicators
7. **Spinners** — Loading spinners for long operations