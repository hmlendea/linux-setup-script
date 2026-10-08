# Filesystem Component

This document provides a deep dive into the filesystem component,
which provides path constants, directory operations, and file utilities.

## Overview

**Location**: `scripts/common/filesystem.sh`

**Purpose**: Centralised path management, directory creation, file operations,
and cross-platform path resolution.

**Consumers**: All scripts in the repository (foundation layer, configuration
scripts, update scripts, profile scripts)

## Core Constants

### Repository Paths

```bash
# Repository root directory
REPO_DIR="/path/to/linux-setup-script"

# Repository subdirectories
REPO_SCRIPTS_DIR="${REPO_DIR}/scripts"
REPO_COMMON_DIR="${REPO_SCRIPTS_DIR}/common"
REPO_DATA_DIR="${REPO_DIR}/data"
REPO_RC_DIR="${REPO_DIR}/rc"
REPO_PROFILES_DIR="${REPO_DIR}/profiles"
REPO_RESOURCES_DIR="${REPO_DIR}/resources"
REPO_DOCS_DIR="${REPO_DIR}/docs"
```

### System Paths

```bash
# Root filesystem paths
ROOT_ETC="/etc"
ROOT_USR="/usr"
ROOT_VAR="/var"
ROOT_OPT="/opt"
ROOT_BOOT="/boot"
ROOT_LIB="/lib"
ROOT_LIB64="/lib64"
ROOT_BIN="/bin"
ROOT_SBIN="/sbin"
ROOT_SYS="/sys"
ROOT_PROC="/proc"
ROOT_DEV="/dev"
ROOT_RUN="/run"
ROOT_TMP="/tmp"
ROOT_HOME="/home"
ROOT_ROOT="/root"
ROOT_MEDIA="/media"
ROOT_MNT="/mnt"
ROOT_SRV="/srv"
```

### User Paths

```bash
# Current user home
USER_HOME="${HOME}"

# XDG directories
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${USER_HOME}/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-${USER_HOME}/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${USER_HOME}/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${USER_HOME}/.local/state}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# User directories
USER_BIN="${USER_HOME}/.local/bin"
USER_LIB="${USER_HOME}/.local/lib"
USER_SHARE="${USER_HOME}/.local/share"
USER_APPLICATIONS="${XDG_DATA_HOME}/applications"
USER_AUTOSTART="${XDG_CONFIG_HOME}/autostart"
USER_DESKTOP="${USER_HOME}/Desktop"
USER_DOCUMENTS="${USER_HOME}/Documents"
USER_DOWNLOADS="${USER_HOME}/Downloads"
USER_MUSIC="${USER_HOME}/Music"
USER_PICTURES="${USER_HOME}/Pictures"
USER_VIDEOS="${USER_HOME}/Videos"
USER_TEMPLATES="${USER_HOME}/Templates"
USER_PUBLIC="${USER_HOME}/Public"
```

### Platform-Specific Paths

```bash
# Android/Termux
TERMUX_PREFIX="/data/data/com.termux/files/usr"
TERMUX_HOME="/data/data/com.termux/files/home"

# SteamOS
STEAMOS_HOME="/home/deck"
STEAMOS_DECK="${STEAMOS_HOME}"

# WSL
WSL_ROOT="/mnt"
WSL_HOME="${WSL_ROOT}/c/Users/${USER}"
```

## Core Functions

### 1. Directory Operations

```bash
# Create directory if not exists
create_directory <path>

# Create directory with parents
create_directory_parents <path>

# Remove directory if empty
remove_directory <path>

# Remove directory recursively
remove_directory_recursive <path>

# Check if directory exists
directory_exists <path>

# Check if directory is empty
directory_is_empty <path>

# List directory contents
list_directory <path>
```

### 2. File Operations

```bash
# Create file if not exists
create_file <path>

# Create file with content
create_file_with_content <path> <content>

# Remove file
remove_file <path>

# Copy file
copy_file <src> <dst>

# Move file
move_file <src> <dst>

# Create symlink
create_symlink <target> <link>

# Read file content
read_file <path>

# Write file content
write_file <path> <content>

# Append to file
append_to_file <path> <content>

# Check if file exists
file_exists <path>

# Check if file is empty
file_is_empty <path>

# Get file size
get_file_size <path>

# Get file modification time
get_file_mtime <path>
```

### 3. Path Operations

```bash
# Get absolute path
get_absolute_path <path>

# Get relative path
get_relative_path <from> <to>

# Get directory name
get_dirname <path>

# Get base name
get_basename <path>

# Get file extension
get_extension <path>

# Join paths
join_paths <path1> <path2> [...]

# Normalize path
normalize_path <path>

# Check if path is absolute
is_absolute_path <path>

# Check if path is relative
is_relative_path <path>
```

### 4. Permission Operations

