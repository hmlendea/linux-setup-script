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

function run_script() {
return
    local SCRIPT_PATH="${@}"
    echo -e "Executing as \e[1;94m${USER}\e[0;39m: '${SCRIPT_PATH}'..."

    if does_bin_exist "bash"; then
        bash "${@}"
    elif does_bin_exist "zsh"; then
        zsh "${@}"
    else
        sh "${@}"
    fi
}

function run_script_as_su() {
    ! ${HAS_SU_PRIVILEGES} && return

    local SCRIPT_PATH="${@}"
    echo -e "Executing as \e[1;91mroot\e[0;39m: '${SCRIPT_PATH}'..."

    if does_bin_exist "bash"; then
        run_as_su "bash" "${@}"
    elif does_bin_exist "zsh"; then
        run_as_su "zsh" "${@}"
    else
        run_as_su "sh" "${@}"
    fi
}
