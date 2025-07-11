#!/bin/bash
source 'scripts/common/common.sh'

GRUB_CFG_PATH="${ROOT_BOOT}/grub/grub.cfg"

[ ! -f "${ROOT_USR_BIN}/grub-reboot" ] && exit 1

function update_grub_rc {
    local OS_ROOT_DIR="${1}"
    local RC_FILE="${2}"

    local SOURCE_RC_PATH="${REPO_RC_DIR}/grub/${RC_FILE}"
    local TARGET_RC_PATH="${ROOT_ETC}/grub.d/${RC_FILE}"

    if [ -d "${OS_ROOT_DIR}" ] || [ "${OS_ROOT_DIR}" = '/' ]; then
        update_file_if_distinct "${SOURCE_RC_PATH}" "${TARGET_RC_PATH}"
    elif [ -f "${TARGET_RC_PATH}" ]; then
        remove "${TARGET_RC_PATH}"
    fi
}

function rename-menuentry {
    local OLD_NAME="${1}"
    local NEW_NAME="${2}"

    local QUOTE_PATTERN="[\'\"]"
    local NON_QUOTE_PATTERN="[^\'\"]"

    ! grep -q "^menuentry [\'\"]${OLD_NAME}[^\'\"]*[\'\"]" "${GRUB_CFG_PATH}" && return

    run_as_su sed -i 's/^menuentry ['\''\"]'"${OLD_NAME}"'[^'\''\"]*['\''\"]/menuentry '\'"${NEW_NAME}"\''/g' "${GRUB_CFG_PATH}"
}

function remove_advanced_options {
    local STARTING_LINE=-1
    local END_LINE=-1

    ! grep -q 'Advanced options for' "${GRUB_CFG_PATH}" && return

    STARTING_LINE=$(grep -n 'Advanced options for' "${GRUB_CFG_PATH}" | awk -F: '{print $1}' | head -n 1)
    END_LINE=$(grep -n "### END ${ROOT_ETC}/grub.d/10_linux" "${GRUB_CFG_PATH}" | awk -F: '{print $1}' | head -n 1)
    END_LINE=$((END_LINE-1))

    run_as_su sed -i "${STARTING_LINE}","${END_LINE}"d "${GRUB_CFG_PATH}"
}

update_grub_rc '/android' '29_android'
update_grub_rc '/blissos' '29_blissos'
update_grub_rc '/phoenixos' '29_phoenixos'
update_grub_rc '/primeos' '29_primeos'
update_grub_rc '/' '99_power'

if does_bin_exist 'update-grub'; then
    run_as_su update-grub
else
    run_as_su grub-mkconfig -o "${GRUB_CFG_PATH}"
fi

#rename-menuentry 'Arch Linux' 'Linux'
rename-menuentry 'Windows Boot Manager' 'Windows'
remove_advanced_options
