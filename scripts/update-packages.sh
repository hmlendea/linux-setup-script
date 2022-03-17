#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

echo -e "Updating the \e[0;32msystem packages\e[0m ..."
if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    call-package-manager -Syu
elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
  || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
    call-package-manager update
    call-package-manager upgrade
fi

if does-bin-exist "flatpak"; then
    echo ""
    echo -e "Updating the \e[0;32mflatpak packages\e[0m ..."
    call_flatpak update
fi

if does-bin-exist "gnome-shell-extension-installer"; then
    echo ""
    echo -e "Updating the \e[0;32mGNOME extensions\e[0m ..."
    gnome-shell-extension-installer --yes --update --restart-shell
fi
