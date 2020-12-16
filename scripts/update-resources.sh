#!/bin/bash

RESOURCES_DIR=$(pwd)"/resources"

copy_res() {
    SOURCE_FILE="${RESOURCES_DIR}/${1}"
    TARGET_FILE="${2}"
    TARGET_DIR=$(dirname "${TARGET_FILE}")

    if [ ! -d "${TARGET_DIR}" ]; then
        echo "Creating the directory: ${TARGET_DIR}" >&2
        mkdir -p "${TARGET_DIR}"
    fi

    if [ -f "${TARGET_FILE}" ]; then
        SOURCE_MD5=$(md5sum "${SOURCE_FILE}" | awk '{print $1}')
        TARGET_MD5=$(md5sum "${TARGET_FILE}" | awk '{print $1}')

        if [ "${SOURCE_MD5}" == "${TARGET_MD5}" ]; then
            return
        fi
    fi

    echo "Copying '${SOURCE_FILE}' to '${TARGET_FILE}'..." >&2
    cp "${SOURCE_FILE}" "${TARGET_FILE}"
}

[ -f "/usr/bin/lxpanel" ]   && copy_res "lxpanel/applications.png"                      "${HOME}/.config/lxpanel/LXDE/panels/applications.png"
[ -f "/usr/bin/lxpanel" ]   && copy_res "lxpanel/applications_ro.png"                   "${HOME}/.config/lxpanel/LXDE/panels/applications_ro.png"
[ -f "/usr/bin/lxpanel" ]   && copy_res "lxpanel/power.png"                             "${HOME}/.config/lxpanel/LXDE/panels/power.png"
[ -f "/usr/bin/lxpanel" ]   && copy_res "lxpanel/lxde-logout-gnomeshellified.desktop"   "/usr/share/applications/lxd-logout-gnomeshellified.desktop"
[ -f "/usr/bin/plank" ]     && copy_res "plank/autostart.desktop"                       "${HOME}/.config/autostart/plank.desktop"
