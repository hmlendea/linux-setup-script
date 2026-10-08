# Config API Reference

This document provides API reference for configuration file manipulation in the linux-setup-script repository.

## Configuration Functions

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

### create_file

```bash
function create_file() {
    local FILE_PATH="${1}"

    local DIRECTORY_PATH
    DIRECTORY_PATH=$(dirname "${FILE_PATH}")

    ensure_directory "${DIRECTORY_PATH}"

    touch "${FILE_PATH}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `FILE_PATH` (string): File path to create

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
create_file "${HOME}/.config/myapp/config"
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

## INI File Manipulation

### read_ini_value

```bash
function read_ini_value() {
    local FILE="${1}"
    local SECTION="${2}"
    local KEY="${3}"

    local VALUE
    VALUE=$(awk -F'=' -v section="${SECTION}" -v key="${KEY}" '
        $0 ~ "\\[" section "\\]" { in_section=1; next }
        $0 ~ /^\[/ { in_section=0 }
        in_section && $1 == key { print $2; exit }
    ' "${FILE}")

    echo "${VALUE}"
}
```

**Parameters:**
- `FILE` (string): INI file path
- `SECTION` (string): Section name
- `KEY` (string): Key name

**Returns:**
- Value of the key, or empty string if not found

**Example:**
```bash
VALUE=$(read_ini_value "/etc/myapp/config.ini" "section" "key")
```

### write_ini_value

```bash
function write_ini_value() {
    local FILE="${1}"
    local SECTION="${2}"
    local KEY="${3}"
    local VALUE="${4}"

    local TEMP_FILE
    TEMP_FILE=$(mktemp)

    awk -F'=' -v section="${SECTION}" -v key="${KEY}" -v value="${VALUE}" '
        $0 ~ "\\[" section "\\]" { in_section=1; print; next }
        $0 ~ /^\[/ { in_section=0 }
        in_section && $1 == key { print key "=" value; found=1; next }
        { print }
        END { if (!found && in_section) print key "=" value }
    ' "${FILE}" > "${TEMP_FILE}"

    mv "${TEMP_FILE}" "${FILE}"
}
```

**Parameters:**
- `FILE` (string): INI file path
- `SECTION` (string): Section name
- `KEY` (string): Key name
- `VALUE` (string): Value to set

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
write_ini_value "/etc/myapp/config.ini" "section" "key" "value"
```

## JSON File Manipulation

### read_json_value

```bash
function read_json_value() {
    local FILE="${1}"
    local KEY="${2}"

    local VALUE
    VALUE=$(jq -r ".${KEY}" "${FILE}" 2>/dev/null)

    echo "${VALUE}"
}
```

**Parameters:**
- `FILE` (string): JSON file path
- `KEY` (string): JSON key path (e.g., "section.key")

**Returns:**
- Value of the key, or empty string if not found

**Example:**
```bash
VALUE=$(read_json_value "/etc/myapp/config.json" "section.key")
```

### write_json_value

```bash
function write_json_value() {
    local FILE="${1}"
    local KEY="${2}"
    local VALUE="${3}"

    local TEMP_FILE
    TEMP_FILE=$(mktemp)

    jq ".${KEY} = ${VALUE}" "${FILE}" > "${TEMP_FILE}"

    mv "${TEMP_FILE}" "${FILE}"
}
```

**Parameters:**
- `FILE` (string): JSON file path
- `KEY` (string): JSON key path (e.g., "section.key")
- `VALUE` (string): Value to set (JSON encoded)

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
write_json_value "/etc/myapp/config.json" "section.key" '"value"'
```

## XML File Manipulation

### read_xml_value

```bash
function read_xml_value() {
    local FILE="${1}"
    local XPATH="${2}"

    local VALUE
    VALUE=$(xmllint --xpath "string(${XPATH})" "${FILE}" 2>/dev/null)

    echo "${VALUE}"
}
```

**Parameters:**
- `FILE` (string): XML file path
- `XPATH` (string): XPath expression

**Returns:**
- Value of the XPath expression, or empty string if not found

**Example:**
```bash
VALUE=$(read_xml_value "/etc/myapp/config.xml" "//section/key")
```

### write_xml_value

```bash
function write_xml_value() {
    local FILE="${1}"
    local XPATH="${2}"
    local VALUE="${3}"

    local TEMP_FILE
    TEMP_FILE=$(mktemp)

    xmlstarlet ed -u "${XPATH}" -v "${VALUE}" "${FILE}" > "${TEMP_FILE}"

    mv "${TEMP_FILE}" "${FILE}"
}
```

**Parameters:**
- `FILE` (string): XML file path
- `XPATH` (string): XPath expression
- `VALUE` (string): Value to set

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
write_xml_value "/etc/myapp/config.xml" "//section/key" "value"
```

## GSettings Manipulation

### read_gsettings_value

```bash
function read_gsettings_value() {
    local SCHEMA="${1}"
    local KEY="${2}"

    local VALUE
    VALUE=$(gsettings get "${SCHEMA}" "${KEY}" 2>/dev/null)

    echo "${VALUE}"
}
```

**Parameters:**
- `SCHEMA` (string): GSettings schema
- `KEY` (string): Key name

**Returns:**
- Value of the key, or empty string if not found

**Example:**
```bash
VALUE=$(read_gsettings_value "org.gnome.desktop.interface" "gtk-theme")
```

### write_gsettings_value

```bash
function write_gsettings_value() {
    local SCHEMA="${1}"
    local KEY="${2}"
    local VALUE="${3}"

    gsettings set "${SCHEMA}" "${KEY}" "${VALUE}" 2>/dev/null

    return $?
}
```

**Parameters:**
- `SCHEMA` (string): GSettings schema
- `KEY` (string): Key name
- `VALUE` (string): Value to set

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
write_gsettings_value "org.gnome.desktop.interface" "gtk-theme" "'Adwaita'"
```

## Modprobe Configuration

### read_modprobe_value

```bash
function read_modprobe_value() {
    local FILE="${1}"
    local MODULE="${2}"
    local PARAMETER="${3}"

    local VALUE
    VALUE=$(grep -E "^options\s+${MODULE}\s+${PARAMETER}=" "${FILE}" 2>/dev/null | \
        sed -E "s/.*${PARAMETER}=([^ ]+).*/\1/")

    echo "${VALUE}"
}
```

**Parameters:**
- `FILE` (string): Modprobe config file path
- `MODULE` (string): Module name
- `PARAMETER` (string): Parameter name

**Returns:**
- Value of the parameter, or empty string if not found

**Example:**
```bash
VALUE=$(read_modprobe_value "/etc/modprobe.d/myapp.conf" "my_module" "my_param")
```

### write_modprobe_value

```bash
function write_modprobe_value() {
    local FILE="${1}"
    local MODULE="${2}"
    local PARAMETER="${3}"
    local VALUE="${4}"

    local TEMP_FILE
    TEMP_FILE=$(mktemp)

    if grep -q "^options\s\+${MODULE}\s\+${PARAMETER}=" "${FILE}" 2>/dev/null; then
        sed -E "s/(^options\s\+${MODULE}\s\+${PARAMETER}=)[^ ]+/\1${VALUE}/" "${FILE}" > "${TEMP_FILE}"
    else
        echo "options ${MODULE} ${PARAMETER}=${VALUE}" >> "${FILE}"
    fi

    mv "${TEMP_FILE}" "${FILE}"
}
```

**Parameters:**
- `FILE` (string): Modprobe config file path
- `MODULE` (string): Module name
- `PARAMETER` (string): Parameter name
- `VALUE` (string): Value to set

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
write_modprobe_value "/etc/modprobe.d/myapp.conf" "my_module" "my_param" "value"
```

## Error Handling

All config functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `does_file_exist` for checks
- Handle permission errors gracefully

## See Also

- [components/configuration-management.md](../components/configuration-management.md) — Configuration management details
- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [flows/configuration-deployment.md](../flows/configuration-deployment.md) — Configuration deployment flow