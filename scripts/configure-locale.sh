#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

LOCALE_GEN_FILE_PATH="${ROOT_ETC}/locale.gen"
LOCALE_CONF_FILE_PATH="${ROOT_ETC}/locale.conf"
VCONSOLE_CONF_FILE_PATH="${ROOT_ETC}/vconsole.conf"
KEYBOARD_LAYOUTS_PATH="${ROOT_USR_SHARE}/X11/xkb/symbols"

echo 'Setting up the console font and keymap...'
{
    echo 'FONT=eurlatgr'
    echo 'KEYMAP=ro-std'
} > "${VCONSOLE_CONF_FILE_PATH}"

echo 'Setting up the language...'
{
    echo 'LANG=en_GB.UTF-8'
    echo 'LC_CTYPE=en_US.UTF-8'
    echo 'LC_ADDRESS=ro_RO.UTF-8'
    echo 'LC_MEASUREMENT=ro_RO.UTF-8'
    echo 'LC_MONETARY=ro_RO.UTF-8'
    echo 'LC_NAME=ro_RO.UTF-8'
    echo 'LC_NUMERIC=ro_RO.UTF-8'
    echo 'LC_TIME=ro_RO.UTF-8'
} > "${LOCALE_CONF_FILE_PATH}"

echo 'en_GB.UTF-8 UTF-8' >  "${LOCALE_GEN_FILE_PATH}"
echo 'en_US.UTF-8 UTF-8' >> "${LOCALE_GEN_FILE_PATH}"
echo 'ro_RO.UTF-8 UTF-8' >> "${LOCALE_GEN_FILE_PATH}"

for LOCALE in $(awk '{print $1}' "${LOCALE_GEN_FILE_PATH}" | sed -e 's/\([^\.]*\)\.\(.*\)/\1.\L\2/' | sed 's/-//'); do
    if [ ! $(locale -a | grep "${LOCALE}") ]; then
        echo 'Generating the localisations...'
        locale-gen
        break
    fi
done

# Update the X11 keyboard layout definitions
if ${HAS_GUI}; then
    if [ -d "${KEYBOARD_LAYOUTS_PATH}" ]; then
        echo 'Updating the keyboard layouts...'
        update_file_if_distinct "${REPO_KEYBOARD_LAYOUTS_DIR}/ro" "${KEYBOARD_LAYOUTS_PATH}/ro"
    fi
fi
