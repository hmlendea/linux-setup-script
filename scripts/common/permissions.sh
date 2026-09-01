#!/bin/bash

function set_linux_permission() {
    local APPLICATION="${1}" && shift

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_linux_permission: ${*}" >&2
        exit 1
    fi

    local IS_SYSTEM_INSTALLED=false
    local IS_FLATPAK_INSTALLED=false

    is_flatpak_installed "${APPLICATION}" && IS_FLATPAK_INSTALLED=true
    [ -f "${ROOT_USR_SHARE}/applications/${APPLICATION}.desktop" ] && IS_SYSTEM_INSTALLED=true

    ! ${IS_SYSTEM_INSTALLED} && ! ${IS_FLATPAK_INSTALLED} && return

    local MICROPHONE_STATE=''
    local SPEAKERS_STATE=''
    local NORMALISED_APPLICATION
    local GSETTING_SCHEMA

    NORMALISED_APPLICATION=$(echo "${APPLICATION}" | sed 's/\./-/g' | tr '[:upper:]' '[:lower:]')
    GSETTING_SCHEMA="org.gnome.desktop.notifications.application:/org/gnome/desktop/notifications/application/${NORMALISED_APPLICATION}/"

    while [ $# -gt 0 ]; do
        local PERMISSION="${1}" && shift
        local STATE="${1}" && shift

        [ "${PERMISSION}" = 'microphone' ] && MICROPHONE_STATE="${STATE}"
        [ "${PERMISSION}" = 'speakers' ] && SPEAKERS_STATE="${STATE}"

        if [ "${PERMISSION}" = 'notification' ]; then
            set_gsetting "${GSETTING_SCHEMA}" enable "${STATE}"

            if [ "${STATE}" = 'false' ]; then
                set_gsetting "${GSETTING_SCHEMA}" 'show-in-lock-screen' false
            fi
        elif [ "${PERMISSION}" = 'notification_lockscreen' ]; then
            set_gsetting "${GSETTING_SCHEMA}" 'show-in-lock-screen' "${STATE}"
        fi

        if ${IS_FLATPAK_INSTALLED}; then
            case "${PERMISSION}" in
                background)
                    set_flatpak_permission "${APPLICATION}" 'background' 'background' "${STATE}"
                    ;;
                camera)
                    set_flatpak_permission "${APPLICATION}" 'devices' 'camera' "${STATE}"
                    ;;
                all-devices)
                    set_flatpak_device "${APPLICATION}" 'all' "${STATE}"
                    ;;
                shared-memory)
                    set_flatpak_device "${APPLICATION}" 'shm' "${STATE}"
                    ;;
                filesystem-home)
                    set_flatpak_filesystem "${APPLICATION}" 'home' "${STATE}"
                    ;;
                microphone)
                    set_flatpak_permission "${APPLICATION}" 'devices' 'microphone' "${STATE}"
                    ;;
                speakers)
                    set_flatpak_permission "${APPLICATION}" 'devices' 'speakers' "${STATE}"
                    ;;
                location)
                    set_flatpak_permission "${APPLICATION}" 'location' 'location' "${STATE}"
                    ;;
                network)
                    set_flatpak_shared "${APPLICATION}" 'network' "${STATE}"
                    ;;
                notification)
                    set_flatpak_permission "${APPLICATION}" 'notifications' 'notification' "${STATE}"
                    ;;
            esac
        fi
    done

    if ${IS_FLATPAK_INSTALLED}; then
        if [ -n "${MICROPHONE_STATE}" ] || [ -n "${SPEAKERS_STATE}" ]; then

            [ -z "${MICROPHONE_STATE}" ] && MICROPHONE_STATE=true
            [ -z "${SPEAKERS_STATE}" ] && SPEAKERS_STATE=true

            if [ "${MICROPHONE_STATE}" = 'false' ] \
            && [ "${SPEAKERS_STATE}" = 'false' ]; then
                set_flatpak_socket "${APPLICATION}" 'pulseaudio' false
            else
                set_flatpak_socket "${APPLICATION}" 'pulseaudio' true
            fi
        fi
    fi
}

function get_flatpak_permission() {
    local PACKAGE="${1}"
    local TABLE="${2}"
    local OBJECT="${3}"

    flatpak permission-show "${PACKAGE}" | grep "^${TABLE}\s${OBJECT}\s" | awk '{print $4}'
}

