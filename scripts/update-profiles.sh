#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

SYSTEM_PROFILES_DIR="${ROOT_ETC}/profile.d"

function update-profile-for-bin() {
    local REQUIRED_BINARY="${1}"
    local PROFILE_NAME="${2}"
    local PROFILE_PATH="${SYSTEM_PROFILES_DIR}/${PROFILE_NAME}.sh"

    if does-bin-exist "${REQUIRED_BINARY}"; then
        update-file-if-needed "profiles/${PROFILE_NAME}.sh" "${PROFILE_PATH}"
    else
        remove "${PROFILE_PATH}"
    fi
}

update-profile-for-bin "dotnet" "dotnet"
update-profile-for-bin "make" "cmake"
