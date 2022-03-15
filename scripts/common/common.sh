#!/bin/bash

# Get local path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
  REPO_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink ${SOURCE})"
  [[ "${SOURCE}" != /* ]] && SOURCE="${EXEDIR}/${SOURCE}"
done
REPO_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
REPO_DIR=$(realpath "${REPO_DIR}/../..")

REPO_DATA_DIR="${REPO_DIR}/data"
REPO_RES_DIR="${REPO_DIR}/resources"
REPO_RC_DIR="${REPO_DIR}/rc"
REPO_SCRIPTS_DIR="${REPO_DIR}/scripts"

REPO_KEYBOARD_LAYOUTS_DIR="${REPO_RC_DIR}/keyboard-layouts"

LOCAL_INSTALL_TEMP_DIR="${REPO_DIR}/.temp-sysinstall"

source "${REPO_DIR}/scripts/common/system-info.sh"

# Distribution
KERNEL_VERSION=$(uname -r)

if [ -f "/etc/os-release" ]; then
    DISTRO=$(grep "^ID" "/etc/os-release" | tail -n 1 | awk -F'=' '{print $2}')
else
    DISTRO=$(echo "${KERNEL_VERSION}" | sed -e 's/^[^-]*-//g' -e 's/^[0-9][0-9]*-//g' -e 's/raspberrypi-//g' -e 's/-[0-9]*$//g' -e 's/-[a-z0-9]*$//g')
fi

OS=$(uname -s)

if [ "${DISTRO}" = "arch" ] \
|| [ "${DISTRO}" = "ARCH" ]; then
    DISTRO="Arch Linux"
    DISTRO_FAMILY="Arch"
elif [ "${DISTRO}" = "debian" ]; then
    DISTRO="Debian"
    DISTRO_FAMILY="Debian"
elif [ "${DISTRO}" = "lineageos" ] || [ $(uname -a | grep -c "Android") -ge 1 ]; then
    DISTRO="LineageOS"
    DISTRO_FAMILY="Android"
    OS="Android"
fi

if [ "${OS}" = "CYGWIN_NT-10.0" ]; then
    DISTRO="Cygwin"
    DISTRO_FAMILY="Windows"
    OS="Windows"
fi

# Root partition mount point
ROOT_PATH=""
[ "${DISTRO_FAMILY}" = "Android" ] && ROOT_PATH="/data/data/com.termux/files/usr"

ROOT_BIN="${ROOT_PATH}/bin"
ROOT_BOOT="${ROOT_PATH}/boot"
ROOT_ETC="${ROOT_PATH}/etc"
ROOT_LIB="${ROOT_PATH}/lib"
ROOT_OPT="${ROOT_PATH}/opt"
ROOT_PROC="${ROOT_PATH}/proc"
ROOT_SYS="${ROOT_PATH}/sys"
ROOT_USR="${ROOT_PATH}/usr"
ROOT_USR_BIN="${ROOT_USR}/bin"
ROOT_USR_LIB="${ROOT_USR}/lib"
ROOT_USR_SHARE="${ROOT_USR}/share"
ROOT_VAR="${ROOT}/var"
ROOT_VAR_LIB="${ROOT_VAR}/lib"

HOME_CACHE="${HOME}/.cache"
HOME_CONFIG="${HOME}/.config"
HOME_LOCAL="${HOME}/.local"
HOME_LOCAL_BIN="${HOME_LOCAL}/bin"
HOME_LOCAL_SHARE="${HOME_LOCAL}/share"
HOME_VAR="${HOME}/.var"

# Functions
function does-bin-exist () {
    for BINARY_NAME in "${@}"; do
        if [ -f "${ROOT_BIN}/${BINARY_NAME}" ] \
        || [ -f "${ROOT_USR_BIN}/${BINARY_NAME}" ] \
        || [ -f "${ROOT_VAR_LIB}/flatpak/exports/bin/${BINARY_NAME}" ] \
        || [ -f "${HOME_LOCAL_BIN}/${BINARY_NAME}" ] \
        || [ -f "${HOME_LOCAL_SHARE}/flatpak/exports/bin/${BINARY_NAME}" ] \
        || [ -f "${BINARY_NAME}" ]; then
            return 0 # True
        fi
    done

    return 1 # False
}

function does-gnome-shell-extension-exist() {
    local EXTENSION_NAME="${*}"

    local GLOBAL_EXTENSIONS_DIR="${ROOT_USR_SHARE}/gnome-shell/extensions"
    local LOCAL_EXTENSIONS_DIR="${HOME_LOCAL_SHARE}/gnome-shell/extensions"

    if [ -d "${GLOBAL_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${GLOBAL_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")
        [ -n "${EXTENSION_PATH}" ] && return 0 # True
    elif [ -d "${LOCAL_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${LOCAL_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")
        [ -n "${EXTENSION_PATH}" ] && return 0 # True
    fi

    return 1 # False
}

function run-as-su() {
    if [ "${UID}" -eq 0 ]; then
        "${@}"
    elif ${HAS_SU_PRIVILEGES}; then
        sudo "${@}"
    else
        echo "Failed to run '${*}': Missing SU privileges!"
    fi
}

function remove() {
    for PATH_TO_REMOVE in "${@}"; do
        PATH_TO_REMOVE=$(echo "${PATH_TO_REMOVE}" | sed \
                            -e 's/^\s*//g' \
                            -e 's/\s*$//g')

        if [ ! -e "${PATH_TO_REMOVE}" ] \
        || [ -z "${PATH_TO_REMOVE}" ] \
        || [ "${PATH_TO_REMOVE}" == "/" ]; then
            return
        fi

        echo -e "Removing \e[0;33m${PATH_TO_REMOVE}\e[0m ..."
        if [ -w "${PATH_TO_REMOVE}" ]; then
            if [ -f "${PATH_TO_REMOVE}" ]; then
                rm "${PATH_TO_REMOVE}"
            else
                rm -r "${PATH_TO_REMOVE}"
            fi
        else
            if [ -f "${PATH_TO_REMOVE}" ]; then
                run-as-su rm "${PATH_TO_REMOVE}"
            else
                run-as-su rm -r "${PATH_TO_REMOVE}"
            fi
        fi
    done
}

function create_symlink() {
    local SOURCE="${1}"
    local TARGET="${2}"

    [ ! -e "${SOURCE}" ] && return
    [ -e "${TARGET}" ] && return

    echo -e "Linking \e[0;33m${SOURCE}\e[0m → \e[0;33m${TARGET}\e[0m..."
    ln -s "${SOURCE}" "${TARGET}"
}

function read-file() {
    local FILE_PATH="${*}"

    if [ -r "${FILE_PATH}" ]; then
        cat "${FILE_PATH}"
    else
        run-as-su cat "${FILE_PATH}"
    fi
}

function file-append-line() {
    local FILE_PATH="${1}"
    local LINE="${@:2}"

    if [ -w "${FILE_PATH}" ]; then
        echo "${LINE}" >> "${FILE_PATH}" 2>/dev/null
    else
        echo "${LINE}" | run-as-su tee -a "${FILE_PATH}" >/dev/null
    fi
}

function download-file {
    local URL="${1}"
    local FILE="${2}"

    [ ! -f "${FILE}" ] && wget "${URL}" -O "${FILE}"
}

function get-file-checksum() {
    [ ! -f "${@}" ] && return
    sha512sum "${@}" | awk '{print $1}'
}

function does-file-need-updating() {
    local SOURCE_FILE_PATH="${1}"
    local TARGET_FILE_PATH="${2}"
    local FILES_ARE_SAME=false

    [ ! -f "${SOURCE_FILE_PATH}" ] && return 1 # False
    [ ! -f "${TARGET_FILE_PATH}" ] && return 0 # True

    if [ -f "${TARGET_FILE_PATH}" ]; then
        local SOURCE_FILE_CHECKSUM=$(get-file-checksum "${SOURCE_FILE_PATH}")
        local TARGET_FILE_CHECKSUM=$(get-file-checksum "${TARGET_FILE_PATH}")

        if [ "${SOURCE_FILE_CHECKSUM}" = "${TARGET_FILE_CHECKSUM}" ]; then
            FILES_ARE_SAME=true
        fi
    fi

    if ${FILES_ARE_SAME}; then
        return 1 # False
    else
        return 0 # True
    fi
}

function update-file-if-needed() {
    local SOURCE_FILE_PATH="${1}"
    local TARGET_FILE_PATH="${2}"
    local TARGET_DIR=$(dirname "${TARGET_FILE_PATH}")

    if $(does-file-need-updating "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"); then
        if [ ! -d "${TARGET_DIR}" ]; then
            echo "Creating the directory: ${TARGET_DIR}" >&2
            mkdir -p "${TARGET_DIR}"
        fi

        echo -e "Copying \e[0;33m${SOURCE_FILE_PATH}\e[0m → \e[0;33m${TARGET_FILE_PATH}\e[0m..."
        if [ -w "${TARGET_DIR}" ]; then
            cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        else
            run-as-su cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        fi
    fi
}

# Architecture
ARCH="$(get_arch)"
ARCH_FAMILY="$(get_arch_family ${ARCH})"

# System characteristics
CPU_MODEL="$(get_cpu_model)"

CHASSIS_TYPE="$(get_chassis_type)"
POWERFUL_PC=false
IS_DEVELOPMENT_DEVICE=false
IS_GENERAL_PURPOSE_DEVICE=true
IS_GAMING_DEVICE=false
HAS_GUI=true
HAS_SU_PRIVILEGES=true
HAS_EFI_SUPPORT=false

if [ "${CHASSIS_TYPE}" = "Phone" ]; then
    POWERFUL_PC=false
    IS_GENERAL_PURPOSE_DEVICE=true
    IS_GAMING_DEVICE=false
    HAS_GUI=true
    HAS_SU_PRIVILEGES=false
    HAS_EFI_SUPPORT=false
else
    if [ "${ARCH_FAMILY}" = "x86" ]; then
        if [ -n "${CPU_MODEL}" ] && [ $(echo ${CPU_MODEL} | grep -c "Atom") -le 1 ]; then
            POWERFUL_PC=true
        fi
    fi

    if ${POWERFUL_PC}; then
        if [ "${CPU_MODEL}" = "Ryzen 7 5800X" ]; then
            IS_GAMING_DEVICE=true
            HAS_GUI=true
        else
            IS_GAMING_DEVICE=false
        fi
    fi

    [ -d "${ROOT_SYS}/firmware/efi/efivars" ] && HAS_EFI_SUPPORT=true
fi

if [ -f "${ROOT_ETC}/systemd/system/display-manager.service" ]; then
    HAS_GUI=true
elif ! ${HAS_GUI}; then
    case ${HOSTNAME} in
        *"PC")  HAS_GUI=true ;;
        *"Top") HAS_GUI=true ;;
        *)      HAS_GUI=false ;;
    esac
