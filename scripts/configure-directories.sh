#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

function update-hidden-files-config-if-needed() {
    local CONFIG_FILE_NAME="${1}"
    local DESTINATION_DIR="${2}"

    update_file_if_distinct "${REPO_RC_DIR}/hidden-files/${CONFIG_FILE_NAME}" "${DESTINATION_DIR}/.hidden"
}

if ${HAS_GUI} && [[ "${OS}" == "Linux" ]]; then
    update-hidden-files-config-if-needed "home" "${HOME}"
    update-hidden-files-config-if-needed "home-documents" "${HOME_DOCUMENTS}"
    update-hidden-files-config-if-needed "home-downloads" "${HOME_DOWNLOADS}"
fi

if [[ "${OS}" == "Android" ]]; then
    ANDROID_USER_STORAGE_DIR="/storage/emulated/0"

    create_symlink "${ANDROID_USER_STORAGE_DIR}/Documents" "${HOME_DOCUMENTS}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Download" "${HOME_DOWNLOADS}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Music" "${HOME_MUSIC}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Movies" "${HOME_VIDEOS}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Pictures" "${HOME_PICTURES}"
fi
