#!/bin/bash

function set_linux_permission() {
    local APPLICATION="${1}" && shift

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entries: ${*}" >&2
        exit 1
    fi

    local IS_SYSTEM_INSTALLED=false
    local IS_FLATPAK_INSTALLED=false

    is_flatpak_installed "${APPLICATION}" && IS_FLATPAK_INSTALLED=true
    [ -f "${ROOT_USR_SHARE}/applications/${APPLICATION}.desktop" ] && IS_SYSTEM_INSTALLED=true

    ! ${IS_SYSTEM_APP} && ! ${IS_FLATPAK_INSTALLED} && return

    local PAIRS_COUNT=$(($# / 2))
    for I in $(seq 1 ${PAIRS_COUNT}); do
        local PERMISSION="${1}" && shift
        local STATE="${1}" && shift

        local GSETTING_SCHEMA="/org/gnome/desktop/notifications/application/$(echo ${APPLICATION} | sed 's/\./-/g' | tr '[:upper:]' '[:lower:]')/"
        GSETTING_SCHEMA="org.gnome.desktop.notifications.application:${GSETTING_SCHEMA}"

        if [ '${PERMISSION}' = 'notification' ]; then
            set_gsetting "${GSETTING_SCHEMA}" enable "${STATE}"

            if [ "${STATE}" = 'false' ]; then
                set_gsetting "${GSETTING_SCHEMA}" 'show-in-lock-screen' false
            fi
        elif [ "${PERMISSION}" = 'notification_lockscreen' ]; then
            set_gsetting "${GSETTING_SCHEMA}" 'show-in-lock-screen' "${STATE}"
        fi

        if ${IS_FLATPAK_INSTALLED}; then
            if [ "${PERMISSION}" = 'background' ]; then
                set_flatpak_permission "${APPLICATION}" 'background' 'background' "${STATE}"
            elif [ "${PERMISSION}" = 'camera' ]; then
                set_flatpak_permission "${APPLICATION}" 'devices' 'camera' "${STATE}"                
            elif [ "${PERMISSION}" = 'location' ]; then
                set_flatpak_permission "${APPLICATION}" 'location' 'location' "${STATE}"
            elif [ "${PERMISSION}" = 'network' ]; then
                set_flatpak_shared "${APPLICATION}" 'network' "${STATE}"
            elif [ "${PERMISSION}" = 'notification' ]; then
                set_flatpak_permission "${APPLICATION}" 'notifications' 'notification' "${STATE}"
            fi
        fi
    done
}

function get_flatpak_permission() {
    local PACKAGE="${1}"
    local TABLE="${2}"
    local OBJECT="${3}"

    flatpak permission-show "${PACKAGE}" | grep "^${TABLE}\s${OBJECT}\s" | awk '{print $4}'
}

function set_flatpak_permission() {
    local PACKAGE="${1}"
    local TABLE="${2}"
    local OBJECT="${3}"
    local VALUE="${4}"

    if [ "${OBJECT}" = 'location' ]; then
        if [ "${VALUE}" = 'true' ]; then
            VALUE="EXACT,0"
        elif [ "${VALUE}" = 'false' ]; then
            VALUE="NONE,0"
        fi
    else
        if [ "${VALUE}" = 'true' ]; then
            VALUE='yes'
        elif [ "${VALUE}" = 'false' ]; then
            VALUE='no'
        fi
    fi

    local CURRENT_VALUE=$(get_flatpak_permission "${PACKAGE}" "${TABLE}" "${OBJECT}")

    if [ "${VALUE}" != "${CURRENT_VALUE}" ]; then
        flatpak permission-set "${TABLE}" "${OBJECT}" "${PACKAGE}" "${VALUE}"
        echo -e "\e[0;33m${PACKAGE}\e[0m permission \e[0;32m${PERMISSION}\e[0m >>> ${VALUE}"
    fi
}

function set_flatpak_device_access() {
    local PACKAGE="${1}"
    local DEVICE="${2}"
    local HAS_ACCESS="${3}"
}

function get_flatpak_shared() {
    local APPLICATION="${1}"
    local OBJECT="${2}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        [ ! -f "${METADATA_FILE}" ] && continue

        local SHARED_OBJECTS=$(grep '^shared=' "${METADATA_FILE}" | awk -F'=' '{print $2}')

        if echo "${SHARED_OBJECTS}" | grep -q "${OBJECT};"; then
            return 0 # True
        fi
    done

    return 1 # False
}

function set_flatpak_shared() {
    local APPLICATION="${1}"
    local OBJECT="${2}"
    local STATE="${3}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        [ ! -f "${METADATA_FILE}" ] && continue

        local SHARED_OBJECTS=$(grep '^shared=' "${METADATA_FILE}" | awk -F'=' '{print $2}')
        local CURRENT_STATE=false

        get_flatpak_shared "${APPLICATION}" "${OBJECT}" && CURRENT_STATE=true

        [ "${STATE}" = "${CURRENT_STATE}" ] && return

        if ${STATE}; then
            SHARED_OBJECTS="${OBJECT};${SHARED_OBJECTS}"
        else
            SHARED_OBJECTS=$(echo "${SHARED_OBJECTS}" | sed 's/'"${OBJECT}"';//g')
        fi

        echo -e "\e[0;33m${APPLICATION}\e[0m permission \e[0;32m${OBJECT}\e[0m >>> ${STATE}"
        run_as_su sed -i 's/^shared=.*/shared='"${SHARED_OBJECTS}"'/g' "${METADATA_FILE}"
    done
}

function get_android_permission() {
    local PACKAGE="${1}"
    local PERMISSION="${2}"
    local STATE='false'

    STATE=$(run_as_su dumpsys package "${PACKAGE}" | \
        grep "${PERMISSION}" | \
        grep 'granted' | \
        sed 's/.*granted=\([^,]*\).*/\1/g')

    [ -z "${STATE}" ] && STATE="false"

    echo "${STATE}"
}

function toggle_android_permission() {
    local PACKAGE="${1}"
    local PERMISSION="${2}"
    local VALUE="${3}"
    local CURRENT_VALUE="false"

    CURRENT_VALUE=$(get_android_permission "${PACKAGE}" "${PERMISSION}")

    if [[ "${VALUE}" != "${CURRENT_VALUE}" ]]; then
        echo -e "\e[0;33m${PACKAGE}\e[0m permission \e[0;32m${PERMISSION}\e[0m >>> ${VALUE}"
        if [ "${VALUE}" = 'true' ]; then
            call_android_package_manager grant "${PACKAGE}" "${PERMISSION}"
        else
            call_android_package_manager revoke "${PACKAGE}" "${PERMISSION}"
        fi
    fi
}

function set_android_permission() {
    local PACKAGE="${1}" && shift

    ! is_android_package_installed "${PACKAGE}" && return

    local PAIRS_COUNT=$(($# / 2))
    for I in $(seq 1 ${PAIRS_COUNT}); do
        local PERMISSION="${1}" && shift
        local VALUE="${1}" && shift

        if [ "${PERMISSION}" = 'accounts_get' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.GET_ACCOUNTS' "${VALUE}"
        elif [ "${PERMISSION}" = 'calendar' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_CALENDAR' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CALENDAR' "${VALUE}"
        elif [ "${PERMISSION}" = 'camera' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.CAMERA' "${VALUE}"
        elif [ "${PERMISSION}" = 'contacts' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_CONTACTS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CONTACTS' "${VALUE}"
        elif [ "${PERMISSION}" = 'contacts_read' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_CONTACTS' "${VALUE}"
        elif [ "${PERMISSION}" = 'contacts_write' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CONTACTS' "${VALUE}"
        elif [ "${PERMISSION}" = 'location' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_COARSE_LOCATION' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_FINE_LOCATION' "${VALUE}"
        elif [ "${PERMISSION}" = 'location' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_COARSE_LOCATION' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_FINE_LOCATION' "${VALUE}"
        elif [ "${PERMISSION}" = 'location_background' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_BACKGROUND_LOCATION' "${VALUE}"
        elif [ "${PERMISSION}" = 'microphone' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.RECORD_AUDIO' "${VALUE}"
        elif [ "${PERMISSION}" = 'phone_log' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_CALL_LOG' "${VALUE}"
        elif [ "${PERMISSION}" = 'phone' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.ANSWER_PHONE_CALLS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.CALL_PHONE' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_PHONE_NUMBERS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_PHONE_STATE' "${VALUE}"
        elif [ "${PERMISSION}" = 'physical_activity' ]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACTIVITY_RECOGNITION" "${VALUE}"
        elif [ "${PERMISSION}" = 'sms' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_SMS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.RECEIVE_MMS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.RECEIVE_SMS' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.SEND_SMS' "${VALUE}"
        elif [ "${PERMISSION}" = 'storage' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_EXTERNAL_STORAGE' "${VALUE}"
            toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_EXTERNAL_STORAGE' "${VALUE}"
        elif [ "${PERMISSION}" = 'storage_read' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.READ_EXTERNAL_STORAGE' "${VALUE}"
        elif [ "${PERMISSION}" = 'storage_media' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_MEDIA_LOCATION' "${VALUE}"
        elif [ "${PERMISSION}" = 'storage_write' ]; then
            toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_EXTERNAL_STORAGE' "${VALUE}"
        else
            toggle_android_permission "${PACKAGE}" "${PERMISSION}" "${VALUE}"
        fi
    done
}
