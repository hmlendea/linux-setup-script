#!/bin/bash

LOCALE_GEN_FILE_PATH="/etc/locale.gen"
LOCALE_CONF_FILE_PATH="/etc/locale.conf"
VCONSOLE_CONF_FILE_PATH="/etc/vconsole.conf"
LOCALTIME_FILE_PATH="/etc/localtime"

echo "Generating the localisations..."
echo "en_GB.UTF-8 UTF-8" >  "${LOCALE_GEN_FILE_PATH}"
echo "en_US.UTF-8 UTF-8" >> "${LOCALE_GEN_FILE_PATH}"
echo "ro_RO.UTF-8 UTF-8" >> "${LOCALE_GEN_FILE_PATH}"
sudo locale-gen

echo "Setting up the keymap..."
echo "KEYMAP=ro-std" > "${VCONSOLE_CONF_FILE_PATH}"

echo "Setting up the language..."
echo "LANG=en_GB.UTF-8" > "${LOCALE_CONF_FILE_PATH}"

if [ ! -f "${LOCALTIME_FILE_PATH}" ]; then
    echo "Setting up the local time..."

    ln -sf "/usr/share/zoneinfo/Europe/Bucharest" "${LOCALTIME_FILE_PATH}"
    hwclock --systohc
fi
