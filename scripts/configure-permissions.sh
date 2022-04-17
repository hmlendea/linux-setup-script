#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/config.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

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

        if [[ "${PERMISSION}" == "notification" ]]; then
            local GSETTING_SCHEMA="/org/gnome/desktop/notifications/application/$(echo ${APPLICATION} | sed 's/\./-/g' | tr '[:upper:]' '[:lower:]')/"
            GSETTING_SCHEMA="org.gnome.desktop.notifications.application:${GSETTING_SCHEMA}"
            set_gsetting "${GSETTING_SCHEMA}" enable "${STATE}"
        fi

        if ${IS_FLATPAK_INSTALLED}; then
            if [[ "${PERMISSION}" == "background" ]]; then
                set_flatpak_permission "${APPLICATION}" "background" "background" "${STATE}"
            elif [[ "${PERMISSION}" == "location" ]]; then
                set_flatpak_permission "${APPLICATION}" "location" "location" "${STATE}"
            elif [[ "${PERMISSION}" == "notification" ]]; then
                set_flatpak_permission "${APPLICATION}" "notifications" "notification" "${STATE}"
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

    if [[ "${OBJECT}" == "location" ]]; then
        if [[ "${VALUE}" == "true" ]]; then
            VALUE="EXACT,0"
        elif [[ "${VALUE}" == "false" ]]; then
            VALUE="NONE,0"
        fi
    else
        if [[ "${VALUE}" == "true" ]]; then
            VALUE="yes"
        elif [[ "${VALUE}" == "false" ]]; then
            VALUE="no"
        fi
    fi

    local CURRENT_VALUE=$(get_flatpak_permission "${PACKAGE}" "${TABLE}" "${OBJECT}")

    if [[ "${VALUE}" != "${CURRENT_VALUE}" ]]; then
        flatpak permission-set "${TABLE}" "${OBJECT}" "${PACKAGE}" "${VALUE}"
        echo -e "\e[0;33m${PACKAGE}\e[0m permission \e[0;32m${PERMISSION}\e[0m >>> ${VALUE}"
    fi
}