fi

if ${HAS_GUI}; then
    if does-bin-exist "code" "code-oss" "codium" "com.visualstudio.code" \
    || does-bin-exist "dotnet"; then
        IS_DEVELOPMENT_DEVICE=true
    fi

    if does-bin-exist "steam" "com.valvesoftware.Steam"; then
        IS_GAMING_DEVICE=true
    fi
else
    IS_GENERAL_PURPOSE_DEVICE=false
fi

if does-bin-exist "sudo"; then
    if [ "${DISTRO_FAMILY}" = "Android" ]; then
        [ -f "/sbin/su" ] && HAS_SU_PRIVILEGES=true
    else
        HAS_SU_PRIVILEGES=true
    fi
else
    HAS_SU_PRIVILEGES=false
fi

[ "${UID}" -eq 0 ] && HAS_SU_PRIVILEGES=true

# Username and home directory
USER_REAL=${SUDO_USER}
[ -z "${USER_REAL}" ] && USER_REAL=${USER}

HOME_REAL=$(grep "${USER_REAL}" "${ROOT_PATH}/etc/passwd" 2>/dev/null | cut -f6 -d":")
[ "${USER_REAL}" = "root" ] && HOME_REAL="${ROOT_PATH}/root"

if [ ! -d "${HOME_REAL}" ]; then
    if [ -d "/data/data/com.termux/files/home" ]; then
        HOME_REAL="/data/data/com.termux/files/home"
    else
        HOME_REAL="/home/${USER_REAL}"
    fi
fi
