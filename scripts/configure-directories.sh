#!/bin/bash
source "scripts/common/common.sh"

function update-hidden-files-config-if-needed() {
    local CONFIG_FILE_NAME="${1}"
    local DESTINATION_DIR="${2}"

    update-file-if-needed "${REPO_RC_DIR}/hidden-files/${CONFIG_FILE_NAME}" "${DESTINATION_DIR}/.hidden"
}

if ${HAS_GUI} && [[ "${OS}" == "Linux" ]]; then
    update-hidden-files-config-if-needed "home" "${HOME}"
    update-hidden-files-config-if-needed "home-documents" "${HOME}/Documents"
    update-hidden-files-config-if-needed "home-downloads" "${HOME}/Downloads"
fi

if [[ "${OS}" == "Android" ]]; then
    ANDROID_USER_STORAGE_DIR="/storage/emulated/0"

    create_symlink "${ANDROID_USER_STORAGE_DIR}/Documents" "${HOME}/Documents"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Download" "${HOME}/Downloads"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Music" "${HOME}/Music"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Movies" "${HOME}/Videos"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Pictures" "${HOME}/Pictures"
fi
