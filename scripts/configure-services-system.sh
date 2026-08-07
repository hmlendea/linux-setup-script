#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"

[[ "${DISTRO}" =~ 'WSL' ]] && exit


if [[ "${OS}" ==  'Linux' ]]; then
    enable_services \
        'bluetooth' \
        'cups' \
        'docker' \
        'fail2ban' \
        'fstrim.timer' \
        'repo-synchroniser.timer' \
        'sshd' \
        'systemd-timesyncd' \
        'thermald'
elif [[ "${OS}" == 'Android' ]]; then
    enable_service 'ssh-agent'
fi

if ${HAS_GUI}; then
    if does_bin_exist 'NetworkManager'; then
        enable_service 'NetworkManager'
        disable_service 'NetworkManager-wait-online'
    fi
else
    if does_bin_exist 'netctl'; then
        enable_service 'netctl-auto@wlan0'
        enable_service 'dhcpcd'
    fi
fi

if does_bin_exist 'chrony' 'chronyd'; then
    disable_service 'ntpd'
    disable_service 'systemd-timesyncd'

    if does_file_exist "${ROOT_USR_LIB}/systemd/system/chrony.service"; then
        enable_service 'chrony'
    elif does_file_exist "${ROOT_USR_LIB}/systemd/system/chronyd.service"; then
        enable_service 'chronyd'
    fi
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

disable_service 'nfs-blkmap'
disable_service 'rpcbind'
disable_service 'pcscd'
disable_service 'avahi-daemon'
disable_service 'ModemManager'
