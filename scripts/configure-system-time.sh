#!/bin/bash
source 'scripts/common/filesystem.sh'
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"

PREFERRED_TIMEZONE='Europe/Bucharest'

LOCALE_CONF_FILE_PATH="${ROOT_ETC}/locale.conf"
LOCALTIME_FILE_PATH="${ROOT_ETC}/localtime"

echo 'Setting up the time locale...'
{
    echo 'LC_TIME=ro_RO.UTF-8'
} > "${LOCALE_CONF_FILE_PATH}"

if does_bin_exist 'timedatectl'; then
    run_as_su timedatectl set-timezone "${PREFERRED_TIMEZONE}"
elif [ ! -f "${LOCALTIME_FILE_PATH}" ]; then
    echo 'Setting up the local time...'

    ln -sf "${ROOT_USER_SHARE}/zoneinfo/${PREFERRED_TIMEZONE}" "${LOCALTIME_FILE_PATH}"
fi

does_bin_exist 'hwclock' && hwclock --systohc
