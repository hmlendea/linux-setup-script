#!/bin/bash
source "scripts/_common.sh"

RC_DIR=$(pwd)"/rc"

copy_rc() {
    SOURCE_RC="${1}"
    TARGET_RC="${2}"
    TARGET_DIR=$(dirname "${TARGET_RC}")

    if [ ! -d "${TARGET_DIR}" ]; then
        echo "Creating the directory: ${TARGET_DIR}" >&2
        mkdir -p "${TARGET_DIR}"
    fi

    cp "$RC_DIR/$SOURCE_RC" "$TARGET_RC"
}

copy_rc "shell_aliases" "${HOME}/.shell_aliases"
copy_rc "shell_prompt" "${HOME}/.shell_prompt"
copy_rc "shell_vars" "${HOME}/.shell_vars"

[ -f "${ROOT_BIN}/bash" ] && copy_rc "bashrc" "${HOME}/.bashrc"
[ -f "${ROOT_BIN}/bash" ] && copy_rc "bashrc" "${HOME}/.bash_prompt"

[ -f "${ROOT_USR_BIN}/nano" ]      && copy_rc "nanorc"     "${HOME}/.nanorc"
[ -f "${ROOT_USR_BIN}/vim" ]       && copy_rc "vimrc"      "${HOME}/.vimrc"
[ -f "${ROOT_USR_BIN}/git" ]       && copy_rc "gitconfig"  "${HOME}/.gitconfig"
[ -f "${ROOT_USR_BIN}/lxpanel" ]   && copy_rc "lxde-panel" "${HOME}/.config/lxpanel/LXDE/panels/panel"
#[ -f "${ROOT_USR_BIN}/lxpanel" ]   && copy_rc "lxde-dock" "${HOME}/.config/lxpanel/LXDE/panels/dock"
