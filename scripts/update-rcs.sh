#!/bin/bash

RC_DIR=$(pwd)"/rc"

copy_rc() {
    SOURCE_RC=$1
    TARGET_RC=$2

    cp "$RC_DIR/$SOURCE_RC" "$TARGET_RC"
}

copy_rc "bashrc" "$HOME/.bashrc"

[ -f "/usr/bin/nano" ]   && copy_rc "nanorc"     "$HOME/.nanorc"
[ -f "/usr/bin/vim" ]    && copy_rc "vimrc"      "$HOME/.vimrc"
[ -f "/usr/bin/git" ]   && copy_rc "gitconfig"  "$HOME/.gitconfig"

