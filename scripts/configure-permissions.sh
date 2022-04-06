#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"

function get_flatpak_permission() {
    local PACKAGE="${1}"
    local TABLE="${2}"
    local OBJECT="${3}"

    ! is_flatpak_installed "${PACKAGE}" && return

    [ -z "${OBJECT}" ] && OBJECT="${TABLE}"

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

        local TABLE=$(echo "${PERMISSION}" | awk -F":" '{print $1}')
        local OBJECT=$(echo "${PERMISSION}" | awk -F":" '{print $2}')

        [ -z "${OBJECT}" ] && OBJECT="${TABLE}"

        PERMISSION="${TABLE}:${OBJECT}"

        [[ "${VALUE}" == "true" ]] && VALUE="yes"
        [[ "${VALUE}" == "false" ]] && VALUE="no"

        local CURRENT_VALUE=$(get_flatpak_permission "${PACKAGE}" "${TABLE}" "${OBJECT}")

        if [[ "${VALUE}" != "${CURRENT_VALUE}" ]]; then
           flatpak permission-set "${TABLE}" "${OBJECT}" "${PACKAGE}" "${VALUE}"
            echo -e "\e[0;33m${PACKAGE}\e[0m permission \e[0;32m${PERMISSION}\e[0m >>> ${VALUE}"
        fi
    done
}

if does_bin_exist "flatpak"; then
    set_flatpak_permission "com.discordapp.Discord" \
        "background" true \
        "notifications:notification" true
    set_flatpak_permission "com.microsoft.Teams" \
        "background" false \
        "notifications:notification" true
    set_flatpak_permission "com.mojang.Minecraft" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "com.getpostman.Postman" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "com.simplenote.Simplenote" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "com.github.vladimiry.ElectronMail" \
        "background" true \
        "notifications:notification" true
    set_flatpak_permission "com.valvesoftware.Steam" \
        "background" true \
        "notifications:notification" false
    set_flatpak_permission "de.haeckerfelix.Fragments" \
        "background" true \
        "notifications:notification" true
    set_flatpak_permission "io.github.hmlendea.geforcenow-electron" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "nl.hjdskes.gcolor3" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gimp.GIMP" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.baobab" \
        "background" false \
        "notifications:notification" true
    set_flatpak_permission "org.gnome.Calculator" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Calendar" \
        "background" false \
        "notifications:notification" true
    set_flatpak_permission "org.gnome.Contacts" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.eog" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Evince" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.gedit" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Maps" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.NetworkDisplays" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Rhythmbox3" "background" false
    set_flatpak_permission "org.gnome.TextEditor" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Totem" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.gnome.Weather" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.inkscape.Inkscape" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.mozilla.firefox" \
        "background" false \
        "notifications:notification" false
    set_flatpak_permission "org.signal.Signal" \
        "background" true \
        "notifications:notification" true
    set_flatpak_permission "org.telegram.desktop" \
        "background" true \
        "notifications:notification" true
fi
