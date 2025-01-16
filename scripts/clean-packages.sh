#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
    call_package_manager cache clean
elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    if does_bin_exist 'paccache'; then
        run_as_su paccache -ruk0 # Remove all uninstall packages from the cache
        run_as_su paccache -rk1  # Remove all cached versions of all packages, except the latest one
    fi

    yes | run_as_su pacman -Scc
    yes | call_package_manager -Scc

    echo ''
elif [ "${DISTRO_FAMILY}" = 'Debian' ] \
  || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
    call_package_manager autoremove
fi
