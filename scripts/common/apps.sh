#!/bin/bash
source "scripts/common/filesystem.sh"

function get_firefox_profiles_dir() {
    local PROFILES_DIR=""

    PROFILES_DIR="${HOME_VAR_APP}/io.gitlab.librewolf-community/.librewolf"
    [ -d "${PROFILES_DIR}" ] && echo "${PROFILES_DIR}" && return

    PROFILES_DIR="${HOME_VAR_APP}/com.mozilla.firefox/.mozilla/firefox"
    [ -d "${PROFILES_DIR}" ] && echo "${PROFILES_DIR}" && return

    PROFILES_DIR="${HOME}/.librewolf"
    [ -d "${PROFILES_DIR}" ] && echo "${PROFILES_DIR}" && return

    PROFILES_DIR="${HOME}/.mozilla/firefox"
    [ -d "${PROFILES_DIR}" ] && echo "${PROFILES_DIR}" && return
}

function get_firefox_profile_id() {
    local PROFILES_DIR=$(get_firefox_profiles_dir)
    local PROFILES_INI_FILE="${PROFILES_DIR}/profiles.ini"
    local PROFILE_ID=$(grep "^Path=" "${PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

    echo "${PROFILE_ID}"
}

function get_firefox_profile_dir() {
    local PROFILES_DIR=$(get_firefox_profiles_dir)
    local PROFILE_ID=$(get_firefox_profile_id)

    echo "${PROFILES_DIR}/${PROFILE_ID}"
}
