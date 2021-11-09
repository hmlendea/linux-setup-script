#!/bin/bash
source "scripts/common/common.sh"

SOURCE_GRUB_RC_DIR=$(pwd)"/rc/grub"
TARGET_GRUB_RC_DIR="${ROOT_ETC}/grub.d"
GRUB_CFG_PATH="${ROOT_BOOT}/grub/grub.cfg"

[ ! -f "${ROOT_USR_BIN}/grub-reboot" ] && exit 1

function update-grub-rc {
    local OS_ROOT_DIR="${1}"
    local RC_FILE="${2}"

    local SOURCE_RC_PATH="${SOURCE_GRUB_RC_DIR}/${RC_FILE}"
    local TARGET_RC_PATH="${TARGET_GRUB_RC_DIR}/${RC_FILE}"

    if [[ -d "${OS_ROOT_DIR}" ]] || [[ "${OS_ROOT_DIR}" == "/" ]]; then
        update-file-if-needed "${SOURCE_RC_PATH}" "${TARGET_RC_PATH}"
    elif [ -f "${TARGET_RC_PATH}" ]; then
        rm "${TARGET_RC_PATH}"
    fi
}

function rename-menuentry {
    local OLD_NAME="${1}"
    local NEW_NAME="${2}"

    sed -i 's/^menuentry ['\''\"]'"${OLD_NAME}"'[^'\''\"]*['\''\"]/menuentry '\'"${NEW_NAME}"\''/g' "${GRUB_CFG_PATH}"
}

function remove_advanced_options {
    local STARTING_LINE=-1
    local END_LINE=-1

    STARTING_LINE=$(grep -n "Advanced options for" "${GRUB_CFG_PATH}" | awk -F: '{print $1}' | head -n 1)
    END_LINE=$(grep -n "### END /etc/grub.d/10_linux" "${GRUB_CFG_PATH}" | awk -F: '{print $1}' | head -n 1)
    END_LINE=$((END_LINE-1))

    sed -i "${STARTING_LINE}","${END_LINE}"d "${GRUB_CFG_PATH}"
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
