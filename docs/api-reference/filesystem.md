# Filesystem API Reference

This document provides API reference for filesystem operations in the linux-setup-script repository.

## Path Constants

### Repository Paths

| Constant | Description | Default Value |
|----------|-------------|---------------|
| `REPO_DIR` | Absolute path to repository root | Computed from script location |
| `REPO_DATA_DIR` | Data directory | `${REPO_DIR}/data` |
| `REPO_RES_DIR` | Resources directory | `${REPO_DIR}/resources` |
| `REPO_RC_DIR` | RC files directory | `${REPO_DIR}/rc` |
| `REPO_SCRIPTS_DIR` | Scripts directory | `${REPO_DIR}/scripts` |
| `REPO_SCRIPTS_COMMON_DIR` | Common scripts directory | `${REPO_SCRIPTS_DIR}/common` |
| `REPO_KEYBOARD_LAYOUTS_DIR` | Keyboard layouts directory | `${REPO_RC_DIR}/keyboard-layouts` |

### System Paths

| Constant | Description | Default Value |
|----------|-------------|---------------|
| `ROOT_PATH` | Root partition mount point | Empty or `/data/data/com.termux/files/usr` |
| `ROOT_BIN` | Root bin directory | `${ROOT_PATH}/bin` |
| `ROOT_BOOT` | Root boot directory | `${ROOT_PATH}/boot` |
| `ROOT_ETC` | Root etc directory | `${ROOT_PATH}/etc` |
| `ROOT_HOME` | Root home directory | `${ROOT_PATH}/home` |
| `ROOT_LIB` | Root lib directory | `${ROOT_PATH}/lib` |
| `ROOT_OPT` | Root opt directory | `${ROOT_PATH}/opt` |
| `ROOT_PROC` | Root proc directory | `${ROOT_PATH}/proc` |
| `ROOT_ROOT` | Root root directory | `${ROOT_PATH}/root` |
| `ROOT_SRV` | Root srv directory | `${ROOT_PATH}/srv` |
| `ROOT_SYS` | Root sys directory | `${ROOT_PATH}/sys` |
| `ROOT_USR` | Root usr directory | `${ROOT_PATH}/usr` |

### User Paths

| Constant | Description | Default Value |
|----------|-------------|---------------|
| `HOME_REAL` | Real user home directory | Computed from passwd |
| `HOME` | Current home directory | Set to `HOME_REAL` if empty |
| `USER_REAL` | Real username | `SUDO_USER` or `USER` |

## Functions

### does_directory_exist

```bash
function does_directory_exist() {
    local DIRECTORY_PATH="${*}"

    [ -d "${DIRECTORY_PATH}" ] && return 0

    return 1
}
```

**Parameters:**
- `DIRECTORY_PATH` (string): Path to check

**Returns:**
- `0` if directory exists
- `1` if directory does not exist

**Example:**
```bash
if does_directory_exist "/usr/bin"; then
    echo "Directory exists"
fi
```

### does_file_exist

```bash
function does_file_exist() {
    local FILE_PATH="${*}"

    [ -f "${FILE_PATH}" ] && return 0

    return 1
}
```

**Parameters:**
- `FILE_PATH` (string): Path to check

**Returns:**
- `0` if file exists
- `1` if file does not exist

**Example:**
```bash
if does_file_exist "/etc/passwd"; then
    echo "File exists"
fi
```

### ensure_directory

```bash
function ensure_directory() {
    local DIRECTORY_PATH="${*}"

    does_directory_exist "${DIRECTORY_PATH}" && return 0

    mkdir -p "${DIRECTORY_PATH}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `DIRECTORY_PATH` (string): Directory to create

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
ensure_directory "${HOME}/.config/myapp"
```

### update_file_if_distinct

```bash
function update_file_if_distinct() {
    local SOURCE_FILE="${1}"
    local TARGET_FILE="${2}"

    does_file_exist "${SOURCE_FILE}" || return 1
    does_file_exist "${TARGET_FILE}" && return 0

    cp "${SOURCE_FILE}" "${TARGET_FILE}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `SOURCE_FILE` (string): Source file path
- `TARGET_FILE` (string): Target file path

**Returns:**
- `0` on success
- `1` if source does not exist
- Non-zero on copy failure

**Example:**
```bash
update_file_if_distinct "/etc/myapp/config" "${HOME}/.config/myapp/config"
```

## File Operations

### File Copying

```bash
# Copy file with permission preservation
cp -p "${SOURCE}" "${DESTINATION}"

# Copy directory recursively
cp -r "${SOURCE_DIR}" "${DESTINATION_DIR}"
```

### File Creation

```bash
# Create file with content
echo "content" > "${FILE_PATH}"

# Create file with heredoc
cat <<EOF > "${FILE_PATH}"
content
EOF
```

### File Deletion

```bash
# Delete file
rm -f "${FILE_PATH}"

# Delete directory recursively
rm -rf "${DIRECTORY_PATH}"
```

## Path Resolution

### Absolute Paths

```bash
# Get absolute path
realpath "${PATH}"

# Get script directory
dirname "${BASH_SOURCE[0]}"
```

### Relative Paths

```bash
# Get relative path
realpath --relative-to="${BASE}" "${PATH}"
```

## Error Handling

All filesystem functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `does_file_exist` and `does_directory_exist` for checks
- Handle permission errors gracefully

## See Also

- [components/common.md](../components/common.md) — Execution primitives
- [components/system-info.md](../components/system-info.md) — Environment detection
- [flows/directory-and-file-management.md](../flows/directory-and-file-management.md) — File management flow