#!/bin/bash

if [ -f "/usr/bin/gnome-shell-extension-installer" ]; then
    echo "Updating GNOME Shell extensions..."
    gnome-shell-extension-installer --yes --update --restart-shell
fi