function get_android_permission() {
    local PACKAGE="${1}"
    local PERMISSION="${2}"
    local STATE="false"

    STATE=$(run_as_su dumpsys package "${PACKAGE}" | \
        grep "${PERMISSION}" | \
        grep "granted" | \
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
        if [[ "${VALUE}" == "true" ]]; then
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

        if [[ "${PERMISSION}" == "accounts_get" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.GET_ACCOUNTS" "${VALUE}"
        elif [[ "${PERMISSION}" == "calendar" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_CALENDAR" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.WRITE_CALENDAR" "${VALUE}"
        elif [[ "${PERMISSION}" == "camera" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.CAMERA" "${VALUE}"
        elif [[ "${PERMISSION}" == "contacts" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_CONTACTS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.WRITE_CONTACTS" "${VALUE}"
        elif [[ "${PERMISSION}" == "contacts_read" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_CONTACTS" "${VALUE}"
        elif [[ "${PERMISSION}" == "contacts_write" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.WRITE_CONTACTS" "${VALUE}"
        elif [[ "${PERMISSION}" == "location" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_COARSE_LOCATION" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_FINE_LOCATION" "${VALUE}"
        elif [[ "${PERMISSION}" == "location" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_COARSE_LOCATION" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_FINE_LOCATION" "${VALUE}"
        elif [[ "${PERMISSION}" == "location_background" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_BACKGROUND_LOCATION" "${VALUE}"
        elif [[ "${PERMISSION}" == "microphone" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.RECORD_AUDIO" "${VALUE}"
        elif [[ "${PERMISSION}" == "phone_log" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_CALL_LOG" "${VALUE}"
        elif [[ "${PERMISSION}" == "phone" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ANSWER_PHONE_CALLS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.CALL_PHONE" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.READ_PHONE_NUMBERS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.READ_PHONE_STATE" "${VALUE}"
        elif [[ "${PERMISSION}" == "physical_activity" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACTIVITY_RECOGNITION" "${VALUE}"
        elif [[ "${PERMISSION}" == "sms" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_SMS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.RECEIVE_MMS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.RECEIVE_SMS" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.SEND_SMS" "${VALUE}"
        elif [[ "${PERMISSION}" == "storage" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_EXTERNAL_STORAGE" "${VALUE}"
            toggle_android_permission "${PACKAGE}" "android.permission.WRITE_EXTERNAL_STORAGE" "${VALUE}"
        elif [[ "${PERMISSION}" == "storage_read" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.READ_EXTERNAL_STORAGE" "${VALUE}"
        elif [[ "${PERMISSION}" == "storage_media" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.ACCESS_MEDIA_LOCATION" "${VALUE}"
        elif [[ "${PERMISSION}" == "storage_write" ]]; then
            toggle_android_permission "${PACKAGE}" "android.permission.WRITE_EXTERNAL_STORAGE" "${VALUE}"
        else
            toggle_android_permission "${PACKAGE}" "${PERMISSION}" "${VALUE}"
        fi
    done
}

if does_bin_exist "flatpak"; then
    set_linux_permission "ca.desrt.dconf-editor" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "com.discordapp.Discord" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "com.brave.Browser" \
        "background" false \
        "notification" false \
        "location" true
    set_linux_permission "com.microsoft.Teams" \
        "background" false \
        "notification" true \
        "location" false
    set_linux_permission "com.mojang.Minecraft" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "com.getpostman.Postman" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "com.github.tchx84.Flatseal" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "com.simplenote.Simplenote" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "com.spotify.Client" \
        "background" false \
        "notification" true \
        "location" false
    set_linux_permission "com.github.vladimiry.ElectronMail" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "com.valvesoftware.Steam" \
        "background" true \
        "notification" false \
        "location" false
    set_linux_permission "com.visualstudio.code" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "de.haeckerfelix.Fragments" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "io.github.hmlendea.geforcenow-electron" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "nl.hjdskes.gcolor3" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gimp.GIMP" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.baobab" \
        "background" false \
        "notification" true \
        "location" false
    set_linux_permission "org.gnome.Calculator" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Calendar" \
        "background" false \
        "notification" true \
        "location" true
    set_linux_permission "org.gnome.clocks" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "org.gnome.Contacts" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.eog" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Evince" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.FileRoller" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "org.gnome.gedit" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Maps" \
        "background" false \
        "notification" false \
        "location" true
    set_linux_permission "org.gnome.NetworkDisplays" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Rhythmbox3" \
        "background" false \
        "notification" true \
        "location" false
    set_linux_permission "org.gnome.Settings" "notification" false
    set_linux_permission "org.gnome.Terminal" "notification" false
    set_linux_permission "org.gnome.TextEditor" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Totem" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Weather" \
        "background" false \
        "notification" false \
        "location" true
    set_linux_permission "org.inkscape.Inkscape" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "org.mozilla.firefox" \
        "background" false \
        "notification" false \
        "location" true
    set_linux_permission "org.signal.Signal" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "org.telegram.desktop" \
        "background" true \
        "notification" true \
        "location" false
    set_linux_permission "ro.go.hmlendea.DL-Desktop" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "ro.go.hmlendea.Sokogrump" \
        "background" false \
        "notification" false \
        "location" false
    set_linux_permission "visual-studio-code" "notification" false
fi

if [[ "${DISTRO_FAMILY}" == "Android" ]] \
&& ${HAS_SU_PRIVILEGES}; then
    set_android_permission "ch.protonmail.android" \
        "accounts_get" false \
        "contacts_read" true \
        "storage" true
    set_android_permission "com.aurora.store" "storage" true
    set_android_permission "com.beemdevelopment.aegis" "camera" true
    set_android_permission "com.bumble.app" \
        "accounts_get" false \
        "camera" false \
        "contacts" false \
        "location" true \
        "microphone" false \
        "phone" false \
        "storage" false
    set_android_permission "com.best.deskclock" "org.codeaurora.permission.POWER_OFF_ALARM" true
    set_android_permission "com.duolingo" \
        "accounts_get" false \
        "camera" false \
        "contacts" false \
        "microphone" true \
        "storage" false
    set_android_permission "com.spotify.music" \
        "accounts_get" false \
        "camera" false \
        "contacts" false \
        "microphone" false \
        "storage" false
    set_android_permission "com.revolut.revolut" \
        "accounts_get" false \
        "camera" false \
        "contacts" true \
        "location" false \
        "microphone" false \
        "phone" false \
        "storage" false
    set_android_permission "com.google.android.apps.photos" \
        "accounts_get" true \
        "contacts" false \
        "location" false \
        "microphone" false \
        "phone" false \
        "storage" true \
        "storage_media" true
    set_android_permission "com.odysee.app" "storage" false
    set_android_permission "com.secuso.privacyFriendlyCodeScanner" "camera" true
    set_android_permission "com.vanced.android.youtube" \
        "accounts_get" false \
        "camera" false \
        "contacts" false \
        "location" false \
        "microphone" false \
        "phone" false \
        "storage" false
    set_android_permission "com.whatsapp" \
        "accounts_get" false \
        "location" false \
        "camera" true \
        "contacts" true \
        "microphone" false \
        "phone_log" false \
        "phone" false \
        "sms" false \
        "storage" true
    set_android_permission "com.x8bit.bitwarden" \
        "camera" false \
        "storage" false
    set_android_permission "de.stocard.stocard" \
        "camera" false \
        "location" false \
        "location_background" false \
        "storage" false
    set_android_permission "foundation.e.apps" "storage" true
    set_android_permission "foundation.e.calendar" \
        "calendar" true \
        "contacts_read" true \
        "storage" true
    set_android_permission "io.homeassistant.companion.android.minimal" \
        "camera" false \
        "location" false \
        "location_background" false \
        "microphone" false \
        "phone" false \
        "physical_activity" false \
        "storage" false
    set_android_permission "me.austinhuang.instagrabber" \
        "camera" false \
        "microphone" false \
        "storage" false
    set_android_permission "net.osmand" \
        "camera" false \
        "location" true \
        "microphone" false \
        "storage" false
    set_android_permission "org.codeaurora.snapcam" \
        "camera" true \
        "location" true \
        "microphone" true \
        "storage" true
    for FIREFOX_APP in "org.mozilla.fenix" "org.mozilla.firefox"; do
        set_android_permission "${FIREFOX_APP}" \
            "camera" false \
            "location" false \
            "microphone" false \
            "storage" false
    done
    set_android_permission "org.thoughtcrime.securesms" \
        "accounts_get" false \
        "location" false \
        "calendar" false \
        "camera" true \
        "contacts" true \
        "microphone" true \
        "phone" false \
        "sms" true \
        "storage_read" true
    set_android_permission "wangdaye.com.geometricweather" \
        "location" true \
        "location_background" true \
        "phone" false \
        "storage" false
fi
