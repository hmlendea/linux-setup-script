# Package Management API Reference

This document provides API reference for package management operations in the linux-setup-script repository.

## Package Manager Abstraction

### call_package_manager

```bash
function call_package_manager() {
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        if [ "${UID}" != '0' ]; then
            if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME='' paru ${*} --noconfirm --noprovides --noredownload --norebuild --sudoloop
            elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME='' yay ${*} --noconfirm
            elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME='' yaourt ${*} --noconfirm
            else
                LANG=C LC_TIME='' run_as_su pacman ${*} --noconfirm
            fi
        else
            LANG=C LC_TIME='' pacman ${*} --noconfirm
        fi
    elif [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        yes | run_as_su apk ${*}
    elif [ "${DISTRO_FAMILY}" = 'Android' ]; then
        yes | pkg ${*}
    elif [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        yes | run_as_su apt ${*}
    fi
}
```

**Parameters:**
- Variable arguments passed to package manager commands

**Returns:**
- Exit code of package manager command

**Example:**
```bash
call_package_manager update
call_package_manager install "package-name"
```

### call_android_package_manager

```bash
function call_android_package_manager() {
    run_as_su pm ${*}
}
```

**Parameters:**
- Variable arguments passed to package manager commands

**Returns:**
- Exit code of package manager command

**Example:**
```bash
call_android_package_manager list packages
```

## Installation Functions

### install_native_package

```bash
function install_native_package() {
    local PACKAGE="${1}"

    is_native_package_installed "${PACKAGE}" && return

    echo -e " >>> Installing native package: \e[0;33m${PACKAGE}\e[0m..."
    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        call_package_manager add "${PACKAGE}"
    elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        call_package_manager -S --asexplicit "${PACKAGE}"
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        call_package_manager install "${PACKAGE}"
    fi
}
```

**Parameters:**
- `PACKAGE` (string): Package name to install

**Returns:**
- `0` if package already installed
- Exit code of installation command

**Example:**
```bash
install_native_package "vim"
```

### install_native_packages

```bash
function install_native_packages() {
    for PACKAGE_NAME in "${@}"; do
        install_native_package "${PACKAGE_NAME}"
    done
}
```

**Parameters:**
- Variable arguments: Package names to install

**Example:**
```bash
install_native_packages "vim" "git" "curl"
```

### install_android_package

```bash
function install_android_package() {
    [ "${DISTRO_FAMILY}" != 'Android' ] && return

    local PACKAGE="${1}"
    local PACKAGE_NAME="${2}"

    [ -z "${PACKAGE_NAME}" ] && PACKAGE_NAME=$(echo "${PACKAGE}" | sed 's/.*\/\([^\/]*\)\.apk$/\1/g')

    is_android_package_installed "${PACKAGE_NAME}" && return

    echo -e " >>> Installing Android package: \e[0;33m${PACKAGE_NAME}\e[0m..."
    call_android_package_manager install --user 0 "${PACKAGE}"
}
```

**Parameters:**
- `PACKAGE` (string): Package file path
- `PACKAGE_NAME` (string): Package name (optional)

**Returns:**
- `0` if package already installed
- Exit code of installation command

**Example:**
```bash
install_android_package "/path/to/package.apk"
```

### install_cargo_package

```bash
function install_cargo_package() {
    local PACKAGE="${1}"

    is_cargo_package_installed "${PACKAGE}" && return

    echo -e " >>> Installing cargo package: \e[0;33m${PACKAGE}\e[0m..."
    call_cargo install "${PACKAGE}"
}
```

**Parameters:**
- `PACKAGE` (string): Cargo package name

**Returns:**
- `0` if package already installed
- Exit code of installation command

**Example:**
```bash
install_cargo_package "ripgrep"
```

### install_flatpak

```bash
function install_flatpak() {
    local PACKAGE="${1}"
    local REMOTE='flathub'

    if [ $# -eq 2 ]; then
        local REMOTE="${1}"
        local PACKAGE="${2}"
    fi

    is_flatpak_installed "${PACKAGE}" && return

    local INSTALLATION_METHOD='user'
    PACKAGE="$(get_latest_flatpak_ref "${REMOTE}" "${PACKAGE}")"

    echo -e " >>> Installing ${INSTALLATION_METHOD} flatpak (${REMOTE}): \e[0;33m${PACKAGE}\e[0m (${REMOTE})..."
    call_flatpak install --${INSTALLATION_METHOD} "${REMOTE}" "${PACKAGE}"
}
```

**Parameters:**
- `PACKAGE` (string): Flatpak package name
- `REMOTE` (string): Remote repository (optional, default: flathub)

**Returns:**
- `0` if package already installed
- Exit code of installation command

**Example:**
```bash
install_flatpak "flathub/org.mozilla.firefox"
```

### install_github_package

