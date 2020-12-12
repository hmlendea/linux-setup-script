#!/bin/bash
ARCH=${1}
PACMAN_CONF_FILE_PATH="/etc/pacman.conf"

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"

function append_to_conf {
    printf "$@" >> ${PACMAN_CONF_FILE_PATH}
}

DATABASES_NEED_UPDATING=false

function add_repository {
    NAME=${1}
    SERVER=${2}
    INCLUDE=${3}
    SIGLEVEL=${4}
    KEY=${5}

    if [ ! $(grep "^\[${NAME}\]" ${PACMAN_CONF_FILE_PATH}) ]; then
        echo "Adding the \"${NAME}\" repository to \"${PACMAN_CONF_FILE_PATH}\"..." >&2

        DATABASES_NEED_UPDATING=true

        append_to_conf "\n[${NAME}]\n"
        [ ! -z "${SERVER}" ]    && append_to_conf "Server = ${SERVER}\n"
        [ ! -z "${INCLUDE}" ]   && append_to_conf "Include = ${INCLUDE}\n"
        [ ! -z "${SIGLEVEL}" ]  && append_to_conf "SigLevel = ${SIGLEVEL}\n"

        if [ ! -z "${KEY}" ]; then
            pacman-key --recv-keys ${KEY}
            pacman-key --finger ${KEY}
            pacman-key --lsign ${KEY}
        fi
    fi
}

add_repository "hmlendea" "https://github.com/hmlendea/PKGBUILDs/releases/latest/download/" "" "Never"

if [ "${ARCH_FAMILY}" == "x86" ]; then
    add_repository "multilib" "" "/etc/pacman.d/mirrorlist"
    add_repository "valveaur" "http://repo.steampowered.com/arch/valveaur/" "" "" "8DC2CE3A3D245E64"
fi


if [ ${DATABASES_NEED_UPDATING} = true ]; then
    pacman -Syy
fi

