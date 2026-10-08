# Testing

This document describes the testing strategy, frameworks, and practices
for the linux-setup-script repository.

## Overview

The repository uses a combination of unit tests, integration tests, and
manual verification to ensure correctness and reliability.

## Test Structure

```
tests/
├── unit/
│   ├── common/
│   │   ├── test_filesystem.sh
│   │   ├── test_common.sh
│   │   ├── test_system_info.sh
│   │   ├── test_config.sh
│   │   ├── test_package_management.sh
│   │   ├── test_service_management.sh
│   │   └── test_apps.sh
│   └── scripts/
│       ├── test_install_packages.sh
│       ├── test_configure_system.sh
│       └── ...
├── integration/
│   ├── test_full_run.sh
│   ├── test_platform_detection.sh
│   └── test_idempotency.sh
└── fixtures/
    ├── mock_pacman.sh
    ├── mock_apt.sh
    └── ...
```

## Test Frameworks

### 1. Bats (Bash Automated Testing System)

**Primary framework** for unit and integration tests.

```bash
# Install bats
install_package "bats"

# Run tests
bats tests/
bats tests/unit/
bats tests/integration/
```

### 2. ShellCheck

**Static analysis** for shell scripts.

```bash
# Install shellcheck
install_package "shellcheck"

# Run on all scripts
shellcheck scripts/**/*.sh
shellcheck scripts/common/*.sh
```

### 3. shfmt

**Formatter** for consistent style.

```bash
# Install shfmt
install_package "shfmt"

# Check formatting
shfmt -d scripts/**/*.sh

# Apply formatting
shfmt -w scripts/**/*.sh
```

## Unit Testing

### Test File Template

```bash
#!/usr/bin/env bats

# Load test helpers
load '../helpers/test_helper'

# Setup runs before each test
setup() {
    # Create temporary directory
    export TEST_TEMP_DIR=$(mktemp -d)

    # Source the module under test
    source "${REPO_DIR}/scripts/common/filesystem.sh"
}

# Teardown runs after each test
teardown() {
    # Clean up
    rm -rf "${TEST_TEMP_DIR}"
}

@test "create_directory creates directory" {
    local test_dir="${TEST_TEMP_DIR}/testdir"

    run create_directory "${test_dir}"

    [ "$status" -eq 0 ]
    [ -d "${test_dir}" ]
}

@test "create_directory is idempotent" {
    local test_dir="${TEST_TEMP_DIR}/testdir"

    run create_directory "${test_dir}"
    [ "$status" -eq 0 ]

    run create_directory "${test_dir}"
    [ "$status" -eq 0 ]
}

@test "update_file_if_distinct updates file when different" {
    local src="${TEST_TEMP_DIR}/source.txt"
    local dst="${TEST_TEMP_DIR}/dest.txt"

    echo "content1" > "${src}"
    echo "content2" > "${dst}"

    run update_file_if_distinct "${src}" "${dst}"

    [ "$status" -eq 0 ]
    [ "$(cat "${dst}")" = "content1" ]
}

@test "update_file_if_distinct does not update when same" {
    local src="${TEST_TEMP_DIR}/source.txt"
    local dst="${TEST_TEMP_DIR}/dest.txt"

    echo "content" > "${src}"
    echo "content" > "${dst}"
    local mtime_before=$(stat -c %Y "${dst}")

    run update_file_if_distinct "${src}" "${dst}"

    [ "$status" -eq 1 ]  # Returns 1 when unchanged
    [ "$(stat -c %Y "${dst}")" -eq "${mtime_before}" ]
}
```

### Test Helpers

```bash
# tests/helpers/test_helper.bash

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [ "${expected}" != "${actual}" ]; then
        echo "Assertion failed: ${message}"
        echo "Expected: ${expected}"
        echo "Actual: ${actual}"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-}"

    if ! eval "${condition}"; then
        echo "Assertion failed: ${message}"
        echo "Condition was false: ${condition}"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-}"

    if eval "${condition}"; then
        echo "Assertion failed: ${message}"
        echo "Condition was true: ${condition}"
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    local message="${2:-}"

    if [ ! -f "${path}" ]; then
        echo "Assertion failed: ${message}"
        echo "File does not exist: ${path}"
        return 1
    fi
}

assert_dir_exists() {
    local path="$1"
    local message="${2:-}"

    if [ ! -d "${path}" ]; then
        echo "Assertion failed: ${message}"
        echo "Directory does not exist: ${path}"
        return 1
    fi
}
```

## Integration Testing

### Full Run Test

```bash
#!/usr/bin/env bats

load '../helpers/test_helper'

@test "full run completes without errors" {
    # Run in dry-run mode
    export DRY_RUN=1

    run "${REPO_DIR}/run.sh"

    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Setup complete" ]]
}

@test "full run is idempotent" {
    export DRY_RUN=1

    # First run
    run "${REPO_DIR}/run.sh"
    [ "$status" -eq 0 ]

    # Second run
    run "${REPO_DIR}/run.sh"
    [ "$status" -eq 0 ]

    # Output should be similar (no new changes)
    # This is a simplified check
}
```

### Platform Detection Test