```bash
function install_github_package() {
    local PACKAGE_NAME="${1}"
    local REPOSITORY="${2}"

    local PACKAGE_METADATA_DIR="${LINUX_SETUP_SCRIPT_PACKAGES_DIR}/${PACKAGE_NAME}"

    local RELEASE_JSON
    RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPOSITORY}/releases/latest")

    local VERSION
    VERSION=$(echo "${RELEASE_JSON}" | jq -r '.tag_name')

    # Detect architecture
    local ARCH
    ARCH=$(dpkg --print-architecture)

    local ARCH_REGEX="${ARCH}"
    if [ "${ARCH}" = 'amd64' ]; then
        ARCH_REGEX='(amd64|x86_64)'
    elif [ "${ARCH}" = 'arm64' ]; then
        ARCH_REGEX='(arm64|aarch64)'
    fi

    local DOWNLOAD_URL
    DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | jq -r '.assets[] | .browser_download_url' | grep -E '\.deb$')

    # First try arch-specific match
    ARCH_MATCH=$(echo "${DOWNLOAD_URL}" | grep -E "${ARCH_REGEX}" | head -n1)

    if [ -n "${ARCH_MATCH}" ]; then
        DOWNLOAD_URL="${ARCH_MATCH}"
    else
        # Fallback to any .deb (e.g. Architecture: all)
        DOWNLOAD_URL=$(echo "${DOWNLOAD_URL}" | head -n1)
    fi

    if [ -z "${DOWNLOAD_URL}" ]; then
        echo " !!! No matching .deb asset found for ${REPOSITORY} (${ARCH})"
        return 1
    fi

    if is_github_package_installed "${PACKAGE_NAME}"; then
        local INSTALLED_VERSION
        INSTALLED_VERSION=$(run_as_su cat "${PACKAGE_METADATA_DIR}/version")

        if [ "${INSTALLED_VERSION}" = "${VERSION}" ]; then
            return
        fi
    fi

    echo -e " >>> Installing GitHub package: \e[0;33m${PACKAGE_NAME}\e[0m (${VERSION})..."

    local TMP_FILE="${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}-${VERSION}.deb"

    create_directory "${LOCAL_INSTALL_TEMP_DIR}"
    remove "${TMP_FILE}"

    trap 'remove "${TMP_FILE}"' RETURN

    wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"

    if [ ! -s "${TMP_FILE}" ]; then
        echo " !!! Download failed for ${PACKAGE_NAME}"
        return 1
    fi

    run_as_su apt install -y "${TMP_FILE}" || {
        echo " !!! Installation failed for ${PACKAGE_NAME}"
        return 1
    }

    create_directory "${PACKAGE_METADATA_DIR}"
    run_as_su sh -c "echo '${VERSION}' > '${PACKAGE_METADATA_DIR}/version'"
    run_as_su sh -c "echo 'github' > '${PACKAGE_METADATA_DIR}/medium'"
}
```

**Parameters:**
- `PACKAGE_NAME` (string): Package name
- `REPOSITORY` (string): GitHub repository (owner/repo)

**Returns:**
- `0` if package already installed
- Exit code of installation command

**Example:**
```bash
install_github_package "vim" "vim/vim"
```

## Detection Functions

### is_package_installed

```bash
function is_package_installed() {
    local PACKAGE="${1}"

    if [ "${OS}" = 'Android' ]; then
        is_android_package_installed "${PACKAGE}" && return 0
    elif [ "${OS}" = 'Linux' ]; then
        is_native_package_installed "${PACKAGE}" && return 0
        is_flatpak_installed "${PACKAGE}" && return 0
        is_github_package_installed "${PACKAGE}" && return 0
        is_webapp_installed "${PACKAGE}" && return 0
    fi

    return 1
}
```

**Parameters:**
- `PACKAGE` (string): Package name to check

**Returns:**
- `0` if package is installed
- `1` if package is not installed

**Example:**
```bash
if is_package_installed "vim"; then
    echo "vim is installed"
fi
```

### is_native_package_installed

```bash
function is_native_package_installed() {
    local PACKAGE_NAME="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        call_package_manager info -e "${PACKAGE_NAME}" >/dev/null 2>&1
        return $?
    elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        if (pacman -Q | grep -q "^${PACKAGE_NAME}\s" > /dev/null); then
            return 0 # True
        else
            return 1 # False
        fi
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        if (apt-cache policy "${PACKAGE_NAME}" | grep -q '^\s*Installed:\s*[0-9]'); then
            return 0 # True
        else
            return 1 # False
        fi
    fi

    return 1
}
```

**Parameters:**
- `PACKAGE_NAME` (string): Package name to check

**Returns:**
- `0` if package is installed
- `1` if package is not installed

**Example:**
```bash
if is_native_package_installed "vim"; then
    echo "vim is installed"
fi
```

## Uninstallation Functions

### uninstall_package

```bash
function uninstall_package() {
    local PACKAGE="${1}"

    if [ "${OS}" = 'Android' ]; then
        uninstall_android_package "${PACKAGE}"
    elif [ "${OS}" = 'Linux' ]; then
        uninstall_native_package "${PACKAGE}"
        uninstall_flatpak "${PACKAGE}"
        uninstall_github_package "${PACKAGE}"
        uninstall_webapp "${PACKAGE}"
    fi
}
```

**Parameters:**
- `PACKAGE` (string): Package name to uninstall

**Returns:**
- Exit code of uninstallation command

**Example:**
```bash
uninstall_package "vim"
```

## Error Handling

All package management functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Use `is_package_installed` for checks
- Continue on non-critical failures

## See Also

- [components/package-management.md](../components/package-management.md) — Package management abstraction
- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [flows/package-management.md](../flows/package-management.md) — Package management flow