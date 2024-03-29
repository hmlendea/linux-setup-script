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

        local GSETTING_SCHEMA="/org/gnome/desktop/notifications/application/$(echo ${APPLICATION} | sed 's/\./-/g' | tr '[:upper:]' '[:lower:]')/"
        GSETTING_SCHEMA="org.gnome.desktop.notifications.application:${GSETTING_SCHEMA}"

        if [[ "${PERMISSION}" == "notification" ]]; then
            set_gsetting "${GSETTING_SCHEMA}" enable "${STATE}"

            if [[ "${STATE}" == "false" ]]; then
                set_gsetting "${GSETTING_SCHEMA}" show-in-lock-screen false
            fi
        elif [[ "${PERMISSION}" == "notification_lockscreen" ]]; then
            set_gsetting "${GSETTING_SCHEMA}" show-in-lock-screen "${STATE}"
        fi

        if ${IS_FLATPAK_INSTALLED}; then
            if [[ "${PERMISSION}" == "background" ]]; then
                set_flatpak_permission "${APPLICATION}" "background" "background" "${STATE}"
            elif [[ "${PERMISSION}" == "location" ]]; then
                set_flatpak_permission "${APPLICATION}" "location" "location" "${STATE}"
            elif [[ "${PERMISSION}" == "network" ]]; then
                set_flatpak_shared "${APPLICATION}" "network" "${STATE}"
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

function get_flatpak_shared() {
    local APPLICATION="${1}"
    local OBJECT="${2}"

    for METADATA_FILE in    "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                            "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        [ ! -f "${METADATA_FILE}" ] && continue

        local SHARED_OBJECTS=$(grep "^shared=" "${METADATA_FILE}" | awk -F'=' '{print $2}')

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

    for METADATA_FILE in    "${ROOT_VAR_LIB}/flatpak/app/${APPLICATION}/current/active/metadata" \
                            "${XDG_DATA_HOME}/flatpak/app/${APPLICATION}/current/active/metadata"; do
        [ ! -f "${METADATA_FILE}" ] && continue

        local SHARED_OBJECTS=$(grep "^shared=" "${METADATA_FILE}" | awk -F'=' '{print $2}')
        local CURRENT_STATE=false

        get_flatpak_shared "${APPLICATION}" "${OBJECT}" && CURRENT_STATE=true

        [[ "${STATE}" == "${CURRENT_STATE}" ]] && return

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
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "com.discordapp.Discord" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    for TEAMS_APP in "com.github.IsmaelMartinez.teams_for_linux" "com.microsoft.teams"; do
        set_linux_permission "${TEAMS_APP}" \
            "background" false \
            "network" true \
            "notification" true \
            "notification_lockscreen" true \
            "location" false
    done
    for MINECRAFT_APP in "com.mojang.Minecraft" "org.prismlauncher.PrismLauncher"; do
        set_linux_permission "${MINECRAFT_APP}" \
            "background" false \
            "network" true \
            "notification" false \
            "location" false
    done
    set_linux_permission "com.getpostman.Postman" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "com.github.tchx84.Flatseal" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "com.simplenote.Simplenote" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "com.spotify.Client" \
        "background" false \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "com.github.vladimiry.ElectronMail" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    for STEAM_APP in "com.valvesoftware.Steam" "steam"; do
        set_linux_permission "${STEAM_APP}" \
            "background" true \
            "network" true \
            "notification" false \
            "location" false
    done
    set_linux_permission "com.obsproject.Studio" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for VSCODE_APP in "com.visualstudio.code" "visual-studio-code"; do
        set_linux_permission "${VSCODE_APP}" \
            "background" false \
            "network" true \
            "notification" false \
            "location" false
    done
    set_linux_permission "de.haeckerfelix.Fragments" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" false \
        "location" false
    set_linux_permission "fr.romainvigier.MetadataCleaner" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for AUDIO_PLAYER_APP in "io.bassi.Amberol" "org.gnome.Rhythmbox3"; do
        set_linux_permission "${AUDIO_PLAYER_APP}" \
            "background" false \
            "network" false \
            "notification" true \
            "notification_lockscreen" true \
            "location" false
    done
    set_linux_permission "io.github.hmlendea.geforcenow-electron" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "io.github.mimbrero.WhatsAppDesktop" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "net.lutris.Lutris" \
        "background" false \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "nl.hjdskes.gcolor3" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for APP in "org.chromium.Chromium" "chromium"; do
        set_linux_permission "${APP}" \
            "background" false \
            "network" true \
            "notification" false \
            "location" true
    done
    set_linux_permission "org.gimp.GIMP" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.baobab" \
        "background" false \
        "network" false \
        "notification" true \
        "notification_lockscreen" false \
        "location" false
    set_linux_permission "org.gnome.Calculator" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Calendar" \
        "background" false \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" true
    set_linux_permission "org.gnome.Cheese" \
        "background" false \
        "network" false \
        "notification" false \
        "location" true
    set_linux_permission "org.gnome.clocks" \
        "background" true \
        "network" false \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "org.gnome.Contacts" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for IMAGE_VIEWER_APP in "org.gnome.eog" "org.gnome.Loupe"; do
        set_linux_permission "${IMAGE_VIEWER_APP}" \
            "background" false \
            "network" false \
            "notification" false \
            "location" false
    done
    set_linux_permission "org.gnome.Evince" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.FileRoller" \
        "background" true \
        "network" false \
        "notification" true \
        "notification_lockscreen" false \
        "location" false
    set_linux_permission "org.gnome.font-viewer" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for TEXT_EDITOR_APP in "org.gnome.gedit" "org.gnome.TextEditor"; do
        set_linux_permission "${TEXT_EDITOR_APP}" \
            "background" false \
            "network" false \
            "notification" false \
            "location" false
    done
    set_linux_permission "org.gnome.Maps" \
        "background" false \
        "network" true \
        "notification" false \
        "location" true
    set_linux_permission "org.gnome.NetworkDisplays" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.seahorse.Application" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Settings" "notification" false
    set_linux_permission "org.gnome.Terminal" "notification" false
    set_linux_permission "org.gnome.TextEditor" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Todo" \
        "background" true \
        "network" true \
        "notification" true \
        "location" false
    set_linux_permission "org.gnome.Totem" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "org.gnome.Weather" \
        "background" false \
        "network" true \
        "notification" false \
        "location" true
    set_linux_permission "org.inkscape.Inkscape" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    set_linux_permission "org.libreoffice.LibreOffice" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
    for INTERNET_BROWSER_APP in "com.brave.browser" "org.mozilla.firefox"; do
        set_linux_permission "${INTERNET_BROWSER_APP}" \
            "background" false \
            "network" true \
            "notification" false \
            "location" true
    done
    set_linux_permission "org.signal.Signal" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "org.telegram.desktop" \
        "background" true \
        "network" true \
        "notification" true \
        "notification_lockscreen" true \
        "location" false
    set_linux_permission "ro.go.hmlendea.DL-Desktop" \
        "background" false \
        "network" true \
        "notification" false \
        "location" false
    set_linux_permission "ro.go.hmlendea.Sokogrump" \
        "background" false \
        "network" false \
        "notification" false \
        "location" false
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
    for APP in "io.gitlab.librewolf-community" "org.mozilla.fenix" "org.mozilla.firefox"; do
        set_android_permission "${APP}" \
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
    set_android_permission "ro.profi.store" \
        "location" false \
        "camera" false
fi
