#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"

[[ "${DISTRO_FAMILY}" != "Arch" ]] && exit

UNUSED_DEPS=$(pacman -Qdtq)
UNUSED_DEPS_COUNT=$(echo "${UNUSED_DEPS}" | wc -w)

if [ "${UNUSED_DEPS_COUNT}" -gt 0 ]; then
    echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
    echo "${UNUSED_DEPS}"

    run-as-su pacman --noconfirm -Rns "${UNUSED_DEPS}"
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    uninstall-pkg "yaourt-auto-sync"
fi
