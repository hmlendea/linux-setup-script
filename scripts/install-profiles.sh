#!/bin/bash

if [[ "$1" != "x86_64" ]]; then
    exit
fi

SYSTEM_PROFILES_DIRECTORY_PATH="/etc/profile.d"

for PROFILE_FILE_NAME in $(ls "profiles"); do
    PROFILE_SOURCE_FILE_PATH="${PWD}/profiles/${PROFILE_FILE_NAME}"
    PROFILE_TARGET_FILE_PATH="${SYSTEM_PROFILES_DIRECTORY_PATH}/${PROFILE_FILE_NAME}"
    echo " > Installing profile '${PROFILE_FILE_NAME}'"

    cp -f "${PROFILE_SOURCE_FILE_PATH}" "${PROFILE_TARGET_FILE_PATH}"
    chmod +x "${PROFILE_TARGET_FILE_PATH}"
done

