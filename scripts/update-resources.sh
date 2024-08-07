#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/apps.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

if does_bin_exist 'firefox' 'firefox-esr' 'org.mozilla.firefox' 'io.gitlab.librewolf-community'; then
    FIREFOX_PROFILE_DIR="$(get_firefox_profile_dir)"

    if [ -d "${FIREFOX_PROFILE_DIR}" ]; then
        update_file_if_distinct "${REPO_RES_DIR}/firefox/containers.json" "${FIREFOX_PROFILE_DIR}/containers.json"
        update_file_if_distinct "${REPO_RES_DIR}/firefox/userChrome.css" "${FIREFOX_PROFILE_DIR}/chrome/userChrome.css"
    
        for ICON_FILE in "${REPO_RES_DIR}/firefox/icons/"*.png; do
            ICON_FILE_BASENAME=$(basename "${ICON_FILE}")
            update_file_if_distinct "${REPO_RES_DIR}/firefox/icons/${ICON_FILE_BASENAME}" "${FIREFOX_PROFILE_DIR}/chrome/icons/${ICON_FILE_BASENAME}"
        done
    fi
fi

if does_bin_exist 'git'; then
    for REPO_HOOK_FILE in "${REPO_RES_DIR}/git/hooks"/*; do
        REPO_HOOK_FILE_NAME=$(basename "${REPO_HOOK_FILE}")
        SYS_HOOK_FILE="${XDG_CONFIG_HOME}/git/hooks/${REPO_HOOK_FILE_NAME}"
        update_file_if_distinct "${REPO_HOOK_FILE}" "${SYS_HOOK_FILE}"
        chmod +x "${SYS_HOOK_FILE}"
    done
fi

if does_bin_exist 'lxpanel'; then
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/applications.png"                "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/applications.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/applications_ro.png"             "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/applications_ro.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/power.png"                       "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/power.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/lxde-logout-gnomified.desktop"   "${XDG_DATA_HOME}/applications/lxde-logout-gnomified.desktop"
fi

if does_bin_exist 'plank'; then
    update_file_if_distinct "${REPO_RES_DIR}/plank/dock.theme"                        "${XDG_DATA_HOME}/plank/themes/Hori/dock.theme"
fi

if does_bin_exist 'neofetch'; then
    NEOFETCH_CONFIG_DIR="${XDG_CONFIG_HOME}/neofetch"
    NEOFETCH_ASCII_LOGO_FILE=""

    if [ "${DISTRO}" = 'Arch Linux' ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-arch"
    elif [ "${DISTRO}" = 'LineageOS' ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-lineageos"
    fi

    [ -f "${NEOFETCH_ASCII_LOGO_FILE}" ] && update_file_if_distinct "${NEOFETCH_ASCII_LOGO_FILE}" "${NEOFETCH_CONFIG_DIR}/ascii"
fi

# PCManFM's context menu
if does_bin_exist 'pcmanfm'; then
    does_bin_exist 'code-oss'   && update_file_if_distinct "${REPO_RES_DIR}/pcmanfm/open-in-code.desktop"     "${XDG_DATA_HOME}/file-manager/actions/open-in-code.desktop"
    does_bin_exist 'lxterminal' && update_file_if_distinct "${REPO_RES_DIR}/pcmanfm/open-in-terminal.desktop" "${XDG_DATA_HOME}/file-manager/actions/open-in-terminal.desktop"
fi

# Templates
if ${HAS_GUI}; then
    update_file_if_distinct "${REPO_RES_DIR}/templates/file" "${XDG_TEMPLATES_DIR}/Blank file"

    if does_bin_exist 'libreoffice'; then
        update_file_if_distinct "${REPO_RES_DIR}/templates/doc" "${XDG_TEMPLATES_DIR}/Microsoft Document.doc"
        update_file_if_distinct "${REPO_RES_DIR}/templates/odt" "${XDG_TEMPLATES_DIR}/Document.odt"
    else
        remove "${XDG_TEMPLATES_DIR}/Microsoft Document.doc"
        remove "${XDG_TEMPLATES_DIR}/Document.odt"
    fi
fi

###########
WIFI_POWERSAVE_UDEV_RULES_FILE="${UDEV_RULES_DIR}/873-wifi_powersave.rules"

if [ "${CHASSIS_TYPE}" = 'Laptop' ]; then
    update_file_if_distinct "${REPO_RES_DIR}/udev/wifi_powersave.rules" "${WIFI_POWERSAVE_UDEV_RULES_FILE}"
elif [ -f "${WIFI_POWERSAVE_UDEV_RULES_FIE}" ]; then
    sudo rm "${WIFI_POWERSAVE_UDEV_RULES_FILE}"
fi

update_file_if_distinct "${REPO_RES_DIR}/udev/ioschedulers.rules" "${UDEV_RULES_DIR}/873-ioschedulers.rules"
update_file_if_distinct "${REPO_RES_DIR}/udev/pci_pm.rules" "${UDEV_RULES_DIR}/873-pci_pm.rules"

if ${IS_BATTERY_DEVICE}; then
    update_file_if_distinct "${REPO_RES_DIR}/udev/usb_powersave.rules" "${UDEV_RULES_DIR}/873-usb_powersave.rules"
else
    remove "${UDEV_RULES_DIR}/873-usb_powersave.rules"
fi
