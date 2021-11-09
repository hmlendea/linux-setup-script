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

    does-systemd-service-exist-at-location "${SERVICE_NAME}" "/etc/systemd/system" && return 0
    does-systemd-service-exist-at-location "${SERVICE_NAME}" "/lib/systemd/system" && return 0
    does-systemd-service-exist-at-location "${SERVICE_NAME}" "/usr/lib/systemd/system" && return 0

    return 1 # False
}

function enable-service {
    local SERVICE_NAME="${*}"

    if [ -f "${ROOT_USR_BIN}/systemctl" ]; then
        (! does-systemd-service-exist "${SERVICE_NAME}") && return

        systemctl enable "${SERVICE_NAME}"
        systemctl start "${SERVICE_NAME}"
    fi
}

[ -f "${ROOT_USR_BIN}/cupsd" ]                                     && enable-service "cups.service"
[ -f "${ROOT_USR_BIN}/thermald" ]                                  && enable-service "thermald.service"
[ -f "${ROOT_USR_BIN}/networkctl" ]                                && enable-service "NetworkManager.service"
[ -f "${ROOT_USR_BIN}/ntpd" ]                                      && enable-service "ntpd.service"
[ -f "${ROOT_USR_LIB}/systemd/system/systemd-timesyncd.service" ]  && enable-service "systemd-timesyncd.service"
[ -f "${ROOT_USR_LIB}/systemd/system/yaourt-auto-sync.timer" ]     && enable-service "yaourt-auto-sync.timer"
[ -f "${ROOT_LIB}/systemd/system/sshd.service" ]                   && enable-service "sshd.service"
[ -f "${ROOT_USR_BIN}/blueman" ]                                   && enable-service "bluetooth.service"
