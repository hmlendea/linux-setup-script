#!/bin/bash
[ -z "${GLOBAL_LAUNCHERS_DIR}" ] && source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"

function does_service_exist {
    local SERVICE_NAME="${*}"

    if does_bin_exist 'systemctl'; then
        for DIRECTORY_PATH in "${ROOT_ETC}/systemd/system" \
                         "${ROOT_LIB}/systemd/system}" \
                         "${ROOT_USR_LIB}/systemd/system"; do
            does_file_exist "${DIRECTORY_PATH}/${SERVICE_NAME}" && return 0
            does_file_exist "${DIRECTORY_PATH}/${SERVICE_NAME}.service" && return 0
        done
    elif does_bin_exist 'rc-service'; then
        does_file_exist "${ROOT_ETC}/init.d/${SERVICE_NAME}" && return 0
    fi
    
    return 1 # False
}

function is_service_enabled {
    local SERVICE_NAME="${*}"

    if does_bin_exist 'systemctl'; then
        systemctl is-enabled "${SERVICE_NAME}" | grep -q 'enabled' && return 0
    elif does_bin_exist 'rc-update'; then
        rc-update show | grep -q "${SERVICE_NAME}" && return 0
    fi

    return 1
}

function enable_service {
    local SERVICE_NAME="${*}"

    ! does_service_exist "${SERVICE_NAME}" && return
    is_service_enabled "${SERVICE_NAME}" && return

    if does_bin_exist 'systemctl'; then
        run_as_su systemctl enable "${SERVICE_NAME}"
        run_as_su systemctl start "${SERVICE_NAME}"
    elif does_bin_exist 'rc-service'; then
        run_as_su rc-update add "${SERVICE_NAME}"
        run_as_su rc-service "${SERVICE_NAME}" start
    fi
}

function disable_service {
    local SERVICE_NAME="${*}"

    ! does_service_exist "${SERVICE_NAME}" && return
    ! is_service_enabled "${SERVICE_NAME}" && return

    if does_bin_exist 'systemctl'; then
        run_as_su systemctl disable "${SERVICE_NAME}"
        run_as_su systemctl stop "${SERVICE_NAME}"
    elif does_bin_exist 'rc-service'; then
        run_as_su rc-update del "${SERVICE_NAME}"
        run_as_su rc-service "${SERVICE_NAME}" stop
    fi
}

function set_service_property {
    local SERVICE_NAME="${1}"
    local SECTION="${2}"
    local KEY="${3}"
    local VALUE="${4}"

    ! does_bin_exist 'systemctl' && return
    ! does_service_exist "${SERVICE_NAME}" && return

    local SERVICE_FILE_PATH="${ROOT_USR_LIB}/systemd/system/${SERVICE_NAME}.service"
    ! does_file_exist "${SERVICE_FILE_PATH}" && return

    set_config_value --section "${SECTION}" "${SERVICE_FILE_PATH}" "${KEY}" "${VALUE}"
    run_as_su systemctl daemon-reload
}
