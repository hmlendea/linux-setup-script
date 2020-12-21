#!/bin/bash

function enable-service {
    systemctl enable $1
    systemctl start $1
}

[ -f "/usr/bin/thermald" ]                              && enable-service "thermald.service"
[ -f "/usr/bin/ntpd" ]                                  && enable-service "ntpd.service"
[ -f "/usr/lib/systemd/system/yaourt-auto-sync.timer" ] && enable-service "yaourt-auto-sync.timer"
[ -f "/lib/systemd/system/sshd.service" ]               && enable-service "sshd.service"
[ -f "/usr/bin/blueman" ]                               && enable-service "bluetooth.service"
