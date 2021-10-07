#!/bin/bash
source "scripts/_common.sh"

if [ -f "${ROOT_USR_BIN}/gnome-shell-extension-installer" ]; then
    echo "Updating GNOME Shell extensions..."
    gnome-shell-extension-installer --yes --update --restart-shell
fi
