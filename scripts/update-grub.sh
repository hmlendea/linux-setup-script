#!/bin/bash
source "scripts/common/common.sh"

SOURCE_GRUB_RC_DIR=$(pwd)"/rc/grub"
TARGET_GRUB_RC_DIR="${ROOT_ETC}/grub.d"
GRUB_CFG_PATH="${ROOT_BOOT}/grub/grub.cfg"

[ ! -f "${ROOT_USR_BIN}/grub-reboot" ] && exit 1

function update-grub-rc {
    OS_ROOT_DIR="${1}"
    RC_FILE="${2}"

    SOURCE_RC_PATH="${SOURCE_GRUB_RC_DIR}/${RC_FILE}"
    TARGET_RC_PATH="${TARGET_GRUB_RC_DIR}/${RC_FILE}"

    if [ -d "${OS_ROOT_DIR}" ] || [ "${OS_ROOT_DIR}" == "/" ]; then
        DO_COPY=false

        if [ -f "${TARGET_RC_PATH}" ]; then
            SOURCE_RC_CHECKSUM=$(sha256sum "${SOURCE_RC_PATH}")
            TARGET_RC_CHECKSUM=$(sha256sum "${TARGET_RC_PATH}")

            if [ "${SOURCE_RC_CHECKSUM}" != "${TARGET_RC_CHECKSUM}" ]; then
                DO_COPY=true
            fi
        else
            DO_COPY=true
        fi

        if ${DO_COPY}; then
            cp "${SOURCE_RC_PATH}" "${TARGET_RC_PATH}"
        fi
    elif [ -f "${TARGET_RC_PATH}" ]; then
        rm "${TARGET_RC_PATH}"
    fi
}

function rename-menuentry {
    OLD_NAME=${1}
    NEW_NAME=${2}

    sed -i 's/^menuentry ['\''\"]'"${OLD_NAME}"'[^'\''\"]*['\''\"]/menuentry '\'"${NEW_NAME}"\''/g' ${GRUB_CFG_PATH}
}

function remove_advanced_options {
    local STARTING_LINE=$(cat "${GRUB_CFG_PATH}" | grep -n "Advanced options for" | awk -F: '{print $1}' | head -n 1)
    local END_LINE=$(cat "${GRUB_CFG_PATH}" | grep -n "### END /etc/grub.d/10_linux" | awk -F: '{print $1}' | head -n 1)
    local EOF_LINE=$(wc -l "${GRUB_CFG_PATH}" | awk '{print $1}')

    END_LINE=$((END_LINE-1))

    sed -i ${STARTING_LINE},${END_LINE}d "${GRUB_CFG_PATH}"
}

update-grub-rc "/android" "29_android"
update-grub-rc "/blissos" "29_blissos"
update-grub-rc "/phoenixos" "29_phoenixos"
update-grub-rc "/primeos" "29_primeos"
update-grub-rc "/" "99_power"

if [ -f "${ROOT_USR_BIN}/update-grub" ]; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

#rename-menuentry "Arch Linux" "Linux"
rename-menuentry "Windows Boot Manager" "Windows"
remove_advanced_options
