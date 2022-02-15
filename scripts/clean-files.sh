#!/bin/bash
source "scripts/common/common.sh"

function removeDirectoryForMissingBin() {
    local BINARY="${1}" && shift

    for DIRECTORY in "${@}"; do
        if ! does-bin-exist "${BINARY}"; then
            remove "${DIRECTORY}"
        fi
    done
}

function removeDirectoryForMissingGnomeShellExtension() {
    local EXTENSION="${1}" && shift

    for DIRECTORY in "${@}"; do
        if ! does-gnome-shell-extension-exist "${EXTENSION}"; then
            remove "${DIRECTORY}"
        fi
    done
}

removeDirectoryForMissingBin "alsi" "${HOME_CONFIG}/alsi"
removeDirectoryForMissingBin "audacity" "${HOME}/.audacity-data"
removeDirectoryForMissingBin "autokey-shell" "${HOME_LOCAL_SHARE}/autokey"
removeDirectoryForMissingBin "avidemux" "${HOME}/.avidemux6"
removeDirectoryForMissingBin "bleachbit" "${HOME_CACHE}/bleachbit"
removeDirectoryForMissingBin "blesh" "${HOME}/.blerc"
removeDirectoryForMissingBin "brave" \
    "${HOME_CACHE}/BraveSoftware" \
    "${HOME_CONFIG}/BraveSoftware"
removeDirectoryForMissingBin "brz" "${HOME_CACHE}/breezy"
removeDirectoryForMissingBin "cairo-dock" "${HOME_CONFIG}/cairo-dock"
removeDirectoryForMissingBin "chromium" \
    "${HOME_CACHE}/chromium" \
    "${HOME_CONFIG}/chromium"
removeDirectoryForMissingBin "code" \
    "${HOME_CONFIG}/Code" \
    "${HOME}/.vscode"
removeDirectoryForMissingBin "code-oss" \
    "${HOME_CONFIG}/Code - OSS" \
    "${HOME_CONFIG}/code-oss" \
    "${HOME}/.vscode-oss"
removeDirectoryForMissingBin "codium" "${HOME_CONFIG}/VSCodium"
(! does-bin-exist "code-oss") && (! does-bin-exist "codium") && remove "${HOME}/.vscode-oss"
removeDirectoryForMissingBin "dockx" "${HOME_LOCAL_SHARE}/dockbarx"
#removeDirectoryForMissingBin "evolution" \
#    "${HOME_CACHE}/evolution" \
#    "${HOME_CONFIG}/evolution" \
#    "${HOME_LOCAL_SHARE}/evolution"
removeDirectoryForMissingBin "/opt/geforcenow-electron/geforcenow-electron" "${HOME_CONFIG}/GeForce NOW"
removeDirectoryForMissingBin "gkraken" "${HOME_CONFIG}/gkraken"
removeDirectoryForMissingBin "gksu" "${HOME}/.gksu.lock"
removeDirectoryForMissingBin "gnome-photos" "${HOME_CACHE}/gnome-photos"
removeDirectoryForMissingBin "gnome-software" "${HOME_CACHE}/gnome-software"
removeDirectoryForMissingBin "gnubg" "${HOME}/.gnubg"
removeDirectoryForMissingBin "google-chrome" \
    "${HOME_CACHE}/google-chrome" \
    "${HOME_CONFIG}/google-chrome"
removeDirectoryForMissingBin "kupfer" "${HOME_CONFIG}/kupfer"
removeDirectoryForMissingBin "libreoffice" "${HOME_CONFIG}/libreoffice"
removeDirectoryForMissingBin "lollypop" "${HOME_LOCAL_SHARE}/lollypop"
removeDirectoryForMissingBin "lsd" "${HOME_CONFIG}/lsd"
removeDirectoryForMissingBin "mcaselector" \
    "${HOME}/.mcaselector" \
    "${HOME_CACHE}/mcaselector"
removeDirectoryForMissingBin "mcedit" "${HOME}/.mcedit"
removeDirectoryForMissingBin "minetest" "${HOME_CACHE}/minetest"
removeDirectoryForMissingBin "notion-app" "${HOME_CONFIG}/Notion"
removeDirectoryForMissingBin "onlyoffice-desktopeditors" \
    "${HOME_CONFIG}/onlyoffice" \
    "${HOME_LOCAL_SHARE}/onlyoffice"
removeDirectoryForMissingBin "pavucontrol" "${HOME_CONFIG}/pavucontrol.ini"
removeDirectoryForMissingBin "pcmanfm" "${HOME_CONFIG}/pcmanfm"
removeDirectoryForMissingBin "pcmanfm-qt" "${HOME_CONFIG}/pcmanfm-qt"
removeDirectoryForMissingBin "pip" "${HOME_CACHE}/pip"
removeDirectoryForMissingBin "plexmediaplayer" "${HOME_CONFIG}/plex.tv"
removeDirectoryForMissingBin "spotify" \
    "${HOME_CACHE}/spotify" \
    "${HOME_CONFIG}/spotify"
removeDirectoryForMissingBin "thunar" "${HOME_CONFIG}/Thunar"
removeDirectoryForMissingBin "transmission-daemon" "${HOME_CONFIG}/transmission-daemon"
removeDirectoryForMissingBin "ulauncher" "${HOME_LOCAL_SHARE}/ulauncher"
removeDirectoryForMissingBin "vlc" \
    "${HOME_CACHE}/vlc" \
    "${HOME_CONFIG}/vlc"
removeDirectoryForMissingBin "whatsapp-nativefier" "${HOME_CONFIG}/whatsapp-nativefier-d40211"
removeDirectoryForMissingBin "whatsdesk" "${HOME}/.whatsdesk"
removeDirectoryForMissingBin "wike" "${HOME_CACHE}/wike"
removeDirectoryForMissingBin "yarn" \
    "${HOME}/.yarn" \
    "${HOME}/.yarnrc"
removeDirectoryForMissingBin "youtube-dl" "${HOME_CACHE}/youtube-dl"

removeDirectoryForMissingGnomeShellExtension "tiling-assistant" "${HOME_CONFIG}/tiling-assistant"
