#!/bin/bash
source 'scripts/common/filesystem.sh'

LOCALE_CONF_FILE_PATH="${ROOT_ETC}/locale.conf"
LOCALTIME_FILE_PATH="${ROOT_ETC}/localtime"

echo 'Setting up the time locale...'
{
    echo 'LC_TIME=ro_RO.UTF-8'
} > "${LOCALE_CONF_FILE_PATH}"

if [ ! -f "${LOCALTIME_FILE_PATH}" ]; then
    echo 'Setting up the local time...'

    ln -sf '/usr/share/zoneinfo/Europe/Bucharest' "${LOCALTIME_FILE_PATH}"
    does_bin_exist 'hwclock' && hwclock --systohc
fi
