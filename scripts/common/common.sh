#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "scripts/common/filesystem.sh"
    source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"
fi

function run_as_su() {
    if [ "${UID}" -eq 0 ]; then
        "${@}"
    elif ${HAS_SU_PRIVILEGES}; then
        if [[ "${DISTRO_FAMILY}" == "Android" ]]; then
            su -c ${*}
        else
            sudo "${@}"
        fi
    else
        echo "Failed to run '${*}': Missing SU privileges!"
    fi
}
