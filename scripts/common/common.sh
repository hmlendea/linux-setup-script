#!/bin/bash

# Get local path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$EXEDIR/$SOURCE"
done
REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
REPO_DIR=$(realpath "${REPO_DIR}/../..")

REPO_DATA_DIR="${REPO_DIR}/data"
REPO_RC_DIR="${REPO_DIR}/rc"
REPO_SCRIPTS_DIR="${REPO_DIR}/scripts"

REPO_KEYBOARD_LAYOUTS_DIR="${REPO_RC_DIR}/keyboard-layouts"

# Distribution
KERNEL_VERSION=$(uname -r)

if [ -f "/etc/os-release" ]; then
    DISTRO=$(grep "^ID" "/etc/os-release" | tail -n 1 | awk -F'=' '{print $2}')
else
    DISTRO=$(echo "${KERNEL_VERSION}" | sed -e 's/^[^-]*-//g' -e 's/^[0-9][0-9]*-//g' -e 's/raspberrypi-//g' -e 's/-[0-9]*$//g' -e 's/-[a-z0-9]*$//g')
fi

OS=$(uname -s)

if [ "${DISTRO}" == "lineageos" ] || [ $(uname -a | grep -c "Android") -ge 1 ]; then
    DISTRO_FAMILY="android"
    OS="Android"
fi

[ "${DISTRO}" == "ARCH" ] && DISTRO="arch"
[ "${DISTRO}" == "arch" ] && DISTRO_FAMILY="arch"

if [ "${OS}" == "CYGWIN_NT-10.0" ]; then
    DISTRO="Cygwin"
    DISTRO_FAMILY="Windows"
    OS="Windows"
fi

# Root partition mount point
ROOT_PATH=""
[ "${DISTRO_FAMILY}" == "android" ] && ROOT_PATH="/data/data/com.termux/files/usr"

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

# Functions
function does-bin-exist() {
    BINARY_NAME="${@}"

    if [ -f "${ROOT_BIN}/${BINARY_NAME}" ] \
    || [ -f "${ROOT_USR_BIN}/${BINARY_NAME}" ]; then
        return 0 # True
    fi

    return 1 # False
}

function run-as-su() {
    if [ "${UID}" == 0 ]; then
        "$@"
    elif ${HAS_SU_PRIVILEGES}; then
        sudo "$@"
    else
        echo "Failed to run '$@': Missing SU privileges!"
    fi
}

function remove() {
    if [ -w "${FILE}" ]; then
        rm $@
    else
        run-as-su rm $@
    fi
}

function file-append-line() {
    FILE_PATH="${1}"
    LINE="${@:2}"

    if [ -w "${FILE_PATH}" ]; then
        printf "${LINE}\n" >> "${FILE_PATH}" 2>/dev/null
    else
        echo "${LINE}" | run-as-su tee -a "${FILE_PATH}" >/dev/null
    fi
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

    if [ -f "${TARGET_FILE_PATH}" ]; then
        local SOURCE_FILE_CHECKSUM=$(get-file-checksum "${SOURCE_FILE_PATH}")
        local TARGET_FILE_CHECKSUM=$(get-file-checksum "${TARGET_FILE_PATH}")

        if [ "${SOURCE_FILE_CHECKSUM}" == "${TARGET_FILE_CHECKSUM}" ]; then
            FILES_ARE_SAME=true
        fi
    fi

    ${FILES_ARE_SAME} && return 1 || return 0
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

        echo "Copying \"${SOURCE_FILE_PATH}\" to \"${TARGET_FILE_PATH}\"..."
        if [ -w "${TARGET_FILE_PATH}" ]; then
            cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        else
            run-as-su cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        fi
    fi
}

# Architecture
ARCH=$(uname -m)

if [ -z "${ARCH}" ] && $(does-bin "uname"); then
    ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g' | sed 's/^ *//g')
fi

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv8l" ]   && ARCH_FAMILY="arm"

# System characteristics
if $(does-bin-exist "lscpu" ); then
    CPU_MODEL=$(lscpu | \
        grep "^Model name:" | \
        awk -F: '{print $2}')
elif [ -f "${ROOT_PROC}/cpuinfo" ]; then
    CPU_MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
        grep "^model name" | \
        awk -F: '{print $2}')
fi

CPU_MODEL=$(echo "${CPU_MODEL}" | \
        head -n 1 | \
        sed 's/^\s*\(.*\)\s*$/\1/g' | \
        sed 's/(TM)//g' | \
        sed 's/(R)//g' | \
        sed 's/ CPU//g' | \
        sed 's/@ .*//g' | \
        sed 's/^[ \t]*//g' | \
        sed 's/[ \t]*$//g')

CHASSIS_TYPE="Desktop"
POWERFUL_PC=false
GAMING_PC=false
HAS_GUI=false
IS_EFI=0
HAS_SU_PRIVILEGES=true

if [ -d "${ROOT_SYS}/module/battery" ] \
&& [ -d "${ROOT_PROC}/acpi/button/lid" ]; then
    CHASSIS_TYPE="Laptop"
elif [ "${DISTRO_FAMILY}" == "android" ]; then
    CHASSIS_TYPE="Phone"
fi

if [ "${CHASSIS_TYPE}" == "Phone" ]; then
    POWERFUL_PC=false
    GAMING_PC=false
    IS_EFI=false
    HAS_SU_PRIVILEGES=false
else
    if [ "${ARCH_FAMILY}" == "x86" ]; then
        if [ -n "${CPU_MODEL}" ] && [ $(echo ${CPU_MODEL} | grep -c "Atom") -le 1 ]; then
            POWERFUL_PC=true
        fi
    fi

    if ${POWERFUL_PC}; then
        if [ "${CPU_MODEL}" == "Intel Core i7-3610QM" ]; then
            GAMING_PC=false
        elif [ -n "${CPU_MODE}" ]; then
            GAMING_PC=true
        fi
    fi

    [ -d "${ROOT_SYS}/firmware/efi/efivars" ] && IS_EFI=1
fi

if [ -f "${ROOT_ETC}/systemd/system/display-manager.service" ] || \
   [[ "${HOSTNAME}" = *PC ]] || \
   [[ "${HOSTNAME}" = *Top ]]; then
    HAS_GUI=true
fi

if $(does-bin-exist "sudo"); then
    if [ "${DISTRO_FAMILY}" == "android" ]; then
        [ -f "/sbin/su" ] && HAS_SU_PRIVILEGES=true
    else
        HAS_SU_PRIVILEGES=true
    fi
else
    HAS_SU_PRIVILEGES=false
fi

[ "${UID}" == 0 ] && HAS_SU_PRIVILEGES=true

# Username and home directory
USER_REAL=${SUDO_USER}
[ ! -n "${USER_REAL}" ] && USER_REAL=${USER}

HOME_REAL=$(grep "${USER_REAL}" "${ROOT_PATH}/etc/passwd" 2>/dev/null | cut -f6 -d":")
[ "${USER_REAL}" == "root" ] && HOME_REAL="${ROOT_PATH}/root"

if [ ! -d "${HOME_REAL}" ]; then
    if [ -d "/data/data/com.termux/files/home" ]; then
        HOME_REAL="/data/data/com.termux/files/home"
    else
        HOME_REAL="/home/${USER_REAL}"
    fi
fi
