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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${REPO_DIR}/scripts/common/package-managements.sh"
    source "${REPO_DIR}/scripts/common/system-info.sh"
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

[ "${DISTRO_FAMILY}" = "Android" ] && ROOT_USR="${ROOT_PATH}"

ROOT_USR_BIN="${ROOT_USR}/bin"
ROOT_USR_LIB="${ROOT_USR}/lib"
ROOT_USR_SHARE="${ROOT_USR}/share"
ROOT_VAR="${ROOT}/var"
ROOT_VAR_LIB="${ROOT_VAR}/lib"

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

[ -z "${HOME}" ] && HOME="${HOME_REAL}"

HOME_CACHE="${HOME_REAL}/.cache"
HOME_CONFIG="${HOME_REAL}/.config"
HOME_DOCUMENTS="${HOME_REAL}/Documents"
HOME_DOWNLOADS="${HOME_REAL}/Downloads"
HOME_LOCAL="${HOME_REAL}/.local"
HOME_LOCAL_BIN="${HOME_LOCAL}/bin"
HOME_LOCAL_SHARE="${HOME_LOCAL}/share"
HOME_MUSIC="${HOME_REAL}/Music"
HOME_PICTURES="${HOME_REAL}/Pictures"
HOME_TEMPLATES="${HOME_REAL}/Templates"
HOME_VAR="${HOME_REAL}/.var"
HOME_VIDEOS="${HOME_REAL}/Videos"

# Functions
function does_bin_exist () {
    for BINARY_NAME in "${@}"; do
        if [ -f "${ROOT_BIN}/${BINARY_NAME}" ] \
        || [ -f "${ROOT_USR_BIN}/${BINARY_NAME}" ] \
        || [ -f "${ROOT_VAR_LIB}/flatpak/exports/bin/${BINARY_NAME}" ] \
        || [ -f "${HOME_LOCAL_BIN}/${BINARY_NAME}" ] \
        || [ -f "${HOME_LOCAL_SHARE}/flatpak/exports/bin/${BINARY_NAME}" ]; then
            return 0 # True
        fi
    done

    if echo "${BINARY_NAME}" | grep -q "^/" \
    && [ -f "${BINARY_NAME}" ]; then
        return 0 # True
    fi

    return 1 # False
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
                run_as_su rm "${PATH_TO_REMOVE}"
            else
                run_as_su rm -r "${PATH_TO_REMOVE}"
            fi
        fi
    done
}

function create_file() {
    local FILE_PATH="${*}"

    [ -z "${FILE_PATH}" ] && return
    [ -f "${FILE_PATH}" ] && return

    local DIRECTORY_PATH="$(dirname ${FILE_PATH})"

    mkdir -p "${DIRECTORY_PATH}"
    touch "${FILE_PATH}"
}

function create_symlink() {
    local SOURCE="${1}"
    local TARGET="${2}"

    [ ! -e "${SOURCE}" ] && return
    [ -e "${TARGET}" ] && return

    echo -e "Linking \e[0;33m${SOURCE}\e[0m → \e[0;33m${TARGET}\e[0m..."
    ln -s "${SOURCE}" "${TARGET}"
}

function get_symlink_target() {
    local SYMLINK="${1}"

    if [ ! -L "${SYMLINK}" ]; then
        echo "${SYMLINK}"
        return
    fi

    TARGET=$(readlink "${SYMLINK}")

    if [ -e "${TARGET}" ] \
    && echo "${TARGET}" | grep -q "^/.*"; then
        echo "${TARGET}"
    else
        SYMLINK_DIR=$(dirname "${SYMLINK}")
        readlink -m "${SYMLINK_DIR}/${TARGET}"
    fi
}

function read_file() {
    local FILE_PATH="${*}"

    if [ -r "${FILE_PATH}" ]; then
        cat "${FILE_PATH}"
    else
        run_as_su cat "${FILE_PATH}"
    fi
}

function append_line() {
    local FILE_PATH="${1}"
    local LINE="${@:2}"

    if [ -L "${FILE_PATH}" ]; then
        FILE_PATH=$(get_symlink_target "${FILE_PATH}")
    fi

    if [ -w "${FILE_PATH}" ]; then
        echo "${LINE}" >> "${FILE_PATH}" 2>/dev/null
    else
        echo "${LINE}" | run_as_su tee -a "${FILE_PATH}" >/dev/null
    fi
}

function download_file {
    local URL="${1}"
    local FILE="${2}"

    [ ! -f "${FILE}" ] && wget "${URL}" -O "${FILE}"
}

function get_file_checksum() {
    [ ! -f "${@}" ] && return
    sha512sum "${@}" | awk '{print $1}'
}

function does_file_need_updating() {
    local SOURCE_FILE_PATH="${1}"
    local TARGET_FILE_PATH="${2}"
    local FILES_ARE_SAME=false

    [ ! -f "${SOURCE_FILE_PATH}" ] && return 1 # False
    [ ! -f "${TARGET_FILE_PATH}" ] && return 0 # True

    if [ -f "${TARGET_FILE_PATH}" ]; then
        local SOURCE_FILE_CHECKSUM=$(get_file_checksum "${SOURCE_FILE_PATH}")
        local TARGET_FILE_CHECKSUM=$(get_file_checksum "${TARGET_FILE_PATH}")

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

function update_file_if_distinct() {
    local SOURCE_FILE_PATH="${1}"
    local TARGET_FILE_PATH="${2}"
    local TARGET_DIR=$(dirname "${TARGET_FILE_PATH}")

    if $(does_file_need_updating "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"); then
        if [ ! -d "${TARGET_DIR}" ]; then
            echo "Creating the directory: ${TARGET_DIR}" >&2
            mkdir -p "${TARGET_DIR}"
        fi

        echo -e "Copying \e[0;33m${SOURCE_FILE_PATH}\e[0m → \e[0;33m${TARGET_FILE_PATH}\e[0m..."
        if [ -w "${TARGET_DIR}" ]; then
            cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        else
            run_as_su cp "${SOURCE_FILE_PATH}" "${TARGET_FILE_PATH}"
        fi
    fi
}



# Specific directories
HOME_MOZILLA="${HOME_REAL}/.mozilla"

does_bin_exist "org.mozilla.firefox" && HOME_MOZILLA="${HOME_VAR}/app/org.mozilla.firefox/.mozilla"

GLOBAL_LAUNCHERS_DIR="${ROOT_USR_SHARE}/applications"
GLOBAL_FLATPAK_LAUNCHERS_DIR="${ROOT_VAR_LIB}/flatpak/exports/share/applications"
LOCAL_LAUNCHERS_DIR="${HOME_LOCAL_SHARE}/applications"

if does_bin_exist "steam" "org.valvesoftware.Steam"; then
    STEAM_DIR="${HOME_LOCAL_SHARE}/Steam"
    does_bin_exist "com.valvesoftware.Steam" && STEAM_DIR="${HOME_VAR}/app/com.valvesoftware.Steam/data/Steam"

    STEAM_LIBRARY_PATHS="${STEAM_DIR}/steamapps"
    STEAM_LAUNCHERS_PATH="${LOCAL_LAUNCHERS_DIR}/Steam"
fi
