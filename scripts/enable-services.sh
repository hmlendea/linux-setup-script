#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/service-management.sh"

enable_service "bluetooth"
enable_service "cups"
enable_service "docker"
enable_service "ntpd"
enable_service "repo-synchroniser.timer"
enable_service "systemd-timesyncd"
enable_service "thermald"

if does_bin_exist "NetworkManager"; then
    enable_service "NetworkManager"
    disable_service "NetworkManager-wait-online"
fi

if [ "${CHASSIS_TYPE}" = "Laptop" ]; then
    enable_service "tlp"
else
    disable_service "tlp"
fi

[[ ${HOSTNAME} = *Pi ]] && enable_service "sshd"
