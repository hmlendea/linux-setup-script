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
    update-hidden-files-config-if-needed "home-documents" "${XDG_DOCUMENTS_DIR}"
    update-hidden-files-config-if-needed "home-downloads" "${XDG_DOWNLOAD_DIR}"
fi

if [[ "${OS}" == "Android" ]]; then
    ANDROID_USER_STORAGE_DIR="/storage/emulated/0"

    create_symlink "${ANDROID_USER_STORAGE_DIR}/Documents" "${XDG_DOCUMENTS_DIR}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Download" "${XDG_DOWNLOAD_DIR}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Music" "${XDG_MUSIC_DIR}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Movies" "${XDG_VIDEOS_DIR}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Pictures" "${XDG_PICTURES_DIR}"
    create_symlink "${ANDROID_USER_STORAGE_DIR}/Public" "${XDG_PUBLICSHARE_DIR}"
fi
