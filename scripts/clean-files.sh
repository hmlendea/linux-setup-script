#!/bin/bash
source "scripts/common/common.sh"

function removeForMissingBin() {
    local BINARY="${1}" && shift

    for DIRECTORY in "${@}"; do
        if ! does-bin-exist "${BINARY}"; then
            remove "${DIRECTORY}"
        fi
    done
}

function removeForMissingGnomeShellExtension() {
    local EXTENSION="${1}" && shift

    for DIRECTORY in "${@}"; do
        if ! does-gnome-shell-extension-exist "${EXTENSION}"; then
            remove "${DIRECTORY}"
        fi
    done
}

removeForMissingBin "aircrack-ng" "${HOME}/.aircrack"
removeForMissingBin "alsi" "${HOME_CONFIG}/alsi"
removeForMissingBin "audacity" "${HOME}/.audacity-data"
removeForMissingBin "autokey-shell" \
    "${HOME_CONFIG}/autokey" \
    "${HOME_LOCAL_SHARE}/autokey"
removeForMissingBin "avidemux" "${HOME}/.avidemux6"
removeForMissingBin "bleachbit" \
    "${HOME_CACHE}/bleachbit" \
    "${HOME_CONFIG}/bleachbit"
removeForMissingBin "blesh" "${HOME}/.blerc"
removeForMissingBin "brave" \
    "${HOME_CACHE}/BraveSoftware" \
    "${HOME_CONFIG}/BraveSoftware"
removeForMissingBin "brz" "${HOME_CACHE}/breezy"
removeForMissingBin "cairo-dock" "${HOME_CONFIG}/cairo-dock"
removeForMissingBin "chiaki" \
    "${HOME_CONFIG}/Chiaki" \
    "${HOME_LOCAL_SHARE}/Chiaki"
removeForMissingBin "chromium" \
    "${HOME_CACHE}/chromium" \
    "${HOME_CONFIG}/chromium"
removeForMissingBin "code" \
    "${HOME_CONFIG}/Code" \
    "${HOME}/.vscode"
removeForMissingBin "code-oss" \
    "${HOME_CONFIG}/Code - OSS" \
    "${HOME_CONFIG}/code-oss" \
    "${HOME}/.vscode-oss"
removeForMissingBin "codium" "${HOME_CONFIG}/VSCodium"
(! does-bin-exist "code-oss") && (! does-bin-exist "codium") && remove "${HOME}/.vscode-oss"
removeForMissingBin "discord" "${HOME_CONFIG}/discord"
removeForMissingBin "dockx" "${HOME_LOCAL_SHARE}/dockbarx"
#removeForMissingBin "evolution" \
#    "${HOME_CACHE}/evolution" \
#    "${HOME_CONFIG}/evolution" \
#    "${HOME_LOCAL_SHARE}/evolution"
removeForMissingBin "etcher" "${HOME_CONFIG}/balena-etcher-electron"
removeForMissingBin "fltk-config" "${HOME}/.fltk"
removeForMissingBin "fma-config-tool" "${HOME_CONFIG}/filemanager-actions"
removeForMissingBin "/opt/geforcenow-electron/geforcenow-electron" "${HOME_CONFIG}/GeForce NOW"
removeForMissingBin "gkraken" "${HOME_CONFIG}/gkraken"
removeForMissingBin "gksu" "${HOME}/.gksu.lock"
removeForMissingBin "gnome-photos" \
    "${HOME_CACHE}/gnome-photos" \
    "${HOME_LOCAL_SHARE}/gnome-photos"
removeForMissingBin "gnome-software" "${HOME_CACHE}/gnome-software"
removeForMissingBin "gnome-sound-recorder" "${HOME_LOCAL_SHARE}/org.gnome.SoundRecorder"
removeForMissingBin "gnubg" "${HOME}/.gnubg"
removeForMissingBin "google-chrome" \
    "${HOME_CACHE}/google-chrome" \
    "${HOME_CONFIG}/google-chrome"
