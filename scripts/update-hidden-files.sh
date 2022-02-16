#!/bin/bash
source "scripts/common/common.sh"

[ ! ${HAS_GUI} ] && exit

function update-hidden-files-config-if-needed() {
    local CONFIG_FILE_NAME="${1}"
    local DESTINATION_DIR="${2}"

    update-file-if-needed "${REPO_RC_DIR}/hidden-files/${CONFIG_FILE_NAME}" "${DESTINATION_DIR}/.hidden"
}

update-hidden-files-config-if-needed "home" "${HOME}"
update-hidden-files-config-if-needed "home-documents" "${HOME}/Documents"
