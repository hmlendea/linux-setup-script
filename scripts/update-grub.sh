#!/bin/bash

SOURCE_GRUB_RC_DIR=$(pwd)"/rc/grub"
TARGET_GRUB_RC_DIR="/etc/grub.d"
GRUB_CFG_FILE_PATH="/boot/grub/grub.cfg"

[ ! -f "/usr/bin/grub-reboot" ] && exit 1

if [ -f "/usr/bin/update-grub" ]; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

function update-grub-rc {
    ROOT_DIR="${1}"
    RC_FILE="${2}"

    SOURCE_RC_PATH="${SOURCE_GRUB_RC_DIR}/${RC_FILE}"
    TARGET_RC_PATH="${TARGET_GRUB_RC_DIR}/${RC_FILE}"

    if [ -d "${ROOT_DIR}" ]; then
        NEEDS_UPDATING=true

        if [ -f "${TARGET_RC_PATH}" ]; then
            SOURCE_RC_CHECKSUM=$(sha256sum "${SOURCE_RC_PATH}")
            TARGET_RC_CHECKSUM=$(sha256sum "${TARGET_RC_PATH}")

            if [ "${SOURCE_RC_CHECKSUM}" != "${TARGET_RC_CHECKSUM}" ]; then
                NEEDS_UPDATING=false
            fi
        fi

        ${NEEDS_UPDATING} && cp "${SOURCE_RC_PATH}" "${TARGET_RC_PATH}"
    elif [ -f "${TARGET_RC_PATH}" ]; then
        rm "${TARGET_RC_PATH}"
    fi
}

function rename-menuentry {
    OLD_NAME=${1}
    NEW_NAME=${2}

    sed -i 's/^menuentry ['\''\"]'"${OLD_NAME}"'[^'\''\"]*['\''\"]/menuentry '\'"${NEW_NAME}"\''/g' ${GRUB_CFG_FILE_PATH}
}

rename-menuentry "Arch Linux" "Linux"
rename-menuentry "Windows Boot Manager" "Windows"

update-grub-rc "/primeos" "50_primeos"
update-grub-rc "/android" "59_android"
update-grub-rc "/" "99_power"
