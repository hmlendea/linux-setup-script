#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

function update_hidden_files_config_if_needed() {
    local CONFIG_FILE_NAME="${1}"
    local DESTINATION_DIR="${2}"

    update_file_if_distinct "${REPO_RC_DIR}/hidden-files/${CONFIG_FILE_NAME}" "${DESTINATION_DIR}/.hidden"
}

if ${HAS_GUI} && [[ "${OS}" == "Linux" ]]; then
    if [ "${XDG_DOWNLOAD_DIR}" == "${HOME}/Descărcări" ]; then
        update_hidden_files_config_if_needed "home-ro" "${HOME}"
        create_symlink "${XDG_DOWNLOAD_DIR}" "${HOME}/Downloads"
    else
        update_hidden_files_config_if_needed "home" "${HOME}"
    fi
    update_hidden_files_config_if_needed "home-documents" "${XDG_DOCUMENTS_DIR}"
    update_hidden_files_config_if_needed "home-downloads" "${XDG_DOWNLOAD_DIR}"

    if does_bin_exist "org.prismlauncher.PrismLauncher"; then
        MINECRAFT_SCREENSHOTS_DIR="${XDG_PICTURES_DIR}/Screenshots/Minecraft"

        create_directory "${MINECRAFT_SCREENSHOTS_DIR}"

        for MINECRAFT_INSTANCE in "${HOME_VAR_APP}/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/"*"/"; do
            MINECRAFT_INSTANCE_SCREENSHOTS_DIR="${MINECRAFT_INSTANCE}/.minecraft/screenshots"
            if [ -d "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}" ] && \
               [ ! -L "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}" ]; then
                MINECRAFT_INSTANCE_SCREENSHOTS_DIR_FILES=$(ls -A "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}")
                if [ "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR_FILES}" ]; then
                    echo "Moving contents of '${MINECRAFT_INSTANCE_SCREENSHOTS_DIR_FILES}' to '${MINECRAFT_SCREENSHOTS_DIR}'..."
                    mv "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}"/* "${MINECRAFT_SCREENSHOTS_DIR}"
                fi

                rm -rf "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}"
            fi

            create_symlink "${MINECRAFT_SCREENSHOTS_DIR}" "${MINECRAFT_INSTANCE_SCREENSHOTS_DIR}"
        done
    fi
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
