#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/system-info.sh"

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    if does-bin-exist "paccache"; then
        run-as-su paccache -ruk0 # Remove all uninstall packages from the cache
        run-as-su paccache -rk1  # Remove all cached versions of all packages, except the latest one
    fi

    yes | run-as-su pacman -Scc

    does-bin-exist "paru" && yes | paru -Scc
    does-bin-exist "yay" && yes | yay -Scc
    does-bin-exist "yaourt" && yes | yaourt -Scc
fi
