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
    uninstall-pkg "alsi"                    # Replaced by fastfetch-git
    uninstall-pkg "dialect"                 # Depends on outdated libs
    uninstall-pkg "grub2-theme-vimix"       # Replaced by grub2-theme-nuci
    uninstall-pkg "neofetch"                # Replaced by fastfetch-git
    uninstall-pkg "paper-icon-theme-git"    # Replaced by paper-icon-theme
    uninstall-pkg "ttf-ms-fonts"            # Replaced by ttf-ms-win10
    uninstall-pkg "yaourt-auto-sync"        # Replaced by repo-synchroniser
fi

# Clean the package cache
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    echo "Cleaning the package cache..."
    run-as-su paccache -ruk0 # Remove all uninstall packages from the cache
    run-as-su paccache -rk1  # Remove all cached versions of all packages, except the latest one

    does-bin-exist "paru" && yes | paru -Scc
    does-bin-exist "yay" && yes | paru -Scc
fi
