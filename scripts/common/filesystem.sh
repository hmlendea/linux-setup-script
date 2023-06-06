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
REPO_SCRIPTS_COMMON_DIR="${REPO_SCRIPTS_DIR}/common"

REPO_KEYBOARD_LAYOUTS_DIR="${REPO_RC_DIR}/keyboard-layouts"

LOCAL_INSTALL_TEMP_DIR="${REPO_DIR}/.temp-sysinstall"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "${REPO_DIR}/scripts/common/package-managements.sh"
    source "${REPO_DIR}/scripts/common/system-info.sh"
fi

# Root partition mount point
ROOT_PATH=""
[ -d "/data/data/com.termux/files/usr" ] && ROOT_PATH="/data/data/com.termux/files/usr"

ROOT_BIN="${ROOT_PATH}/bin"
ROOT_BOOT="${ROOT_PATH}/boot"
ROOT_ETC="${ROOT_PATH}/etc"
ROOT_LIB="${ROOT_PATH}/lib"
ROOT_OPT="${ROOT_PATH}/opt"
ROOT_PROC="${ROOT_PATH}/proc"
ROOT_SRV="${ROOT_PATH}/srv"
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

[ -z "${HOME}" ]                && HOME="${HOME_REAL}"

[ -z "${XDG_CACHE_HOME}" ]      && XDG_CACHE_HOME="${HOME_REAL}/.cache"
[ -z "${XDG_CONFIG_HOME}" ]     && XDG_CONFIG_HOME="${HOME_REAL}/.config"
[ -z "${XDG_DATA_HOME}" ]       && XDG_DATA_HOME="${HOME_REAL}/.local/share"
[ -z "${XDG_STATE_HOME}" ]      && XDG_STATE_HOME="${HOME_REAL}/.local/state"

function configure_xdg_directory() {
    local XDG_DIR="${1}" && shift
    local XDG_VARIABLE_NAME="XDG_${XDG_DIR}_DIR"

    local XDG_DIR_PATH=""

    [ -f "${XDG_CONFIG_DIR}/user-dirs.dirs" ] && XDG_DIR_PATH=$(cat "${XDG_CONFIG_DIR}/user-dirs.dirs" | grep "${XDG_VARIABLE_NAME}" | awk -F"=" '{print $2}')

    while [ -z "${XDG_DIR_PATH}" ] && [ -n "${1}" ]; do
        [ -e "${1}" ] && XDG_DIR_PATH="${1}"
        shift
    done

    eval "${XDG_VARIABLE_NAME}=\"${XDG_DIR_PATH}\""
}

configure_xdg_directory "DESKTOP"       "${HOME_REAL}/Desktop"
configure_xdg_directory "DOCUMENTS"     "${HOME_REAL}/Documente"    "${HOME_REAL}/Documents"
configure_xdg_directory "DOWNLOAD"      "${HOME_REAL}/Descărcări"   "${HOME_REAL}/Downloads"
configure_xdg_directory "MUSIC"         "${HOME_REAL}/Muzică"       "${HOME_REAL}/Music"
configure_xdg_directory "PICTURES"      "${HOME_REAL}/Poze"         "${HOME_REAL}/Pictures"
configure_xdg_directory "PUBLICSHARE"   "${HOME_REAL}/Public"
configure_xdg_directory "TEMPLATES"     "${HOME_REAL}/Șabloane"     "${HOME_REAL}/Templates"
configure_xdg_directory "VIDEOS"        "${HOME_REAL}/Video"        "${HOME_REAL}/Videos"

HOME_LOCAL="${HOME_REAL}/.local"
HOME_LOCAL_BIN="${HOME_LOCAL}/bin"
HOME_VAR="${HOME_REAL}/.var"
HOME_VAR_APP="${HOME_VAR}/app"

