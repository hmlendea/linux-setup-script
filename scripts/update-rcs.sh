#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"

update_file_if_distinct "${REPO_RC_DIR}/inputrc" "${XDG_CONFIG_HOME}/readline/inputrc"
update_file_if_distinct "${REPO_RC_DIR}/shell_aliases" "${HOME}/.shell_aliases"
update_file_if_distinct "${REPO_RC_DIR}/shell_opts" "${HOME}/.shell_opts"
update_file_if_distinct "${REPO_RC_DIR}/shell_prompt" "${HOME}/.shell_prompt"
update_file_if_distinct "${REPO_RC_DIR}/shell_vars" "${HOME}/.shell_vars"

if does_bin_exist "bash"; then
    update_file_if_distinct "${REPO_RC_DIR}/bashrc" "${HOME}/.bashrc"
    update_file_if_distinct "${REPO_RC_DIR}/bash_profile" "${HOME}/.bash_profile"
    update_file_if_distinct "${REPO_RC_DIR}/bashrc" "${HOME}/.bash_prompt"
fi

for RC in "gimprc" "sessionrc" "toolrc"; do
    does_bin_exist "gimp" && update_file_if_distinct "${REPO_RC_DIR}/gimp/${RC}" "${XDG_CONFIG_HOME}/GIMP/2.10/${RC}"
    does_bin_exist "org.gimp.GIMP" && update_file_if_distinct "${REPO_RC_DIR}/gimp/${RC}" "${HOME_VAR_APP}/org.gimp.GIMP/config/GIMP/2.10/${RC}"
done

does_bin_exist "nano"       && update_file_if_distinct "${REPO_RC_DIR}/nanorc"        "${HOME}/.nanorc"
does_bin_exist "vim"        && update_file_if_distinct "${REPO_RC_DIR}/vimrc"         "${HOME}/.vimrc"
does_bin_exist "git"        && update_file_if_distinct "${REPO_RC_DIR}/gitconfig"     "${XDG_CONFIG_HOME}/git/config"
does_bin_exist "lxpanel"    && update_file_if_distinct "${REPO_RC_DIR}/lxde-panel"    "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/panel"
#[ -f "${ROOT_USR_BIN}/lxpanel" ]   && copy_rc "lxde-dock" "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/dock"

if does_bin_exist "firefox" "org.mozilla.firefox"; then
    FIREFOX_PROFILES_DIR="${HOME_MOZILLA}/firefox"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        update_file_if_distinct "${REPO_RC_DIR}/firefox-policies.json" "${ROOT_USR_LIB}/firefox/distribution/policies.json"
    fi
fi
