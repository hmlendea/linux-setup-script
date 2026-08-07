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

function get_preferred_script_shell() {
    if does_bin_exist "bash"; then
        echo "bash"
    elif does_bin_exist "zsh"; then
        echo "zsh"
    else
        echo "sh"
    fi
}

function run_script() {
    local SCRIPT_PATH="${@}"
    local SHELL_BIN=""

    echo -e "Executing as \e[1;94m${USER}\e[0;39m: '${SCRIPT_PATH}'..."

    SHELL_BIN="$(get_preferred_script_shell)"
    "${SHELL_BIN}" "${@}"
}

function run_script_as_su() {
    ! ${HAS_SU_PRIVILEGES} && return

    local SCRIPT_PATH="${@}"
    local SHELL_BIN=""

    echo -e "Executing as \e[1;91mroot\e[0;39m: '${SCRIPT_PATH}'..."

    SHELL_BIN="$(get_preferred_script_shell)"
    run_as_su "${SHELL_BIN}" "${@}"
}

LANG=en_US.UTF-8 # Fix for commands such as `yes`
