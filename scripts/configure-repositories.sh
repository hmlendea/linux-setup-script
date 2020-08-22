#!/bin/bash
ARCH=${1}
PACMAN_CONF_FILE_PATH="/etc/pacman.conf"

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"

function append_to_conf {
    printf "$@" >> ${PACMAN_CONF_FILE_PATH}
}

function add_repository {
    NAME=${1}
    SERVER=${2}
    SIGLEVEL=${3}
    INCLUDE=${4}

    if [ ! $(grep "^\[${NAME}\]" ${PACMAN_CONF_FILE_PATH}) ]; then
        echo "Adding the \"${NAME}\" repository to \"${PACMAN_CONF_FILE_PATH}\"..." >&2

        append_to_conf "\n[${NAME}]\n"
        [ ! -z "${SERVER}" ]    && append_to_conf "Server = ${SERVER}\n"
        [ ! -z "${INCLUDE}" ]   && append_to_conf "Include = ${INCLUDE}\n"
        [ ! -z "${SIGLEVEL}" ]  && append_to_conf "SigLevel = ${SIGLEVEL}\n"
    fi
}

add_repository "hmlendea" "https://github.com/hmlendea/PKGBUILDs/releases/latest/download/" "Never"

if [ "${ARCH_FAMILY}" == "x86" ]; then
    add_repository "multilib" "" "" "/etc/pacman.d/mirrorlist"
    add_repository "valveaur" "http://repo.steampowered.com/arch/valveaur/"
fi

if [ "${ARCH_FAMILY}" == "arm" ]; then
    add_repository "arch4edu" "https://mirrors.tuna.tsinghua.edu.cn/arch4edu/\$arch"
fi
