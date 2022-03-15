#!/bin/bash
source "scripts/common/common.sh"

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

        file-append-line "${PACMAN_CONF_FILE_PATH}" ""
        file-append-line "${PACMAN_CONF_FILE_PATH}" "[${NAME}]"

        [ -n "${SERVER}" ]    && file-append-line "${PACMAN_CONF_FILE_PATH}" "Server = ${SERVER}"
        [ -n "${INCLUDE}" ]   && file-append-line "${PACMAN_CONF_FILE_PATH}" "Include = ${INCLUDE}"
        [ -n "${SIGLEVEL}" ]  && file-append-line "${PACMAN_CONF_FILE_PATH}" "SigLevel = ${SIGLEVEL}"

        if [ -n "${KEY}" ]; then
            pacman-key --recv-keys "${KEY}"
            pacman-key --finger "${KEY}"
            pacman-key --lsign "${KEY}"
        fi
    fi
}

function add_flatpak_remote() {
    local REMOTE_NAME="${1}"
    local REMOTE_URL="${2}"

    if ! flatpak remotes | grep -q "^${REMOTE_NAME}\s"; then
        cp "${REPO_DATA_DIR}/flatpak/keys/${REMOTE_NAME}" "${ROOT_VAR_LIB}/flatpak/repo/${REMOTE_NAME}.trustedkeys.gpg"
        flatpak remote-add --if-not-exists "${REMOTE_NAME}" "${REMOTE_URL}"
    fi
}

add_flatpak_remote "zorinos" "https://flatpak.zorinos.com/repo/"
exit

add_repository "hmlendea" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"

if [[ "${ARCH}" == "aarch64" ]]; then
    add_repository "hmlendea-aarch64" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
fi

if [[ "${ARCH}" == "armv7h" ]] || [[ "${ARCH}" == "armv7l" ]]; then
    add_repository "hmlendea-armv7h" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
fi

if [[ "${ARCH}" == "x86_64" ]]; then
    add_repository "hmlendea-x86_64" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
fi

if [[ "${ARCH_FAMILY}" == "x86" ]]; then
    add_repository "multilib" "" "${ROOT_ETC}/pacman.d/mirrorlist"
    add_repository "valveaur" "http://repo.steampowered.com/arch/valveaur/" "" "" "8DC2CE3A3D245E64"
    add_repository "dx37essentials" 'https://dx37.gitlab.io/$repo/$arch' "" "PackageOptional" # For things like ttf-ms-win10
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]] && ${DATABASES_NEED_UPDATING}; then
    pacman -Syy
fi

does-bin-exist "pkgfile" && pkgfile -u
