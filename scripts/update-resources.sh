#!/bin/bash
source "scripts/common/common.sh"

RESOURCES_DIR=$(pwd)"/resources"

copy_res() {
    APPLICATION="${1}"
    SOURCE_FILE="${RESOURCES_DIR}/${2}"
    TARGET_FILE="${3}"
    TARGET_DIR=$(dirname "${TARGET_FILE}")

    if (! does-bin-exist "${APPLICATION}"); then
        if [ -f "${TARGET_FILE}" ]; then
            echo "Removing \"${TARGET_FILE}\""
            rm "${TARGET_FILE}"
        fi

        return
    fi

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

copy_res "${ROOT_USR_BIN}/lxpanel" "lxpanel/applications.png"               "${HOME}/.config/lxpanel/LXDE/panels/applications.png"
copy_res "${ROOT_USR_BIN}/lxpanel" "lxpanel/applications_ro.png"            "${HOME}/.config/lxpanel/LXDE/panels/applications_ro.png"
copy_res "${ROOT_USR_BIN}/lxpanel" "lxpanel/power.png"                      "${HOME}/.config/lxpanel/LXDE/panels/power.png"
copy_res "${ROOT_USR_BIN}/lxpanel" "lxpanel/lxde-logout-gnomified.desktop"  "${HOME}/.local/share/applications/lxde-logout-gnomified.desktop"
copy_res "${ROOT_USR_BIN}/lxpanel" "plank/autostart.desktop"                "${HOME}/.config/autostart/plank.desktop"

# PCManFM's context menu
copy_res "${ROOT_USR_BIN}/code-oss"     "pcmanfm/open-in-code.desktop"      "${HOME}/.local/share/file-manager/actions/open-in-code.desktop"
copy_res "${ROOT_USR_BIN}/lxterminal"   "pcmanfm/open-in-terminal.desktop"  "${HOME}/.local/share/file-manager/actions/open-in-terminal.desktop"
