#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"

[[ "${DISTRO}" =~ 'WSL' ]] && exit

enable_service 'bluetooth'
enable_service 'cups'
enable_service 'docker'
enable_service 'fstrim.timer'
enable_service 'repo-synchroniser.timer'
enable_service 'systemd-timesyncd'
enable_service 'thermald'

if ${HAS_GUI}; then
    if does_bin_exist 'NetworkManager'; then
        enable_service 'NetworkManager'
        disable_service 'NetworkManager-wait-online'
    fi
fi

if does_bin_exist 'chronyd'; then
    disable_service 'ntpd'
    disable_service 'systemd-timesyncd'
    enable_service 'chronyd'
elif does_bin_exist 'ntpd'; then
    enable_service 'ntpd'
    disable_service 'systemd-timesyncd'
elif does_bin_exist 'systemd-timesyncd'; then
    enable_service 'systemd-timesyncd'
fi

if [ "${CHASSIS_TYPE}" = 'Laptop' ]; then
    enable_service 'tlp'
else
    disable_service 'tlp'
fi

[[ ${HOSTNAME} = *Pi ]] && enable_service 'sshd'