```bash
#!/usr/bin/env bats

load '../helpers/test_helper'

@test "detect_os identifies Linux" {
    source "${REPO_DIR}/scripts/common/system-info.sh"

    run detect_os

    [ "$status" -eq 0 ]
    [ "${OS}" = "linux" ]
}

@test "detect_distro identifies Arch" {
    # Mock /etc/os-release
    echo 'ID=arch' > "${TEST_TEMP_DIR}/os-release"
    export TEST_OS_RELEASE="${TEST_TEMP_DIR}/os-release"

    source "${REPO_DIR}/scripts/common/system-info.sh"

    run detect_distro

    [ "$status" -eq 0 ]
    [ "${DISTRO}" = "arch" ]
}
```

### Idempotency Test

```bash
#!/usr/bin/env bats

load '../helpers/test_helper'

@test "configure-system is idempotent" {
    export DRY_RUN=1

    # First run
    run "${REPO_DIR}/scripts/configure-system.sh"
    [ "$status" -eq 0 ]
    local output1="${output}"

    # Second run
    run "${REPO_DIR}/scripts/configure-system.sh"
    [ "$status" -eq 0 ]
    local output2="${output}"

    # Should have no changes on second run
    # (In dry-run mode, output should be identical)
    [ "${output1}" = "${output2}" ]
}
```

## Test Execution

### Local Development

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/unit/common/test_filesystem.sh

# Run with verbose output
bats -v tests/

# Run with TAP output
bats --tap tests/
```

### CI/CD Pipeline

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats shellcheck shfmt

      - name: Run ShellCheck
        run: shellcheck scripts/**/*.sh

      - name: Check formatting
        run: shfmt -d scripts/**/*.sh

      - name: Run unit tests
        run: bats tests/unit/

      - name: Run integration tests
        run: bats tests/integration/
```

## Test Coverage

### Target Coverage

| Component | Target Coverage |
|-----------|-----------------|
| Foundation layer (common/) | 90% |
| Configuration scripts | 80% |
| Update scripts | 70% |
| Profile scripts | 60% |

### Coverage Measurement

```bash
# Install kcov for coverage
install_package "kcov"

# Run with coverage
kcov coverage/ bats tests/

# View coverage report
open coverage/index.html
```

## Mocking Strategy

### Package Manager Mocks

```bash
# tests/fixtures/mock_pacman.sh

#!/bin/bash

# Mock pacman for testing
function pacman() {
    case "$1" in
        -S)
            echo "Installing: $2"
            ;;
        -Rns)
            echo "Removing: $2"
            ;;
        -Sy)
            echo "Updating database"
            ;;
        -Ss)
            echo "Searching: $2"
            ;;
        -Q)
            if [ "$2" = "test-package" ]; then
                echo "test-package 1.0-1"
                return 0
            fi
            return 1
            ;;
    esac
}

export -f pacman
```

### System Command Mocks

```bash
# tests/fixtures/mock_systemctl.sh

#!/bin/bash

function systemctl() {
    case "$1" in
        start)
            echo "Starting: $2"
            ;;
        stop)
            echo "Stopping: $2"
            ;;
        enable)
            echo "Enabling: $2"
            ;;
        disable)
            echo "Disabling: $2"
            ;;
        status)
            if [ "$2" = "test-service" ]; then
                echo "active"
                return 0
            fi
            echo "inactive"
            return 1
            ;;
        daemon-reload)
            echo "Reloading daemon"
            ;;
    esac
}

export -f systemctl
```

## Test Data Management

### Fixtures

```
tests/fixtures/
├── os-release.arch
├── os-release.debian
├── os-release.ubuntu
├── os-release.alpine
├── lspci.intel
├── lspci.amd
├── lspci.nvidia
├── containers.json
├── prefs.js
└── ...
```

### Test Data Generation

```bash
# tests/helpers/generate_test_data.sh

generate_os_release() {
    local distro="$1"
    local output="$2"

    case "${distro}" in
        arch)
            cat > "${output}" <<'EOF'
ID=arch
NAME="Arch Linux"
PRETTY_NAME="Arch Linux"
EOF
            ;;
        debian)
            cat > "${output}" <<'EOF'
ID=debian
NAME="Debian GNU/Linux"
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
VERSION_ID="12"
EOF
            ;;
    esac
}
```

## Continuous Testing

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit

#!/bin/bash

# Run shellcheck on staged files
git diff --cached --name-only -- '*.sh' | xargs shellcheck

# Run shfmt check on staged files
git diff --cached --name-only -- '*.sh' | xargs shfmt -d

# Run quick unit tests
bats tests/unit/common/
```

### Pre-push Hooks

```bash
# .git/hooks/pre-push

#!/bin/bash

# Run full test suite
bats tests/
```

## Testing Invariants

1. **Isolation** — Tests don't modify system state
2. **Determinism** — Same inputs produce same outputs
3. **Speed** — Unit tests complete in <1 second each
4. **Independence** — Tests can run in any order
5. **Clarity** — Test names describe what they verify

## Future Enhancements

1. **Property-based testing** — QuickCheck-style testing for bash
2. **Mutation testing** — Verify test quality
3. **Contract testing** — Test module interfaces
4. **Performance benchmarks** — Track execution time
5. **Visual regression** — Screenshot comparison for GUI config
6. **Cross-platform testing** — Test matrix for all supported platforms