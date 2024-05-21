#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

if ! is_distro_immutable; then
    echo -e 'Updating the \e[0;32msystem packages\e[0m ...'
    if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        call_package_manager -Syu
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        call_package_manager upgrade
    fi
fi

if does_bin_exist 'flatpak'; then
    echo ''
    echo -e 'Updating the \e[0;32mflatpak packages\e[0m ...'
    call_flatpak update
fi

if does_bin_exist 'gnome-shell-extension-installer'; then
    echo ''
    echo -e 'Updating the \e[0;32mGNOME extensions\e[0m ...'
    gnome-shell-extension-installer --yes --update --restart-shell | \
      grep -v 'The extension is up-to-date' | \
      grep -v 'Searching extensions.gnome.org' | \
      grep -v 'Extension not available for GNOME Shell [0-9]' | \
      grep -v 'This extension is available for the following' | \
      grep -v '^\s*-\s*[0-9]' | \
      grep -v 'Type a version to install' | \
      grep -v '^\s*$'
fi
