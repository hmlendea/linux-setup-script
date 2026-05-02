#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/service-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

DEVICE_MODEL="$(get_device_model)"

if [[ "${DEVICE_MODEL}" =~ 'Argon ONE UP' ]]; then
    WORKING_DIRECTORY="$(pwd)"

    if ! ls "${ROOT_USR_SRC}"/oneUpPower-* >/dev/null 2>&1; then
        create_directory "${LOCAL_INSTALL_TEMP_DIR}"
        cd "${LOCAL_INSTALL_TEMP_DIR}"

        [ ! -d 'argon-oneup' ] && git clone 'https://github.com/JeffCurless/argon-oneup.git'
        cd 'argon-oneup'

        run_as_su 'battery/setup'
    fi

    if ! ls "${ROOT_USR_LOCAL_BIN}/argononeup-automatic-shutdown" >/dev/null 2>&1; then
        create_directory "${LOCAL_INSTALL_TEMP_DIR}"
        cd "${LOCAL_INSTALL_TEMP_DIR}"

        [ ! -d 'argononeup-automatic-shutdown' ] && git clone 'https://github.com/hmlendea/argononeup-automatic-shutdown'
        cd 'argononeup-automatic-shutdown'

        run_as_su './install'
    fi

    disable_service 'argononeupd'
fi
