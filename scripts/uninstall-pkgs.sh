#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"

# Remove unused dependencies
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    UNUSED_DEPS=$(pacman -Qdtq)
    UNUSED_DEPS_COUNT=$(echo "${UNUSED_DEPS}" | wc -w)

    if [ "${UNUSED_DEPS_COUNT}" -gt 0 ]; then
        echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
        uninstall-pkgs "${UNUSED_DEPS[@]}"
    fi
fi

# Uninstall the packages
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    uninstall-pkg "alsi"                                # Replaced by fastfetch-git
    uninstall-pkg "dialect"                             # Depends on outdated libs
    uninstall-pkg "discord"                             # Replaced by flatpak: com.discordapp.Discord
    uninstall-pkg "electronmail-bin"                    # Replaced by flatpak: com.github.vladimiry.ElectronMail
    uninstall-pkg "fragments"                           # Replaced by flatpak: de.haeckerfelix.Fragments
    uninstall-pkg "gnome-shell-extension-dash-to-dock"  # Replaced by plank
    uninstall-pkg "grub2-theme-vimix"                   # Replaced by grub2-theme-nuci
    uninstall-pkg "neofetch"                            # Replaced by fastfetch-git
    uninstall-pkg "paper-icon-theme-git"                # Replaced by paper-icon-theme
    uninstall-pkg "signal-desktop"                      # Replaced by flatpak: org.signal.Signal
    uninstall-pkg "simplenote-electron-bin"             # Replaced by flatpak: com.simplenote.Simplenote
    uninstall-pkg "simplenote-electron-arm-bin"         # Replaced by flatpak: com.simplenote.Simplenote
    uninstall-pkg "spotify"                             # Replaced by flatpak: com.spotify.Client
    uninstall-pkg "telegram-desktop"                    # Replaced by flatpak: com.telegram.desktop
    uninstall-pkg "ttf-ms-fonts"                        # Replaced by ttf-ms-win10
    uninstall-pkg "yaourt-auto-sync"                    # Replaced by repo-synchroniser

    if is-package-installed "visual-studio-code-bin"; then
        uninstall-pkg "code"
        uninstall-pkg "vscodium-bin"
    fi
fi

# Clean the package cache
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    echo "Cleaning the package cache..."
    if does-bin-exist "paccache"; then
        run-as-su paccache -ruk0 # Remove all uninstall packages from the cache
        run-as-su paccache -rk1  # Remove all cached versions of all packages, except the latest one
    fi

    yes | run-as-su pacman -Scc

    does-bin-exist "paru" && yes | paru -Scc
    does-bin-exist "yay" && yes | yay -Scc
fi

if [ "$(get_gpu_family)" != "AMD" ]; then
    uninstall-pkg "amdvlk"
    uninstall-pkg "lib32-amdvlk"
fi

if [[ "${CHASSIS_TYPE}" != "Laptop" ]]; then
    uninstall-pkg "acpi"
    uninstall-pkg "tlp"

    uninstall-pkg "powertop"

    if ( ! get_dmi_string "system-sku-number" | grep -q "ThinkPad" ); then
        uninstall-pkg acpi_call
        uninstall-pkg tp_smapi
    fi
fi
