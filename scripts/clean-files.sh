#!/bin/bash
source "scripts/common/common.sh"

HOME_CACHE="${HOME}/.cache"
HOME_CONFIG="${HOME}/.config"
HOME_LOCAL_SHARE="${HOME}/.local/share"

function removeDirectoryForMissingBin() {
    local BINARY="${1}" && shift

    for DIRECTORY in "${@}"; do
        if (! does-bin-exist "${BINARY}") \
        && [ -d "${DIRECTORY}" ]; then
            remove "${DIRECTORY}"
        fi
    done
}

removeDirectoryForMissingBin "alsi" "${HOME_CONFIG}/alsi"
removeDirectoryForMissingBin "audacity" "${HOME}/.audacity-data"
removeDirectoryForMissingBin "autokey-shell" "${HOME_LOCAL_SHARE}/autokey"
removeDirectoryForMissingBin "avidemux" "${HOME}/.avidemux6"
removeDirectoryForMissingBin "brave" \
    "${HOME_CACHE}/BraveSoftware" \
    "${HOME_CONFIG}/BraveSoftware"
removeDirectoryForMissingBin "brz" "${HOME_CACHE}/breezy"
removeDirectoryForMissingBin "chromium" \
    "${HOME_CACHE}/chromium" \
    "${HOME_CONFIG}/chromium"
removeDirectoryForMissingBin "evolution" \
    "${HOME_CACHE}/evolution" \
    "${HOME_CONFIG}/evolution" \
    "${HOME_LOCAL_SHARE}/evolution"
removeDirectoryForMissingBin "gkraken" "${HOME_CONFIG}/gkraken"
removeDirectoryForMissingBin "gnome-photos" "${HOME_CACHE}/gnome-photos"
removeDirectoryForMissingBin "gnome-software" "${HOME_CACHE}/gnome-software"
removeDirectoryForMissingBin "gnubg" "${HOME}/.gnubg"
removeDirectoryForMissingBin "google-chrome" \
    "${HOME_CACHE}/google-chrome" \
    "${HOME_CONFIG}/google-chrome"
removeDirectoryForMissingBin "libreoffice" "${HOME_CONFIG}/libreoffice"
removeDirectoryForMissingBin "lollypop" "${HOME_LOCAL_SHARE}/lollypop"
removeDirectoryForMissingBin "notion-app" "${HOME_CONFIG}/Notion"
removeDirectoryForMissingBin "onlyoffice-desktopeditors" "${HOME_CONFIG}/onlyoffice"
removeDirectoryForMissingBin "pip" "${HOME_CACHE}/pip"
removeDirectoryForMissingBin "spotify" \
    "${HOME_CACHE}/spotify" \
    "${HOME_CONFIG}/spotify"
removeDirectoryForMissingBin "transmission-daemon" "${HOME_CONFIG}/transmission-daemon"
removeDirectoryForMissingBin "vlc" "${HOME_CONFIG}/vlc"
removeDirectoryForMissingBin "whatsapp-nativefier" "${HOME_CONFIG}/whatsapp-nativefier-d40211"
removeDirectoryForMissingBin "whatsdesk" "${HOME}/.whatsdesk"
removeDirectoryForMissingBin "wike" "${HOME_CACHE}/wike"
