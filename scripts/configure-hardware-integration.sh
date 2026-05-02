#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/service-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

DEVICE_MODEL="$(get_device_model)"

if [[ "${DEVICE_MODEL}" =~ 'Argon ONE UP' ]]; then
    if ! ls "${ROOT_USR_SRC}"/oneUpPower-* >/dev/null 2>&1; then
        WORKING_DIRECTORY="$(pwd)"
        [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"
        cd "${LOCAL_INSTALL_TEMP_DIR}"

        git clone 'https://github.com/JeffCurless/argon-oneup.git'
        cd 'argon-oneup'

        run_as_su './setup'
    fi

    disable_service 'argononeupd'
fi
