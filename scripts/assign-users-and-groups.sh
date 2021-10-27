#!/bin/bash
source "scripts/common/common.sh"

GROUPS_FILE="${ROOT_ETC}/group"

[ ! -f "${GROUPS_FILE}" ] && exit

function does_group_exist() {
    local GROUP_NAME="${1}"

    if [ $(grep -c "^${GROUP_NAME}" "${GROUPS_FILE}") -ge 1 ]; then
        return 0
    fi

    return 1
}

function is_user_in_group() {
    local GROUP_NAME="${1}"
    local USER_NAME="${2}"

    if getent group "${GROUP_NAME}" | grep -q "\b${USER_NAME}\b"; then
        return 0
    fi

    return 1
}

function add_user_to_group() {
    local GROUP_NAME="${1}"
    local USER_NAME="${2}"

    if $(does_group_exist "${GROUP_NAME}"); then
        if ! $(is_user_in_group "${GROUP_NAME}" "${USER_NAME}"); then
            usermod -a -G "${GROUP_NAME}" "${USER_NAME}"
        fi
    fi
}

add_user_to_group "realtime" "${USER}"
