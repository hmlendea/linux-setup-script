#!/bin/bash
source "scripts/common/common.sh"

function does-systemd-service-exist-at-location {
    local SERVICE_NAME="${1}"
    local LOCATION="${2}"

    [ -f "${LOCATION}/${SERVICE_NAME}" ] && return 0
    [ -f "${LOCATION}/${SERVICE_NAME}.service" ] && return 0

    return 1 # False
}

function does-systemd-service-exist {
    local SERVICE_NAME="${*}"

    does-systemd-service-exist-at-location "${SERVICE_NAME}" "${ROOT_ETC}/systemd/system" && return 0
    does-systemd-service-exist-at-location "${SERVICE_NAME}" "${ROOT_LIB}/systemd/system" && return 0
    does-systemd-service-exist-at-location "${SERVICE_NAME}" "${ROOT_USR_LIB}/systemd/system" && return 0

    return 1 # False
}

function enable-service {
    [ ! -f "${ROOT_USR_BIN}/systemctl" ] && return

    local SERVICE_NAME="${*}"

    (! does-systemd-service-exist "${SERVICE_NAME}") && return

    run-as-su systemctl enable "${SERVICE_NAME}"
    run-as-su systemctl start "${SERVICE_NAME}"
}

function disable-service {
    [ ! -f "${ROOT_USR_BIN}/systemctl" ] && return

    local SERVICE_NAME="${*}"

    (! does-systemd-service-exist "${SERVICE_NAME}") && return

    run-as-su systemctl disable "${SERVICE_NAME}"
    run-as-su systemctl stop "${SERVICE_NAME}"
}

enable-service "bluetooth"
enable-service "cups"
enable-service "docker"
enable-service "NetworkManager"
enable-service "ntpd"
enable-service "repo-synchroniser.timer"
enable-service "systemd-timesyncd"
enable-service "thermald"

[[ ${HOSTNAME} = *Pi ]] && enable-service "sshd"
