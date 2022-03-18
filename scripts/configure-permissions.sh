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
    local PACKAGE="${1}"
    local PERMISSION="${2}"
    local VALUE="${3}"

    ! is_flatpak_installed "${PACKAGE}" && return

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
}

if does_bin_exist "flatpak"; then
    set_flatpak_permission "com.microsoft.Teams" "background" false
    set_flatpak_permission "com.mojang.Minecraft" "background" false
    set_flatpak_permission "com.getpostman.Postman" "background" false
    set_flatpak_permission "com.simplenote.Simplenote" "background" false
    set_flatpak_permission "io.github.hmlendea.geforcenow-electron" "background" false
    set_flatpak_permission "org.gnome.baobab" "background" false
    set_flatpak_permission "org.gnome.Calculator" "background" false
    set_flatpak_permission "org.gnome.Calendar" "background" false
    set_flatpak_permission "org.gnome.Contacts" "background" false
    set_flatpak_permission "org.gnome.eog" "background" false
    set_flatpak_permission "org.gnome.Evince" "background" false
    set_flatpak_permission "org.gnome.Maps" "background" false
    set_flatpak_permission "org.gnome.Rhythmbox3" "background" false
    set_flatpak_permission "org.gnome.Totem" "background" false
    set_flatpak_permission "org.gnome.Weather" "background" false
    set_flatpak_permission "org.inkscape.Inkscape" "background" false
    set_flatpak_permission "org.mozilla.firefox" "background" false
fi
