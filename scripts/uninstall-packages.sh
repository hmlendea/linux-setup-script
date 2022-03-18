#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"
source "scripts/common/system-info.sh"

# Remove unused dependencies
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    UNUSED_DEPS=$(pacman -Qdtq)
    UNUSED_DEPS_COUNT=$(echo "${UNUSED_DEPS}" | wc -w)

    if [ "${UNUSED_DEPS_COUNT}" -gt 0 ]; then
        echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
        uninstall_native_package "${UNUSED_DEPS[@]}"
    fi
fi

# Uninstall the packages
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    uninstall_native_package "alsi"                                # Replaced by fastfetch-git
    uninstall_native_package "baobab"                              # Replaced by flatpak: org.gnome.baobab
    uninstall_native_package "dialect"                             # Depends on outdated libs
    uninstall_native_package "discord"                             # Replaced by flatpak: com.discordapp.Discord
    uninstall_native_package "electronmail-bin"                    # Replaced by flatpak: com.github.vladimiry.ElectronMail
    uninstall_native_package "evince"                              # Replaced by flatpak: org.gnome.Evince
    uninstall_native_package "chrome-gnome-shell"                  # Does not work with flatpak browsers
    uninstall_native_package "eog"                                 # Replaced by flatpak: org.gnome.eog
    uninstall_native_package "file-roller"                         # Replaced by flatpak: org.gnome.FileRoller
    uninstall_native_package "firefox"                             # Replaced by flatpak: org.mozilla.firefox
    uninstall_native_package "fragments"                           # Replaced by flatpak: de.haeckerfelix.Fragments
    uninstall_native_package "gedit"                               # Replaced by flatpak: org.gnome.gedit
    uninstall_native_package "gnome-calculator"                    # Replaced by flatpak: org.gnome.Calculator
    uninstall_native_package "gnome-calendar"                      # Replaced by flatpak: org.gnome.Calendar
    uninstall_native_package "gnome-contacts"                      # Replaced by flatpak: org.gnome.Contacts
    uninstall_native_package "gnome-clocks"                        # Replaced by flatpak: org.gnome.Clocks
    uninstall_native_package "gnome-font-viewer"                   # Replaced by flatpak: org.gnome.font-viewer
    uninstall_native_package "gnome-maps"                          # Replaced by flatpak: org.gnome.Maps
    uninstall_native_package "gnome-network-displays"              # Replaced by flatpak: org.gnome.NetworkDisplays
    uninstall_native_package "gnome-weather"                       # Replaced by flatpak: org.gnome.Weather
    uninstall_native_package "gnome-shell-extension-dash-to-dock"  # Replaced by plank
    uninstall_native_package "grub2-theme-vimix"                   # Replaced by grub2-theme-nuci
    uninstall_native_package "inkscape"                            # Replaced by flatpak: org.inkscape.Inkscape
    uninstall_native_package "minecraft-launcher"                  # Replaced by flatpak: com.mojang.Minecraft
    uninstall_native_package "neofetch"                            # Replaced by fastfetch-git
    uninstall_native_package "paper-icon-theme-git"                # Replaced by paper-icon-theme
    uninstall_native_package "postman-bin"                         # Replaced by flatpak: com.getpostman.Postman
    uninstall_native_package "rhythmbox"                           # Replaced by flatpak: org.gnome.Rhythmbox3
    uninstall_native_package "seahorse"                            # Replaced by flatpak: org.gnome.seahorse.Application
    uninstall_native_package "signal-desktop"                      # Replaced by flatpak: org.signal.Signal
    uninstall_native_package "simplenote-electron-bin"             # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_native_package "simplenote-electron-arm-bin"         # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_native_package "spotify"                             # Replaced by flatpak: com.spotify.Client
    uninstall_native_package "telegram-desktop"                    # Replaced by flatpak: com.telegram.desktop
    uninstall_native_package "totem"                               # Replaced by flatpak: org.gnome.Totem
    uninstall_native_package "transmission-gtk"                    # Replaced by flatpak: com.transmissionbt.Transmission
    uninstall_native_package "ttf-ms-fonts"                        # Replaced by ttf-ms-win10
    uninstall_native_package "yaourt-auto-sync"                    # Replaced by repo-synchroniser

    uninstall_flatpak "org.gnome.TextEditor" # Replaced by org.gnome.gedit

    if is_native_package_installed "visual-studio-code-bin"; then
        uninstall_native_package "code"
        uninstall_native_package "vscodium-bin"
    fi

    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        yes | apt autoremove
    elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        yes | run_as_su apt autoremove
    fi
elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
    yes | apt autoremove
elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
    yes | run_as_su apt autoremove
fi