function get_flatpak_metadata_value() {
    local METADATA_FILE="${1}"
    local FIELD="${2}"

    [ ! -f "${METADATA_FILE}" ] && return 1

    grep "^${FIELD}=" "${METADATA_FILE}" | awk -F'=' '{print $2}'
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
        echo -e "\e[0;33m${PACKAGE}\e[0m permission \e[0;32m${OBJECT}\e[0m >>> ${VALUE}"
    fi
}

function get_flatpak_shared() {
    local APPLICATION="${1}"
    local OBJECT="${2}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local SHARED_OBJECTS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'shared')"

        [ -z "${SHARED_OBJECTS}" ] && continue

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
    local CURRENT_STATE=false

    get_flatpak_shared "${APPLICATION}" "${OBJECT}" && CURRENT_STATE=true

    [ "${STATE}" = "${CURRENT_STATE}" ] && return

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local SHARED_OBJECTS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'shared')"

        [ -z "${SHARED_OBJECTS}" ] && continue

        if ${STATE}; then
            SHARED_OBJECTS="${OBJECT};${SHARED_OBJECTS}"
        else
            SHARED_OBJECTS=$(echo "${SHARED_OBJECTS}" | sed 's/'"${OBJECT}"';//g')
        fi

        local SHARED_OBJECTS_ESCAPED=""

        SHARED_OBJECTS_ESCAPED=$(printf '%s' "${SHARED_OBJECTS}" | sed -e 's/[\\/&]/\\&/g')

        echo -e "\e[0;33m${APPLICATION}\e[0m permission \e[0;32m${OBJECT}\e[0m >>> ${STATE}"
        run_as_su sed -i "s/^shared=.*/shared=${SHARED_OBJECTS_ESCAPED}/g" "${METADATA_FILE}"
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

    while [ $# -gt 0 ]; do
        local PERMISSION="${1}" && shift
        local VALUE="${1}" && shift

        case "${PERMISSION}" in
            accounts_get)
                toggle_android_permission "${PACKAGE}" 'android.permission.GET_ACCOUNTS' "${VALUE}"
                ;;
            calendar)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_CALENDAR' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CALENDAR' "${VALUE}"
                ;;
            camera)
                toggle_android_permission "${PACKAGE}" 'android.permission.CAMERA' "${VALUE}"
                ;;
            contacts)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_CONTACTS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CONTACTS' "${VALUE}"
                ;;
            contacts_read)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_CONTACTS' "${VALUE}"
                ;;
            contacts_write)
                toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_CONTACTS' "${VALUE}"
                ;;
            location)
                toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_COARSE_LOCATION' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_FINE_LOCATION' "${VALUE}"
                ;;
            location_background)
                toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_BACKGROUND_LOCATION' "${VALUE}"
                ;;
            microphone)
                toggle_android_permission "${PACKAGE}" 'android.permission.RECORD_AUDIO' "${VALUE}"
                ;;
            phone_log)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_CALL_LOG' "${VALUE}"
                ;;
            phone)
                toggle_android_permission "${PACKAGE}" 'android.permission.ANSWER_PHONE_CALLS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.CALL_PHONE' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_PHONE_NUMBERS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_PHONE_STATE' "${VALUE}"
                ;;
            physical_activity)
                toggle_android_permission "${PACKAGE}" 'android.permission.ACTIVITY_RECOGNITION' "${VALUE}"
                ;;
            sms)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_SMS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.RECEIVE_MMS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.RECEIVE_SMS' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.SEND_SMS' "${VALUE}"
                ;;
            storage)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_EXTERNAL_STORAGE' "${VALUE}"
                toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_EXTERNAL_STORAGE' "${VALUE}"
                ;;
            storage_read)
                toggle_android_permission "${PACKAGE}" 'android.permission.READ_EXTERNAL_STORAGE' "${VALUE}"
                ;;
            storage_media)
                toggle_android_permission "${PACKAGE}" 'android.permission.ACCESS_MEDIA_LOCATION' "${VALUE}"
                ;;
            storage_write)
                toggle_android_permission "${PACKAGE}" 'android.permission.WRITE_EXTERNAL_STORAGE' "${VALUE}"
                ;;
            *)
                toggle_android_permission "${PACKAGE}" "${PERMISSION}" "${VALUE}"
                ;;
        esac
    done
}

function get_flatpak_filesystem() {
    local APPLICATION="${1}"
    local FILESYSTEM="${2}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local FILESYSTEMS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'filesystems')"

        [ -z "${FILESYSTEMS}" ] && continue

        if echo "${FILESYSTEMS}" | grep -q "^${FILESYSTEM};\|;${FILESYSTEM};\|;${FILESYSTEM}$\|^${FILESYSTEM}$"; then
            return 0
        fi
    done

    return 1
}

