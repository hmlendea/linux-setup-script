#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

if does_bin_exist "firefox" "org.mozilla.firefox"; then
    MOZILLA_USERDATA_DIR="${HOME_REAL}/.mozilla/firefox"

    [ -d "${HOME_VAR}/app/org.mozilla.firefox" ] && MOZILLA_USERDATA_DIR="${HOME_VAR}/app/org.mozilla.firefox/.mozilla"

    FIREFOX_PROFILES_DIR="${MOZILLA_USERDATA_DIR}/firefox"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        update_file_if_distinct "${REPO_RES_DIR}/firefox/containers.json" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/containers.json"
        update_file_if_distinct "${REPO_RES_DIR}/firefox/userChrome.css" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/userChrome.css"

        for ICON_FILE in "${REPO_RES_DIR}/firefox/icons/"*.png; do
            ICON_FILE_BASENAME=$(basename "${ICON_FILE}")
            update_file_if_distinct "${REPO_RES_DIR}/firefox/icons/${ICON_FILE_BASENAME}" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/icons/${ICON_FILE_BASENAME}"
        done
    fi
fi

if does_bin_exist "lxpanel"; then
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/applications.png"                "${HOME}/.config/lxpanel/LXDE/panels/applications.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/applications_ro.png"             "${HOME}/.config/lxpanel/LXDE/panels/applications_ro.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/power.png"                       "${HOME}/.config/lxpanel/LXDE/panels/power.png"
    update_file_if_distinct "${REPO_RES_DIR}/lxpanel/lxde-logout-gnomified.desktop"   "${HOME}/.local/share/applications/lxde-logout-gnomified.desktop"
fi

if does_bin_exist "plank"; then
    update_file_if_distinct "${REPO_RES_DIR}/plank/dock.theme"                        "${HOME}/.local/share/plank/themes/Hori/dock.theme"
fi

if does_bin_exist "neofetch"; then
    NEOFETCH_CONFIG_DIR="${HOME_REAL}/.config/neofetch"
    NEOFETCH_ASCII_LOGO_FILE=""

    if [[ "${DISTRO}" == "Arch Linux" ]]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-arch"
    elif [[ "${DISTRO}" == "LineageOS" ]]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RES_DIR}/neofetch/ascii-lineageos"
    fi

    [ -f "${NEOFETCH_ASCII_LOGO_FILE}" ] && update_file_if_distinct "${NEOFETCH_ASCII_LOGO_FILE}" "${NEOFETCH_CONFIG_DIR}/ascii"
fi

# PCManFM's context menu
if does_bin_exist "pcmanfm"; then
    does_bin_exist "code-oss"   && update_file_if_distinct "${REPO_RES_DIR}/pcmanfm/open-in-code.desktop"     "${HOME}/.local/share/file-manager/actions/open-in-code.desktop"
    does_bin_exist "lxterminal" && update_file_if_distinct "${REPO_RES_DIR}/pcmanfm/open-in-terminal.desktop" "${HOME}/.local/share/file-manager/actions/open-in-terminal.desktop"
fi

# Templates
if ${HAS_GUI}; then
    update_file_if_distinct "${REPO_RES_DIR}/templates/file" "${HOME}/Templates/Blank file"

    if does_bin_exist "libreoffice"; then
        update_file_if_distinct "${REPO_RES_DIR}/templates/doc" "${HOME}/Templates/Microsoft Document.doc"
        update_file_if_distinct "${REPO_RES_DIR}/templates/odt" "${HOME}/Templates/Document.odt"
    else
        remove "${HOME}/Templates/Microsoft Document.doc"
        remove "${HOME}/Templates/Document.odt"
    fi
fi
