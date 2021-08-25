#!/bin/bash

function enable-service {
    local SERVICE="${1}"

    systemctl enable "${SERVICE}"
    systemctl start "${SERVICE}"
}

[ -f "/usr/bin/cupsd" ]                                     && enable-service "cups.service"
[ -f "/usr/bin/thermald" ]                                  && enable-service "thermald.service"
[ -f "/usr/bin/networkctl" ]                                && enable-service "NetworkManager.service"
[ -f "/usr/bin/ntpd" ]                                      && enable-service "ntpd.service"
[ -f "/usr/lib/systemd/system/systemd-timesyncd.service" ]  && enable-service "systemd-timesyncd.service"
[ -f "/usr/lib/systemd/system/yaourt-auto-sync.timer" ]     && enable-service "yaourt-auto-sync.timer"
[ -f "/lib/systemd/system/sshd.service" ]                   && enable-service "sshd.service"
[ -f "/usr/bin/blueman" ]                                   && enable-service "bluetooth.service"
