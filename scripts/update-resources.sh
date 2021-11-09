#!/bin/bash
source "scripts/common/common.sh"

if does-bin-exist "firefox"; then
    FIREFOX_PROFILES_DIR="${HOME_REAL}/.mozilla/firefox"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        update-file-if-needed "${REPO_RES_DIR}/firefox/userChrome.css" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/userChrome.css"
    fi
fi

if does-bin-exist "lxpanel"; then
    update-file-if-needed "lxpanel/applications.png"                "${HOME}/.config/lxpanel/LXDE/panels/applications.png"
    update-file-if-needed "lxpanel/applications_ro.png"             "${HOME}/.config/lxpanel/LXDE/panels/applications_ro.png"
    update-file-if-needed "lxpanel/power.png"                       "${HOME}/.config/lxpanel/LXDE/panels/power.png"
    update-file-if-needed "lxpanel/lxde-logout-gnomified.desktop"   "${HOME}/.local/share/applications/lxde-logout-gnomified.desktop"
    update-file-if-needed "plank/autostart.desktop"                 "${HOME}/.config/autostart/plank.desktop"
fi

if does-bin-exist "neofetch"; then
    NEOFETCH_CONFIG_DIR="${HOME_REAL}/.config/neofetch"
    NEOFETCH_ASCII_LOGO_FILE=""

    if [ "${DISTRO}" == "Arch Linux" ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch-arch-ascii"
    elif [ "${DISTRO}" == "LineageOS" ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch-lineageos-ascii"
    fi

    [ -f "${NEOFETCH_ASCII_LOGO_FILE}" ] && update-file-if-needed "${NEOFETCH_ASCII_LOGO_FILE}" "${NEOFETCH_CONFIG_DIR}/neofetch-distro-ascii"
fi

# PCManFM's context menu
if does-bin-exist "pcmanfm"; then
    does-bin-exist "code-oss"   && update-file-if-needed "pcmanfm/open-in-code.desktop"     "${HOME}/.local/share/file-manager/actions/open-in-code.desktop"
    does-bin-exist "lxterminal" && update-file-if-needed "pcmanfm/open-in-terminal.desktop" "${HOME}/.local/share/file-manager/actions/open-in-terminal.desktop"
fi