function set_flatpak_device() {
    local APPLICATION="${1}"
    local DEVICE="${2}"
    local STATE="${3}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local DEVICES="$(get_flatpak_metadata_value "${METADATA_FILE}" 'devices')"

        [ -z "${DEVICES}" ] && continue

        if echo "${DEVICES}" | grep -q "^${DEVICE};\|;${DEVICE};\|;${DEVICE}$\|^${DEVICE}$"; then
            ${STATE} && continue

            DEVICES=$(echo "${DEVICES}" | sed 's/\(^\|;\)'"${DEVICE}"'\($\|;\)/;/g')
            DEVICES=$(echo "${DEVICES}" | sed 's/^;//;s/;$//;s/;;*/;/g')
        else
            ${STATE} || continue

            DEVICES="${DEVICE};${DEVICES}"
        fi

        local DEVICES_ESCAPED=""

        DEVICES_ESCAPED=$(printf '%s' "${DEVICES}" | sed -e 's/[\\/&]/\\&/g')

        echo -e "\e[0;33m${APPLICATION}\e[0m device \e[0;32m${DEVICE}\e[0m >>> ${STATE}"
        run_as_su sed -i "s/^devices=.*/devices=${DEVICES_ESCAPED}/g" "${METADATA_FILE}"
    done
}

function set_flatpak_filesystem() {
    local APPLICATION="${1}"
    local FILESYSTEM="${2}"
    local STATE="${3}"
    local CURRENT_STATE=false

    get_flatpak_filesystem "${APPLICATION}" "${FILESYSTEM}" && CURRENT_STATE=true

    [ "${STATE}" = "${CURRENT_STATE}" ] && return

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local FILESYSTEMS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'filesystems')"

        [ -z "${FILESYSTEMS}" ] && continue

        if ${STATE}; then
            echo "${FILESYSTEMS}" | grep -q "${FILESYSTEM}" || FILESYSTEMS="${FILESYSTEM};${FILESYSTEMS}"
        else
            FILESYSTEMS=$(echo "${FILESYSTEMS}" | sed 's/\(^\|;\)'"${FILESYSTEM}"'\($\|;\)/;/g')
            FILESYSTEMS=$(echo "${FILESYSTEMS}" | sed 's/^;//;s/;$//;s/;;*/;/g')
        fi

        local FILESYSTEMS_ESCAPED=""

        FILESYSTEMS_ESCAPED=$(printf '%s' "${FILESYSTEMS}" | sed -e 's/[\\/&]/\\&/g')

        echo -e "\e[0;33m${APPLICATION}\e[0m filesystem \e[0;32m${FILESYSTEM}\e[0m >>> ${STATE}"
        run_as_su sed -i "s/^filesystems=.*/filesystems=${FILESYSTEMS_ESCAPED}/g" "${METADATA_FILE}"
    done
}

function get_flatpak_socket() {
    local APPLICATION="${1}"
    local SOCKET="${2}"

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local SOCKETS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'sockets')"

        [ -z "${SOCKETS}" ] && continue

        if echo "${SOCKETS}" | grep -q "${SOCKET};"; then
            return 0 # True
        fi
    done

    return 1 # False
}

function set_flatpak_socket() {
    local APPLICATION="${1}"
    local SOCKET="${2}"
    local STATE="${3}"
    local CURRENT_STATE=false

    get_flatpak_socket "${APPLICATION}" "${SOCKET}" && CURRENT_STATE=true

    [ "${STATE}" = "${CURRENT_STATE}" ] && return

    for METADATA_FILE in "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                         "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        local SOCKETS="$(get_flatpak_metadata_value "${METADATA_FILE}" 'sockets')"

        [ -z "${SOCKETS}" ] && continue

        if ${STATE}; then
            echo "${SOCKETS}" | grep -q "${SOCKET};" || SOCKETS="${SOCKET};${SOCKETS}"
        else
            SOCKETS=$(echo "${SOCKETS}" | sed 's/'"${SOCKET}"';//g')
        fi

        local SOCKETS_ESCAPED=""

        SOCKETS_ESCAPED=$(printf '%s' "${SOCKETS}" | sed -e 's/[\\/&]/\\&/g')

        echo -e "\e[0;33m${APPLICATION}\e[0m socket \e[0;32m${SOCKET}\e[0m >>> ${STATE}"
        run_as_su sed -i "s/^sockets=.*/sockets=${SOCKETS_ESCAPED}/g" "${METADATA_FILE}"
    done
}