removeForMissingBin "gradle" "${HOME}.gradle"
removeForMissingBin "hardinfo" "${HOME_CONFIG}/hardinfo"
removeForMissingBin "hashcat" "${HOME_CONFIG}/hashcat"
removeForMissingBin "inkscape" "${HOME_CONFIG}/inkscape"
removeForMissingBin "java" "${HOME}/.java"
removeForMissingBin "kupfer" "${HOME_CONFIG}/kupfer"
removeForMissingBin "libreoffice" "${HOME_CONFIG}/libreoffice"
removeForMissingBin "lollypop" "${HOME_LOCAL_SHARE}/lollypop"
removeForMissingBin "lsd" "${HOME_CONFIG}/lsd"
removeForMissingBin "mcaselector" \
    "${HOME}/.mcaselector" \
    "${HOME_CACHE}/mcaselector"
removeForMissingBin "mcedit" "${HOME}/.mcedit"
removeForMissingBin "minetest" "${HOME_CACHE}/minetest"
removeForMissingBin "mono" "${HOME}/.mono"
removeForMissingBin "mpv" "${HOME_CONFIG}/mpv"
removeForMissingBin "neofetch" "${HOME_CONFIG}/neofetch"
removeForMissingBin "notion-app" "${HOME_CONFIG}/Notion"
removeForMissingBin "nvidia-settings" "${HOME}/.nvidia-settings-rc"
removeForMissingBin "onlyoffice-desktopeditors" \
    "${HOME_CONFIG}/onlyoffice" \
    "${HOME_LOCAL_SHARE}/onlyoffice"
removeForMissingBin "openshot-qt" "${HOME}/.openshot_qt"
removeForMissingBin "pavucontrol" "${HOME_CONFIG}/pavucontrol.ini"
removeForMissingBin "pcmanfm" "${HOME_CONFIG}/pcmanfm"
removeForMissingBin "pcmanfm-qt" "${HOME_CONFIG}/pcmanfm-qt"
removeForMissingBin "pip" "${HOME_CACHE}/pip"
removeForMissingBin "plexmediaplayer" "${HOME_CONFIG}/plex.tv"
removeForMissingBin "simplescreenrecorder" "${HOME}/.ssr"
removeForMissingBin "snapcraft" "${HOME_CACHE}/snapcraft"
removeForMissingBin "spotify" \
    "${HOME_CACHE}/spotify" \
    "${HOME_CONFIG}/spotify"
removeForMissingBin "teams" \
    "${HOME_CONFIG}/Microsoft Teams - Preview" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams"
removeForMissingBin "teams-insiders" \
    "${HOME_CONFIG}/Microsoft Teams - Insiders" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams - Insiders"
removeForMissingBin "teamviewer" \
    "${HOME_CONFIG}/teamviewer" \
    "${HOME_LOCAL_SHARE}/teamviewer15"
removeForMissingBin "thunar" "${HOME_CONFIG}/Thunar"
removeForMissingBin "transmission-daemon" "${HOME_CONFIG}/transmission-daemon"
removeForMissingBin "ulauncher" "${HOME_LOCAL_SHARE}/ulauncher"
removeForMissingBin "vim" \
    "${HOME}/.viminfo" \
    "${HOME}/.vimrc" \
    "${HOME_CACHE}/vim"
removeForMissingBin "vlc" \
    "${HOME_CACHE}/vlc" \
    "${HOME_CONFIG}/vlc"
removeForMissingBin "whatsapp-nativefier" "${HOME_CONFIG}/whatsapp-nativefier-d40211"
removeForMissingBin "whatsdesk" "${HOME}/.whatsdesk"
removeForMissingBin "wike" "${HOME_CACHE}/wike"
removeForMissingBin "wine" "${HOME_CACHE}/wine"
removeForMissingBin "winetricks" "${HOME_CACHE}/winetricks"
removeForMissingBin "yarn" \
    "${HOME}/.yarn" \
    "${HOME}/.yarnrc"
removeForMissingBin "yay" "${HOME_CACHE}/yay"
removeForMissingBin "youtube-dl" "${HOME_CACHE}/youtube-dl"
removeForMissingBin "zsh" "${HOME}/.zshrc"

removeForMissingGnomeShellExtension "tiling-assistant" "${HOME_CONFIG}/tiling-assistant"

# Unnecessary files
if [ -d "${HOME}/Downloads" ]; then
    while IFS='' read -r -d '' TORRENT_FILE; do
        remove "${TORRENT_FILE}"
    done < <(find "${HOME}/Downloads" -maxdepth 1 -type f -name "*.torrent" -print0)
fi

# Logs
remove "${HOME}/.config/logs"
remove "${HOME}/.minecraft/logs"
