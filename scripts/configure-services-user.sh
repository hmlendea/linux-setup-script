#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

[[ "${DISTRO}" =~ 'WSL' ]] && exit

if [ "${OS}" =  'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
        if does_bin_exist 'gnome-software'; then
            mask_user_service 'gnome-software'
            mask_user_service 'gnome-software-monitor'
        fi

        mask_user_service 'ibus'
        mask_user_service 'org.gnome.SettingsDaemon.Sharing'
        mask_user_service 'org.gnome.SettingsDaemon.Smartcard'
        mask_user_service 'org.gnome.SettingsDaemon.UsbProtection'
        mask_user_service 'org.gnome.SettingsDaemon.Wacom'

        if ! ${POWERFUL_PC}; then
            mask_user_service 'tracker-miner-fs'
            mask_user_service 'tracker-extract'
            mask_user_service 'tracker-store'
        fi
    fi

    does_bin_exist 'localsearch' && mask_user_service 'localsearch-3'
    does_bin_exist 'obexctl' && mask_user_service 'obex'
    does_bin_exist 'pipewire' && disable_user_service 'filter-chain'
fi
