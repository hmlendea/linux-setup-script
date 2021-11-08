#!/bin/bash
source "scripts/common/common.sh"

[[ "${ARCH}" != "x86_64" ]] && exit

SYSTEM_PROFILES_DIRECTORY_PATH="${ROOT_ETC}/profile.d"

for PROFILE_FILE_RELATIVE_PATH in "profiles"/*; do
    PROFILE_FILE_NAME=$(basename "${PROFILE_FILE_RELATIVE_PATH}")
    PROFILE_SOURCE_FILE_PATH="${PWD}/${PROFILE_FILE_NAME}"
    PROFILE_TARGET_FILE_PATH="${SYSTEM_PROFILES_DIRECTORY_PATH}/${PROFILE_FILE_NAME}"
    echo " > Installing profile '${PROFILE_FILE_NAME}'"

    cp -f "${PROFILE_SOURCE_FILE_PATH}" "${PROFILE_TARGET_FILE_PATH}"
    chmod +x "${PROFILE_TARGET_FILE_PATH}"
done

