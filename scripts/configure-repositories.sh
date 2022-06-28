#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

PACMAN_CONF_FILE_PATH="${ROOT_ETC}/pacman.conf"
DATABASES_NEED_UPDATING=false

function add_repository {
    local NAME="${1}"
    local SERVER="${2}"
    local INCLUDE="${3}"
    local SIGLEVEL="${4}"
    local KEY="${5}"

    [ ! -f "${PACMAN_CONF_FILE_PATH}" ] && return

    if [ ! $(grep "^\[${NAME}\]" "${PACMAN_CONF_FILE_PATH}") ]; then
        echo "Adding the \"${NAME}\" repository to \"${PACMAN_CONF_FILE_PATH}\"..." >&2

        DATABASES_NEED_UPDATING=true

        append_line "${PACMAN_CONF_FILE_PATH}" ""
        append_line "${PACMAN_CONF_FILE_PATH}" "[${NAME}]"

        [ -n "${SERVER}" ]    && append_line "${PACMAN_CONF_FILE_PATH}" "Server = ${SERVER}"
        [ -n "${INCLUDE}" ]   && append_line "${PACMAN_CONF_FILE_PATH}" "Include = ${INCLUDE}"
        [ -n "${SIGLEVEL}" ]  && append_line "${PACMAN_CONF_FILE_PATH}" "SigLevel = ${SIGLEVEL}"

        if [ -n "${KEY}" ]; then
            pacman-key --recv-keys "${KEY}"
            pacman-key --finger "${KEY}"
            pacman-key --lsign "${KEY}"
        fi
    fi
}

function add_system_flatpak_remote() {
    local REMOTE_NAME="${1}"
    local REMOTE_URL="${2}"

    if ! flatpak remotes | grep -q "^${REMOTE_NAME}\s"; then
        echo -e "Adding the \e[0;33m${REMOTE_NAME}\e[0m system flatpak remote..."
        update_file_if_distinct "${REPO_DATA_DIR}/flatpak/keys/${REMOTE_NAME}" "${ROOT_VAR_LIB}/flatpak/repo/${REMOTE_NAME}.trustedkeys.gpg"
        run_as_su flatpak remote-add --if-not-exists "${REMOTE_NAME}" "${REMOTE_URL}"
    fi
}

function add_user_flatpak_remote() {
    local REMOTE_NAME="${1}"
    local REMOTE_URL="${2}"

    if ! flatpak remotes | grep -q "^${REMOTE_NAME}\s"; then
        echo -e "Adding the \e[0;33m${REMOTE_NAME}\e[0m user flatpak remote..."
        update_file_if_distinct "${REPO_DATA_DIR}/flatpak/keys/${REMOTE_NAME}" "${XDG_DATA_HOME}/flatpak/repo/${REMOTE_NAME}.trustedkeys.gpg"
        flatpak remote-add --user --if-not-exists "${REMOTE_NAME}" "${REMOTE_URL}"
    fi
}

if does_bin_exist "flatpak"; then
    add_system_flatpak_remote   "zorinos" "https://flatpak.zorinos.com/repo/"
    add_user_flatpak_remote     "flathub-beta" "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    add_repository "hmlendea" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"

    if [[ "${ARCH_FAMILY}" == "arm" ]]; then
        if [[ "${ARCH}" == "aarch64" ]]; then
            add_repository "hmlendea-aarch64" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
        fi

        if [[ "${ARCH}" == "armv7h" ]] || [[ "${ARCH}" == "armv7l" ]]; then
            add_repository "hmlendea-armv7h" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
        fi
    fi

    if [[ "${ARCH_FAMILY}" == "x86" ]]; then
        add_repository "multilib" "" "${ROOT_ETC}/pacman.d/mirrorlist"
        add_repository "valveaur" "http://repo.steampowered.com/arch/valveaur/" "" "" "8DC2CE3A3D245E64"
        add_repository "dx37essentials" 'https://dx37.gitlab.io/$repo/$arch' "" "PackageOptional" # For things like ttf-ms-win10

        if [[ "${ARCH}" == "x86_64" ]]; then
            add_repository "hmlendea-x86_64" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
        fi
    fi
fi
