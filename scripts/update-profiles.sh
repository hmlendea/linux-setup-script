#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

SYSTEM_PROFILES_DIR="${ROOT_ETC}/profile.d"

function update_profile_for_bin {
    local REQUIRED_BINARY="${1}"
    local PROFILE_NAME="${2}"
    local PROFILE_PATH="${SYSTEM_PROFILES_DIR}/${PROFILE_NAME}.sh"

    if does_bin_exist "${REQUIRED_BINARY}"; then
        update_file_if_distinct "profiles/${PROFILE_NAME}.sh" "${PROFILE_PATH}"
    else
        remove "${PROFILE_PATH}"
    fi
}

update_profile_for_bin 'dotnet' 'dotnet'
update_profile_for_bin 'make' 'cmake'
