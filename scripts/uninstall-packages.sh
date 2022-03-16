#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"

# Remove unused dependencies
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    UNUSED_DEPS=$(pacman -Qdtq)
    UNUSED_DEPS_COUNT=$(echo "${UNUSED_DEPS}" | wc -w)

    if [ "${UNUSED_DEPS_COUNT}" -gt 0 ]; then
        echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
        uninstall_package "${UNUSED_DEPS[@]}"
    fi
fi

# Uninstall the packages
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    uninstall_package "alsi"                                # Replaced by fastfetch-git
    uninstall_package "baobab"                              # Replaced by flatpak: org.gnome.baobab
    uninstall_package "dialect"                             # Depends on outdated libs
    uninstall_package "discord"                             # Replaced by flatpak: com.discordapp.Discord
    uninstall_package "electronmail-bin"                    # Replaced by flatpak: com.github.vladimiry.ElectronMail
    uninstall_package "evince"                              # Replaced by flatpak: org.gnome.Evince
    uninstall_package "chrome-gnome-shell"                  # Does not work with flatpak browsers
    uninstall_package "eog"                                 # Replaced by flatpak: org.gnome.eog
    uninstall_package "file-roller"                         # Replaced by flatpak: org.gnome.FileRoller
    uninstall_package "firefox"                             # Replaced by flatpak: org.mozilla.firefox
    uninstall_package "fragments"                           # Replaced by flatpak: de.haeckerfelix.Fragments
    uninstall_package "gedit"                               # Replaced by flatpak: org.gnome.gedit
    uninstall_package "gnome-calculator"                    # Replaced by flatpak: org.gnome.Calculator
    uninstall_package "gnome-calendar"                      # Replaced by flatpak: org.gnome.Calendar
    uninstall_package "gnome-contacts"                      # Replaced by flatpak: org.gnome.Contacts
    uninstall_package "gnome-clock"                         # Replaced by flatpak: org.gnome.Clocks
    uninstall_package "gnome-font-viewer"                   # Replaced by flatpak: org.gnome.font-viewer
    uninstall_package "gnome-maps"                          # Replaced by flatpak: org.gnome.Maps
    uninstall_package "gnome-network-displays"              # Replaced by flatpak: org.gnome.NetworkDisplays
    uninstall_package "gnome-weather"                       # Replaced by flatpak: org.gnome.Weather
    uninstall_package "gnome-shell-extension-dash-to-dock"  # Replaced by plank
    uninstall_package "grub2-theme-vimix"                   # Replaced by grub2-theme-nuci
    uninstall_package "inkscape"                            # Replaced by flatpak: org.inkscape.Inkscape
    uninstall_package "neofetch"                            # Replaced by fastfetch-git
    uninstall_package "paper-icon-theme-git"                # Replaced by paper-icon-theme
    uninstall_package "postman-bin"                         # Replaced by flatpak: com.getpostman.Postman
    uninstall_package "rhythmbox"                           # Replaced by flatpak: org.gnome.Rhythmbox3
    uninstall_package "signal-desktop"                      # Replaced by flatpak: org.signal.Signal
    uninstall_package "simplenote-electron-bin"             # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_package "simplenote-electron-arm-bin"         # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_package "spotify"                             # Replaced by flatpak: com.spotify.Client
    uninstall_package "telegram-desktop"                    # Replaced by flatpak: com.telegram.desktop
    uninstall_package "totem"                               # Replaced by flatpak: org.gnome.Totem
    uninstall_package "transmission-gtk"                    # Replaced by flatpak: com.transmissionbt.Transmission
    uninstall_package "ttf-ms-fonts"                        # Replaced by ttf-ms-win10
    uninstall_package "yaourt-auto-sync"                    # Replaced by repo-synchroniser

    if is-package-installed "visual-studio-code-bin"; then
        uninstall_package "code"
        uninstall_package "vscodium-bin"
    fi
fi

if [ "$(get_gpu_family)" != "AMD" ]; then
    uninstall_package "amdvlk"
    uninstall_package "lib32-amdvlk"
fi

if [[ "${CHASSIS_TYPE}" != "Laptop" ]]; then
    uninstall_package "acpi"
    uninstall_package "tlp"

    uninstall_package "powertop"

    if ( ! get_dmi_string "system-sku-number" | grep -q "ThinkPad" ); then
        uninstall_package acpi_call
        uninstall_package tp_smapi
    fi
fi
