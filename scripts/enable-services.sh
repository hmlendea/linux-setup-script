#!/bin/bash
source "scripts/_common.sh"

function enable-service {
    local SERVICE="${1}"

    if [ -f "${ROOT_USR_BIN}/systemctl" ]; then
        systemctl enable "${SERVICE}"
        systemctl start "${SERVICE}"
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
