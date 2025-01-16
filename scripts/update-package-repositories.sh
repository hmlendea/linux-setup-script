#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

echo -e 'Updating the \e[0;32msystem package repositories\e[0m ...'
if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
    call_package_manager update
elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    call_package_manager -Syy
    does_bin_exist 'pkgfile' && run_as_su pkgfile -u
elif [ "${DISTRO_FAMILY}" = 'Android' ] \
  || [ "${DISTRO_FAMILY}" = 'Debian' ] \
  || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
    call_package_manager update
fi

if does_bin_exist 'flatpak'; then
    echo -e 'Updating the \e[0;32msystem flatpak remotes\e[0m ...'
    run_as_su flatpak update --appstream
    echo -e 'Updating the \e[0;32muser flatpak remotes\e[0m ...'
    flatpak update --user --appstream
fi
