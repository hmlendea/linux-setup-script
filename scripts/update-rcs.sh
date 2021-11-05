#!/bin/bash
source "scripts/common/common.sh"

update-file-if-needed "${REPO_RC_DIR}/inputrc" "${HOME}/.inputrc"
update-file-if-needed "${REPO_RC_DIR}/shell_aliases" "${HOME}/.shell_aliases"
update-file-if-needed "${REPO_RC_DIR}/shell_prompt" "${HOME}/.shell_prompt"
update-file-if-needed "${REPO_RC_DIR}/shell_vars" "${HOME}/.shell_vars"

if $(does-bin-exist "bash"); then
    update-file-if-needed "${REPO_RC_DIR}/bashrc" "${HOME}/.bashrc"
    update-file-if-needed "${REPO_RC_DIR}/bashrc" "${HOME}/.bash_prompt"
fi

$(does-bin-exist "nano")    && update-file-if-needed "${REPO_RC_DIR}/nanorc"        "${HOME}/.nanorc"
$(does-bin-exist "vim")     && update-file-if-needed "${REPO_RC_DIR}/vimrc"         "${HOME}/.vimrc"
$(does-bin-exist "git")     && update-file-if-needed "${REPO_RC_DIR}/gitconfig"     "${HOME}/.gitconfig"
$(does-bin-exist "lxpanel") && update-file-if-needed "${REPO_RC_DIR}/lxde-panel"    "${HOME}/.config/lxpanel/LXDE/panels/panel"
#[ -f "${ROOT_USR_BIN}/lxpanel" ]   && copy_rc "lxde-dock" "${HOME}/.config/lxpanel/LXDE/panels/dock"

if $(does-bin-exist "firefox"); then
    FIREFOX_PROFILES_DIR="${HOME_REAL}/.mozilla/firefox"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        update-file-if-needed "${REPO_RC_DIR}/firefox-userChrome.css" "${FIREFOX_PROFILES_DIR}/${FIREFOX_PROFILE_ID}/chrome/userChrome.css"
        update-file-if-needed "${REPO_RC_DIR}/firefox-policies.json" "/usr/lib/firefox/distribution/policies.json"
    fi
fi

if $(does-bin-exist "neofetch"); then
    NEOFETCH_CONFIG_DIR="${HOME_REAL}/.config/neofetch"
    NEOFETCH_ASCII_LOGO_FILE=""

    if [ "${DISTRO}" == "Arch Linux" ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RC_DIR}/neofetch-arch-ascii"
    elif [ "${DISTRO}" == "LineageOS" ]; then
        NEOFETCH_ASCII_LOGO_FILE="${REPO_RC_DIR}/neofetch-lineageos-ascii"
    fi

    [ -f "${NEOFETCH_ASCII_LOGO_FILE}" ] && update-file-if-needed "${NEOFETCH_ASCII_LOGO_FILE}" "${NEOFETCH_CONFIG_DIR}/neofetch-distro-ascii"
fi