# Functions
function does_bin_exist () {
    for BINARY_NAME in "${@}"; do
        for PATH_DIR in $(echo "${PATH}" | sed 's/:/\n/g'); do
            [ -f "${PATH_DIR}/${BINARY_NAME}" ] && return 0 # True
        done

        if echo "${BINARY_NAME}" | grep -q "^/" \
        && [ -f "${BINARY_NAME}" ]; then
            return 0 # True
        fi
    done

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
            continue
        fi

        local SIZE="4,0K"
        if [ -w "${PATH_TO_REMOVE}" ]; then
            SIZE=$(run_as_su du -sh "${PATH_TO_REMOVE}" | awk '{print $1}')
        else
            SIZE=$(du -sh "${PATH_TO_REMOVE}" | awk '{print $1}')
        fi

        echo -e "Removing \e[0;33m${PATH_TO_REMOVE}\e[0m (${SIZE})..."
        if [ -w "${PATH_TO_REMOVE}" ]; then
            if [ -f "${PATH_TO_REMOVE}" ]; then
                yes | rm "${PATH_TO_REMOVE}"
            else
                yes | rm -r "${PATH_TO_REMOVE}"
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

function remove_dir_if_empty() {
    local PATH_TO_REMOVE="${*}"
    PATH_TO_REMOVE=$(echo "${PATH_TO_REMOVE}" | sed \
                        -e 's/^\s*//g' \
                        -e 's/\s*$//g')

    remove_empty_subdirectories "${PATH_TO_REMOVE}"

    [ ! -d "${PATH_TO_REMOVE}" ] && return

    local DIR_CONTENTS=$(ls -A "${PATH_TO_REMOVE}")

    [ -z "${DIR_CONTENTS}" ] && remove "${PATH_TO_REMOVE}"
}

function remove_empty_subdirectories() {
    local PARENT_DIRECTORY="${*}"

    [ ! -d "${PARENT_DIRECTORY}" ] && return

    while IFS='' read -r -d '' SUB_DIRECTORY; do
        [ ! -d "${SUB_DIRECTORY}" ] && continue
        SUB_DIRECTORY_CONTENTS=$(ls -A "${SUB_DIRECTORY}")
        if [ -z "${SUB_DIRECTORY_CONTENTS}" ]; then
            remove "${SUB_DIRECTORY}"
        fi
    done < <(find "${PARENT_DIRECTORY}" -maxdepth 1 -type d -print0)
}

function remove_logs_in_dir() {
    [ ! -d "${DIR}" ] && return

    remove \
        "${DIR}/logs" \
        "${DIR}/_logs" \
        "${DIR}"/*-log.txt \
        "${DIR}"/*_log.txt \
        "${DIR}"/*-log-*.txt \
        "${DIR}"/*_log_*.txt \
        "${DIR}"/*-logs-*.txt \
        "${DIR}"/*_logs_*.txt \
        "${DIR}"/*.log \
        "${DIR}"/*.log.old \
        "${DIR}"/changelog.txt \
        "${DIR}"/log.txt \
        "${DIR}"/logs.txt \
        "${DIR}"/logfile.txt
}

function remove_logs_in_dirs() {
    for DIR in "${@}"; do
        remove_logs_in_dir "${DIR}"

        if [ -d "${DIR}/IndexedDB" ] \
        || [ -d "${DIR}/shared_proto_db" ]; then
            remove_logs_in_dir "${DIR}/IndexedDB"/*
            remove_logs_in_dir "${DIR}/File System"/*
            remove_logs_in_dir "${DIR}/File System"/*/*/*
            remove_logs_in_dir "${DIR}/Session Storage"
            remove_logs_in_dir "${DIR}/Service Worker/Database"
            remove_logs_in_dir "${DIR}/shared_proto_db"
            remove_logs_in_dir "${DIR}/shared_proto_db/metadata"
        fi
    done
}

function create_directory() {
    local DIRECTORY_PATH="${*}"

    [ -z "${DIRECTORY_PATH}" ] && return
    [ -d "${DIRECTORY_PATH}" ] && return
    
    echo -e "Creating directory \e[0;33m${DIRECTORY_PATH}\e[0m..."
    mkdir -p "${DIRECTORY_PATH}"
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

    echo -e "Creating link \e[0;33m${TARGET}\e[0m →  \e[0;33m${SOURCE}\e[0m..."
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

does_bin_exist "org.mozilla.firefox" && HOME_MOZILLA="${HOME_VAR_APP}/org.mozilla.firefox/.mozilla"

GLOBAL_LAUNCHERS_DIR="${ROOT_USR_SHARE}/applications"
GLOBAL_FLATPAK_LAUNCHERS_DIR="${ROOT_VAR_LIB}/flatpak/exports/share/applications"
LOCAL_LAUNCHERS_DIR="${XDG_DATA_HOME}/applications"
LOCAL_FLATPAK_LAUNCHERS_DIR="${XDG_DATA_HOME}/flatpak/exports/share/applications"

if does_bin_exist "steam" "com.valvesoftware.Steam"; then
    STEAM_DIR="${XDG_DATA_HOME}/Steam"
    does_bin_exist "com.valvesoftware.Steam" && STEAM_DIR="${HOME_VAR_APP}/com.valvesoftware.Steam/.local/share/Steam"

    STEAM_LIBRARY_PATHS="${STEAM_DIR}/steamapps"
    STEAM_LAUNCHERS_PATH="${LOCAL_LAUNCHERS_DIR}/Steam"

    STEAM_LIBRARY_CUSTOM_PATHS=$(grep "\"/" "${STEAM_DIR}/steamapps/libraryfolders.vdf")

    if [ -n "${STEAM_LIBRARY_CUSTOM_PATHS}" ]; then
        STEAM_LIBRARY_CUSTOM_PATHS=$(echo "${STEAM_LIBRARY_CUSTOM_PATHS}" | \
                                        sed 's/\"[0-9]\"//g' | \
                                        sed 's/^ *//g' | \
                                        sed 's/\t//g' | \
                                        sed 's/\"//g' | \
                                        sed 's/^ *path *//g' | \
                                        sed 's/$/\/steamapps/g')
        STEAM_LIBRARY_PATHS=$(echo -e "${STEAM_LIBRARY_PATHS}\n${STEAM_LIBRARY_CUSTOM_PATHS}" | sort | uniq)
    fi
fi

# Configuration files
SYSTEM_PHP_CONFIG_FILE="${ROOT_ETC}/php/php.ini"
NEXTCLOUD_PHP_CONFIG_FILE="${ROOT_ETC}/webapps/nextcloud/php.ini"
MARIADB_SERVER_CONFIG_FILE="${ROOT_ETC}/my.cnf.d/server.cnf"

[ ! -f "${SYSTEM_PHP_CONFIG_FILE}" ] && SYSTEM_PHP_CONFIG_FILE="${ROOT_ETC}/php-legacy/php.ini"
