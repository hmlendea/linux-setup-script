#!/bin/bash
source "scripts/common/common.sh"

if does-bin-exist "firefox"; then
    FIREFOX_PROFILES_DIR="${HOME_REAL}/.mozilla/firefox"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        update-file-if-needed "${REPO_RES_DIR}/firefox/containers.json" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/containers.json"
        update-file-if-needed "${REPO_RES_DIR}/firefox/userChrome.css" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/userChrome.css"

        for ICON_FILE in "${REPO_RES_DIR}/firefox/icons/"*.png; do
            ICON_FILE_BASENAME=$(basename "${ICON_FILE}")
            update-file-if-needed "${REPO_RES_DIR}/firefox/icons/${ICON_FILE_BASENAME}" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/icons/${ICON_FILE_BASENAME}"
        done
    fi
fi

if does-bin-exist "lxpanel"; then
    update-file-if-needed "${REPO_RES_DIR}/lxpanel/applications.png"                "${HOME}/.config/lxpanel/LXDE/panels/applications.png"
    update-file-if-needed "${REPO_RES_DIR}/lxpanel/applications_ro.png"             "${HOME}/.config/lxpanel/LXDE/panels/applications_ro.png"
    update-file-if-needed "${REPO_RES_DIR}/lxpanel/power.png"                       "${HOME}/.config/lxpanel/LXDE/panels/power.png"
    update-file-if-needed "${REPO_RES_DIR}/lxpanel/lxde-logout-gnomified.desktop"   "${HOME}/.local/share/applications/lxde-logout-gnomified.desktop"
    update-file-if-needed "${REPO_RES_DIR}/plank/autostart.desktop"                 "${HOME}/.config/autostart/plank.desktop"
fi

if does-bin-exist "neofetch"; then
    NEOFETCH_CONFIG_DIR="${HOME_REAL}/.config/neofetch"
    NEOFETCH_ASCII_LOGO_FILE=""

    if [[ "${DISTRO}" == "Arch Linux" ]]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-arch"
    elif [[ "${DISTRO}" == "LineageOS" ]]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-lineageos"
    fi

    [ -f "${NEOFETCH_ASCII_LOGO_FILE}" ] && update-file-if-needed "${NEOFETCH_ASCII_LOGO_FILE}" "${NEOFETCH_CONFIG_DIR}/ascii"
fi

# PCManFM's context menu
if does-bin-exist "pcmanfm"; then
    does-bin-exist "code-oss"   && update-file-if-needed "${REPO_RES_DIR}/pcmanfm/open-in-code.desktop"     "${HOME}/.local/share/file-manager/actions/open-in-code.desktop"
    does-bin-exist "lxterminal" && update-file-if-needed "${REPO_RES_DIR}/pcmanfm/open-in-terminal.desktop" "${HOME}/.local/share/file-manager/actions/open-in-terminal.desktop"
fi

# Templates
if ${HAS_GUI}; then
    update-file-if-needed "${REPO_RES_DIR}/templates/file" "${HOME}/Templates/Blank file"

    if does-bin-exist "libreoffice"; then
        update-file-if-needed "${REPO_RES_DIR}/templates/doc" "${HOME}/Templates/Microsoft Document.doc"
        update-file-if-needed "${REPO_RES_DIR}/templates/odt" "${HOME}/Templates/Document.odt"
    else
        remove "${HOME}/Templates/Microsoft Document.doc"
        remove "${HOME}/Templates/Document.odt"
    fi
fi