```bash
# Set file permissions
set_permissions <path> <mode>

# Set file owner
set_owner <path> <user>[:<group>]

# Get file permissions
get_permissions <path>

# Get file owner
get_owner <path>

# Check if readable
is_readable <path>

# Check if writable
is_writable <path>

# Check if executable
is_executable <path>
```

### 5. Comparison Operations

```bash
# Compare file contents
compare_files <file1> <file2>
# Returns 0 if identical, 1 if different

# Update file if content differs
update_file_if_distinct <src> <dst>
# Returns 0 if updated, 1 if unchanged, 2 if error
```

## Path Resolution Patterns

### Pattern 1: Repository-Relative Paths

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"

# Access repository resources
local config_file="${REPO_RC_DIR}/shell/bashrc"
local data_file="${REPO_DATA_DIR}/steam-names.txt"
local resource_file="${REPO_RESOURCES_DIR}/firefox/userChrome.css"
```

### Pattern 2: User Configuration Paths

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"

# Deploy user configuration
local target="${XDG_CONFIG_HOME}/git/config"
local source="${REPO_RC_DIR}/gitconfig"
update_file_if_distinct "${source}" "${target}"
```

### Pattern 3: System Configuration Paths

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"

# Deploy system configuration
local target="${ROOT_ETC}/systemd/system.conf"
local source="${REPO_RC_DIR}/systemd/system.conf"
run_as_su update_file_if_distinct "${source}" "${target}"
```

### Pattern 4: Platform-Specific Paths

```bash
#!/bin/bash
source "scripts/common/filesystem.sh"
source "scripts/common/system-info.sh"

# Handle platform-specific paths
if [ "${DISTRO_FAMILY}" = "android" ]; then
    local config_dir="${TERMUX_PREFIX}/etc"
elif [ "${DISTRO_FAMILY}" = "steamos" ]; then
    local config_dir="${STEAMOS_HOME}/.config"
else
    local config_dir="${XDG_CONFIG_HOME}"
fi
```

## Filesystem Invariants

1. **Centralised paths** — All paths defined in `filesystem.sh`
2. **XDG compliance** — User paths follow XDG Base Directory Specification
3. **Platform awareness** — Platform-specific paths handled explicitly
4. **Idempotent operations** — Directory/file creation safe to repeat
5. **Content comparison** — `update_file_if_distinct` prevents unnecessary writes
6. **Privilege separation** — System paths via `run_as_su`

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `create_directory` | Permission denied | Error message, returns 1 |
| `create_file` | Parent directory missing | Creates parents, then file |
| `update_file_if_distinct` | Source not found | Error message, returns 2 |
| `update_file_if_distinct` | Permission denied | Error message, returns 2 |
| `create_symlink` | Target exists | Error message, returns 1 |
| `get_absolute_path` | Path not found | Returns original path |

## Performance Considerations

- **Path caching** — Constants computed once at source time
- **Batch operations** — Multiple files processed in loops
- **Content comparison** — `cmp -s` for fast binary comparison
- **Minimal I/O** — Read-only operations preferred

## Security Considerations

- **Path validation** — All paths validated before operations
- **No path traversal** — Relative paths resolved safely
- **Privilege separation** — System paths via `run_as_su`
- **Symlink safety** — Symlink targets validated

## Testing

### Unit Tests

```bash
function test_create_directory() {
    local temp_dir=$(mktemp -d)
    local test_dir="${temp_dir}/test/subdir"

    create_directory "${test_dir}"
    assertTrue "Directory created" "[ -d '${test_dir}' ]"

    rm -rf "${temp_dir}"
}

function test_update_file_if_distinct() {
    local temp_dir=$(mktemp -d)
    local src="${temp_dir}/source.txt"
    local dst="${temp_dir}/dest.txt"

    echo "content" > "${src}"
    update_file_if_distinct "${src}" "${dst}"
    assertEquals "content" "$(cat "${dst}")"

    # Second call should not update
    update_file_if_distinct "${src}" "${dst}"
    assertEquals "content" "$(cat "${dst}")"

    rm -rf "${temp_dir}"
}
```

### Integration Tests

```bash
function test_xdg_paths() {
    source "scripts/common/filesystem.sh"

    assertNotNull "XDG_CONFIG_HOME is set" "${XDG_CONFIG_HOME}"
    assertNotNull "XDG_DATA_HOME is set" "${XDG_DATA_HOME}"
    assertNotNull "XDG_CACHE_HOME is set" "${XDG_CACHE_HOME}"
    assertTrue "XDG_CONFIG_HOME exists" "[ -d '${XDG_CONFIG_HOME}' ]"
}
```

## Future Enhancements

1. **Path validation** — Strict path validation with allowlists
2. **Atomic operations** — Atomic file writes with temp files
3. **File locking** — Advisory file locking for concurrent access
4. **Extended attributes** — Support for xattrs
5. **ACL support** — Access Control List management
6. **Filesystem detection** — Detect filesystem type (ext4, btrfs, zfs, etc.)
7. **Mount point management** — Mount/unmount utilities