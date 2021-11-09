#!/bin/bash
source "scripts/common/common.sh"

PACMAN_CONF_FILE_PATH="${ROOT_ETC}/pacman.conf"
DATABASES_NEED_UPDATING=false

function add_repository {
    NAME="${1}"
    SERVER="${2}"
    INCLUDE="${3}"
    SIGLEVEL="${4}"
    KEY="${5}"

    [ ! -f "${PACMAN_CONF_FILE_PATH}" ] && return

    if [ ! $(grep "^\[${NAME}\]" "${PACMAN_CONF_FILE_PATH}") ]; then
        echo "Adding the \"${NAME}\" repository to \"${PACMAN_CONF_FILE_PATH}\"..." >&2

        DATABASES_NEED_UPDATING=true

        file-append-line "${PACMAN_CONF_FILE_PATH}" ""
        file-append-line "${PACMAN_CONF_FILE_PATH}" "[${NAME}]"

        [ -n "${SERVER}" ]    && append_to_conf "Server = ${SERVER}\n"
        [ -n "${INCLUDE}" ]   && append_to_conf "Include = ${INCLUDE}\n"
        [ -n "${SIGLEVEL}" ]  && append_to_conf "SigLevel = ${SIGLEVEL}\n"

        if [ -n "${KEY}" ]; then
            pacman-key --recv-keys "${KEY}"
            pacman-key --finger "${KEY}"
            pacman-key --lsign "${KEY}"
        fi
    fi
}

add_repository "hmlendea" 'https://github.com/hmlendea/PKGBUILDs/releases/latest/download/' "" "Never"
add_repository "dx37essentials" 'https://dx37.gitlab.io/$repo/$arch' "" "PackageOptional" # Fot things like ttf-ms-win10

if [ "${ARCH_FAMILY}" == "x86" ]; then
    add_repository "multilib" "" "${ROOT_ETC}/pacman.d/mirrorlist"
    add_repository "valveaur" "http://repo.steampowered.com/arch/valveaur/" "" "" "8DC2CE3A3D245E64"
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]] && ${DATABASES_NEED_UPDATING}; then
    pacman -Syy
fi

does-bin-exist "pkgfile" && pkgfile -u
