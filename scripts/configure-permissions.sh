#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/config.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"

function get_flatpak_permission() {
    local PACKAGE="${1}"
    local TABLE="${2}"
    local OBJECT="${3}"

    ! is_flatpak_installed "${PACKAGE}" && return

    flatpak permission-show "${PACKAGE}" | grep "^${TABLE}\s${OBJECT}\s" | awk '{print $4}'
}

function set_flatpak_permission() {
    local PACKAGE="${1}" && shift

    ! is_flatpak_installed "${PACKAGE}" && return

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entries: ${*}" >&2
        exit 1
    fi

    local PAIRS_COUNT=$(($# / 2))

    for I in $(seq 1 ${PAIRS_COUNT}); do
        local PERMISSION="${1}" && shift
        local VALUE="${1}" && shift

        local TABLE="${PERMISSION}"
        local OBJECT="${PERMISSION}"

        if echo "${PERMISSION}" | grep -q ":"; then
            TABLE=$(echo "${PERMISSION}" | awk -F":" '{print $1}')
            OBJECT=$(echo "${PERMISSION}" | awk -F":" '{print $2}')
        else
            [[ "${TABLE}" == "notification" ]] && TABLE="notifications"
        fi

        PERMISSION="${TABLE}:${OBJECT}"

        if [[ "${OBJECT}" == "notification" ]]; then
            local GSETTING_SCHEMA="/org/gnome/desktop/notifications/application/$(echo ${PACKAGE} | sed 's/\./-/g' | tr '[:upper:]' '[:lower:]')/"
            GSETTING_SCHEMA="org.gnome.desktop.notifications.application:${GSETTING_SCHEMA}"
            set_gsetting "${GSETTING_SCHEMA}" enable "${VALUE}"
        fi

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
    done
}

if does_bin_exist "flatpak"; then
    set_flatpak_permission "ca.desrt.dconf-editor" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "com.discordapp.Discord" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "com.brave.Browser" \
        "background" false \
        "notification" false \
        "location" true
    set_flatpak_permission "com.microsoft.Teams" \
        "background" false \
        "notification" true \
        "location" false
    set_flatpak_permission "com.mojang.Minecraft" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "com.getpostman.Postman" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "com.github.tchx84.Flatseal" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "com.simplenote.Simplenote" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "com.spotify.Client" \
        "background" false \
        "notification" true \
        "location" false
    set_flatpak_permission "com.github.vladimiry.ElectronMail" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "com.valvesoftware.Steam" \
        "background" true \
        "notification" false \
        "location" false
    set_flatpak_permission "com.visualstudio.code" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "de.haeckerfelix.Fragments" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "io.github.hmlendea.geforcenow-electron" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "nl.hjdskes.gcolor3" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gimp.GIMP" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.baobab" \
        "background" false \
        "notification" true \
        "location" false
    set_flatpak_permission "org.gnome.Calculator" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Calendar" \
        "background" false \
        "notification" true \
        "location" true
    set_flatpak_permission "org.gnome.clocks" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "org.gnome.Contacts" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.eog" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Evince" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.FileRoller" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "org.gnome.gedit" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Maps" \
        "background" false \
        "notification" false \
        "location" true
    set_flatpak_permission "org.gnome.NetworkDisplays" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Rhythmbox3" \
        "background" false \
        "notification" true \
        "location" false
    set_flatpak_permission "org.gnome.TextEditor" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Totem" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.gnome.Weather" \
        "background" false \
        "notification" false \
        "location" true
    set_flatpak_permission "org.inkscape.Inkscape" \
        "background" false \
        "notification" false \
        "location" false
    set_flatpak_permission "org.mozilla.firefox" \
        "background" false \
        "notification" false \
        "location" true
    set_flatpak_permission "org.signal.Signal" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "org.telegram.desktop" \
        "background" true \
        "notification" true \
        "location" false
    set_flatpak_permission "ro.go.hmlendea.DL-Desktop" \
        "background" false \
        "notification" false \
        "location" false
fi
