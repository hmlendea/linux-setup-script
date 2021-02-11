#!/bin/bash

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
copy_rc "shell_vars" "${HOME}/.shell_vars"

[ -f "/bin/bash" ] && copy_rc "bashrc" "${HOME}/.bashrc"
[ -f "/bin/bash" ] && copy_rc "bashrc" "${HOME}/.bash_prompt"

[ -f "/usr/bin/nano" ]      && copy_rc "nanorc"     "${HOME}/.nanorc"
[ -f "/usr/bin/vim" ]       && copy_rc "vimrc"      "${HOME}/.vimrc"
[ -f "/usr/bin/git" ]       && copy_rc "gitconfig"  "${HOME}/.gitconfig"
[ -f "/usr/bin/lxpanel" ]   && copy_rc "lxde-panel" "${HOME}/.config/lxpanel/LXDE/panels/panel"
#[ -f "/usr/bin/lxpanel" ]   && copy_rc "lxde-dock" "${HOME}/.config/lxpanel/LXDE/panels/dock"
