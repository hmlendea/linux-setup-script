#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "scripts/common/filesystem.sh"
    source "${REPO_DIR}/scripts/common/common.sh"
fi

function does_systemd_service_exist_at_location {
    local SERVICE_NAME="${1}"
    local LOCATION="${2}"

    [ -f "${LOCATION}/${SERVICE_NAME}" ] && return 0
    [ -f "${LOCATION}/${SERVICE_NAME}.service" ] && return 0

    return 1 # False
}

function does_systemd_service_exist {
    local SERVICE_NAME="${*}"

    does_systemd_service_exist_at_location "${SERVICE_NAME}" "${ROOT_ETC}/systemd/system" && return 0
    does_systemd_service_exist_at_location "${SERVICE_NAME}" "${ROOT_LIB}/systemd/system" && return 0
    does_systemd_service_exist_at_location "${SERVICE_NAME}" "${ROOT_USR_LIB}/systemd/system" && return 0

    return 1 # False
}

function enable_service {
    [ ! -f "${ROOT_USR_BIN}/systemctl" ] && return

    local SERVICE_NAME="${*}"

    (! does_systemd_service_exist "${SERVICE_NAME}") && return

    run-as-su systemctl enable "${SERVICE_NAME}"
    run-as-su systemctl start "${SERVICE_NAME}"
}

function disable_service {
    [ ! -f "${ROOT_USR_BIN}/systemctl" ] && return

    local SERVICE_NAME="${*}"

    (! does_systemd_service_exist "${SERVICE_NAME}") && return

    run-as-su systemctl disable "${SERVICE_NAME}"
    run-as-su systemctl stop "${SERVICE_NAME}"
}
