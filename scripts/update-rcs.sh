#!/bin/bash
source "scripts/_common.sh"

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
    FIREFOX_PROFILES_INI_FILE="${HOME_REAL}/.mozilla/firefox/profiles.ini"
    FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

    update-file-if-needed "${REPO_RC_DIR}/firefox-userChrome.css" "${HOME}/.mozilla/firefox/${FIREFOX_PROFILE_ID}/chrome/userChrome.css"
fi
