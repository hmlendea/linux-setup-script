# Apps API Reference

This document provides API reference for application management operations in the linux-setup-script repository.

## Application Installation Functions

### install_application

```bash
function install_application() {
    local APP_NAME="${1}"
    local APP_TYPE="${2}"

    case "${APP_TYPE}" in
        "native")
            install_native_package "${APP_NAME}"
            ;;
        "flatpak")
            install_flatpak "${APP_NAME}"
            ;;
        "cargo")
            install_cargo_package "${APP_NAME}"
            ;;
        "github")
            local REPOSITORY="${3}"
            install_github_package "${APP_NAME}" "${REPOSITORY}"
            ;;
        "webapp")
            local URL="${3}"
            install_webapp "${URL}"
            ;;
        "vscode")
            install_vscode_package "${APP_NAME}"
            ;;
        "gnome-extension")
            install_gnome_shell_extension "${APP_NAME}"
            ;;
        *)
            log_error "Unknown application type: ${APP_TYPE}"
            return 1
            ;;
    esac
}
```

**Parameters:**
- `APP_NAME` (string): Application name
- `APP_TYPE` (string): Application type (native, flatpak, cargo, github, webapp, vscode, gnome-extension)
- Additional parameters depending on type

**Returns:**
- Exit code of installation command

**Example:**
```bash
install_application "vim" "native"
install_application "org.mozilla.firefox" "flatpak"
install_application "ripgrep" "cargo"
install_application "vim" "github" "vim/vim"
install_application "https://example.com" "webapp"
install_application "ms-python.python" "vscode"
install_application "1234/some-extension" "gnome-extension"
```

## Application Uninstallation Functions

### uninstall_application

```bash
function uninstall_application() {
    local APP_NAME="${1}"
    local APP_TYPE="${2}"

    case "${APP_TYPE}" in
        "native")
            uninstall_native_package "${APP_NAME}"
            ;;
        "flatpak")
            uninstall_flatpak "${APP_NAME}"
            ;;
        "cargo")
            uninstall_cargo_package "${APP_NAME}"
            ;;
        "github")
            uninstall_github_package "${APP_NAME}"
            ;;
        "webapp")
            uninstall_webapp "${APP_NAME}"
            ;;
        "vscode")
            # VS Code extensions don't have a standard uninstall function
            log_warning "VS Code extension uninstall not implemented"
            ;;
        "gnome-extension")
            uninstall_gnome_shell_extension "${APP_NAME}"
            ;;
        *)
            log_error "Unknown application type: ${APP_TYPE}"
            return 1
            ;;
    esac
}
```

**Parameters:**
- `APP_NAME` (string): Application name
- `APP_TYPE` (string): Application type

**Returns:**
- Exit code of uninstallation command

**Example:**
```bash
uninstall_application "vim" "native"
uninstall_application "org.mozilla.firefox" "flatpak"
```

## Desktop Entry Management

### create_desktop_entry

```bash
function create_desktop_entry() {
    local NAME="${1}"
    local EXEC="${2}"
    local ICON="${3}"
    local CATEGORIES="${4}"
    local FILE_PATH="${5}"

    create_file "${FILE_PATH}"

    cat > "${FILE_PATH}" << EOF
[Desktop Entry]
Type=Application
Name=${NAME}
Exec=${EXEC}
Icon=${ICON}
Categories=${CATEGORIES}
Terminal=false
EOF

    chmod +x "${FILE_PATH}"

    if does_bin_exist 'update-desktop-database'; then
        update-desktop-database "$(dirname "${FILE_PATH}")" >/dev/null 2>&1
    fi
}
```

**Parameters:**
- `NAME` (string): Application name
- `EXEC` (string): Executable command
- `ICON` (string): Icon name or path
- `CATEGORIES` (string): Desktop categories
- `FILE_PATH` (string): Desktop file path

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
create_desktop_entry "My App" "myapp" "myapp" "Utility;" "${HOME}/.local/share/applications/myapp.desktop"
```

### modify_desktop_entry

```bash
function modify_desktop_entry() {
    local FILE_PATH="${1}"
    local KEY="${2}"
    local VALUE="${3}"

    if does_file_exist "${FILE_PATH}"; then
        sed -i "s/^${KEY}=.*/${KEY}=${VALUE}/" "${FILE_PATH}"
    fi
}
```

**Parameters:**
- `FILE_PATH` (string): Desktop file path
- `KEY` (string): Key to modify
- `VALUE` (string): New value

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
modify_desktop_entry "${HOME}/.local/share/applications/myapp.desktop" "Exec" "myapp --new-flag"
```

## Application Launchers

### configure_launchers

```bash
function configure_launchers() {
    local LAUNCHER_DIR="${1}"

    for DESKTOP_FILE in "${LAUNCHER_DIR}"/*.desktop; do
        if does_file_exist "${DESKTOP_FILE}"; then
            # Apply modifications based on configuration
            modify_launcher "${DESKTOP_FILE}"
        fi
    done
}
```

**Parameters:**
- `LAUNCHER_DIR` (string): Directory containing desktop files

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
configure_launchers "/usr/share/applications"
```

## Error Handling

All apps functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `is_package_installed` for checks
- Continue on non-critical failures

## See Also

- [components/application-services.md](../components/application-services.md) — Application services details
- [components/package-management.md](../components/package-management.md) — Package management
- [flows/configuration-deployment.md](../flows/configuration-deployment.md) — Configuration deployment flow