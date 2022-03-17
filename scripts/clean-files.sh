#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"

! does-bin-exist "aircrack-ng" && remove "${HOME}/.aircrack"
! does-bin-exist "alsi" && remove "${HOME_CONFIG}/alsi"
! does-bin-exist "audacity" && remove "${HOME}/.audacity-data"
! does-bin-exist "autokey-shell" && remove \
    "${HOME_CONFIG}/autokey" \
    "${HOME_LOCAL_SHARE}/autokey"
! does-bin-exist "avidemux" && remove "${HOME}/.avidemux6"
! does-bin-exist "bleachbit" && remove \
    "${HOME_CACHE}/bleachbit" \
    "${HOME_CONFIG}/bleachbit"
! does-bin-exist "blesh" && remove "${HOME}/.blerc"
! does-bin-exist "brave" && remove \
    "${HOME_CACHE}/BraveSoftware" \
    "${HOME_CONFIG}/BraveSoftware"
! does-bin-exist "brz" && remove "${HOME_CACHE}/breezy"
! does-bin-exist "cairo-dock" && remove "${HOME_CONFIG}/cairo-dock"
! does-bin-exist "chiaki" && remove \
    "${HOME_CONFIG}/Chiaki" \
    "${HOME_LOCAL_SHARE}/Chiaki"
! does-bin-exist "chromium" && remove \
    "${HOME_CACHE}/chromium" \
    "${HOME_CONFIG}/chromium"
! does-bin-exist "code" && remove \
    "${HOME_CONFIG}/Code" \
    "${HOME}/.vscode"
! does-bin-exist "code-oss" && remove \
    "${HOME_CONFIG}/Code - OSS" \
    "${HOME_CONFIG}/code-oss" \
    "${HOME}/.vscode-oss"
! does-bin-exist "codium" && remove "${HOME_CONFIG}/VSCodium"
! does-bin-exist "code-oss" "codium" && remove "${HOME}/.vscode-oss"
! does-bin-exist "discord" && remove "${HOME_CONFIG}/discord"
! does-bin-exist "dockx" && remove "${HOME_LOCAL_SHARE}/dockbarx"
#! does-bin-exist "evolution" && remove \
#    "${HOME_CACHE}/evolution" \
#    "${HOME_CONFIG}/evolution" \
#    "${HOME_LOCAL_SHARE}/evolution"
! does-bin-exist "electronmail-bin" && remove "${HOME_CONFIG}/electron-mail"
! does-bin-exist "etcher" && remove "${HOME_CONFIG}/balena-etcher-electron"
! does-bin-exist "fltk-config" && remove "${HOME}/.fltk"
! does-bin-exist "fma-config-tool" && remove "${HOME_CONFIG}/filemanager-actions"
! does-bin-exist "fragments" && remove "${HOME_LOCAL_SHARE}/fragments"
! does-bin-exist "/opt/geforcenow-electron/geforcenow-electron" && remove "${HOME_CONFIG}/GeForce NOW"
! does-bin-exist "gkraken" && remove "${HOME_CONFIG}/gkraken"
! does-bin-exist "gksu" && remove "${HOME}/.gksu.lock"
! does-bin-exist "gnome-photos" && remove \
    "${HOME_CACHE}/gnome-photos" \
    "${HOME_LOCAL_SHARE}/gnome-photos"
! does-bin-exist "gnome-software" && remove "${HOME_CACHE}/gnome-software"
! does-bin-exist "gnome-sound-recorder" && remove "${HOME_LOCAL_SHARE}/org.gnome.SoundRecorder"
! does-bin-exist "gnubg" && remove "${HOME}/.gnubg"
! does-bin-exist "google-chrome" && remove \
    "${HOME_CACHE}/google-chrome" \
    "${HOME_CONFIG}/google-chrome"
! does-bin-exist "gradle" && remove "${HOME}.gradle"
! does-bin-exist "hardinfo" && remove "${HOME_CONFIG}/hardinfo"
! does-bin-exist "hashcat" && remove "${HOME_CONFIG}/hashcat"
! does-bin-exist "inkscape" && remove \
    "${HOME_CACHE}/inkscape" \
    "${HOME_CONFIG}/inkscape"
! does-bin-exist "java" && remove "${HOME}/.java"
! does-bin-exist "kupfer" && remove "${HOME_CONFIG}/kupfer"
! does-bin-exist "libreoffice" && remove "${HOME_CONFIG}/libreoffice"
! does-bin-exist "lollypop" && remove "${HOME_LOCAL_SHARE}/lollypop"
! does-bin-exist "lsd" && remove "${HOME_CONFIG}/lsd"
! does-bin-exist "lutris" && remove \
    "${HOME_CONFIG}/lutris" \
    "${HOME_LOCAL_SHARE}/lutris"
! does-bin-exist "mcaselector" && remove \
    "${HOME}/.mcaselector" \
    "${HOME_CACHE}/mcaselector"
! does-bin-exist "mcedit" && remove "${HOME}/.mcedit"
! does-bin-exist "minetest" && remove "${HOME_CACHE}/minetest"
! does-bin-exist "mono" && remove "${HOME}/.mono"
! does-bin-exist "mpv" && remove "${HOME_CONFIG}/mpv"
! does-bin-exist "neofetch" && remove "${HOME_CONFIG}/neofetch"
! does-bin-exist "notion-app" && remove "${HOME_CONFIG}/Notion"
! does-bin-exist "nvidia-settings" && remove "${HOME}/.nvidia-settings-rc"
! does-bin-exist "onlyoffice-desktopeditors" && remove \
    "${HOME_CONFIG}/onlyoffice" \
    "${HOME_LOCAL_SHARE}/onlyoffice"
! does-bin-exist "openshot-qt" && remove "${HOME}/.openshot_qt"
! does-bin-exist "pavucontrol" && remove "${HOME_CONFIG}/pavucontrol.ini"
! does-bin-exist "pcmanfm" && remove "${HOME_CONFIG}/pcmanfm"
! does-bin-exist "pcmanfm-qt" && remove "${HOME_CONFIG}/pcmanfm-qt"
! does-bin-exist "pip" && remove "${HOME_CACHE}/pip"
! does-bin-exist "plexmediaplayer" && remove "${HOME_CONFIG}/plex.tv"
! does-bin-exist "postman" && remove "${HOME_CONFIG}/Postman"
! does-bin-exist "rhythmbox" && remove \
    "${HOME_CACHE}/rhythmbox" \
    "${HOME_LOCAL_SHARE}/rhythmbox"
! does-bin-exist "simplescreenrecorder" && remove "${HOME}/.ssr"
! does-bin-exist "snapcraft" && remove "${HOME_CACHE}/snapcraft"
! does-bin-exist "spotify" && remove \
    "${HOME_CACHE}/spotify" \
    "${HOME_CONFIG}/spotify"
! does-bin-exist "teams" && remove \
    "${HOME_CONFIG}/Microsoft Teams - Preview" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams"
! does-bin-exist "teams-insiders" && remove \
    "${HOME_CONFIG}/Microsoft Teams - Insiders" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams - Insiders"
! does-bin-exist "teamviewer" && remove \
    "${HOME_CONFIG}/teamviewer" \
    "${HOME_LOCAL_SHARE}/teamviewer15"
! does-bin-exist "telegram-desktop" && remove "${HOME_LOCAL_SHARE}/TelegramDesktop"
! does-bin-exist "thunar" && remove "${HOME_CONFIG}/Thunar"
! does-bin-exist "totem" && remove \
    "${HOME_CACHE}/totem" \
    "${HOME_CONFIG}/totem" \
    "${HOME_LOCAL_SHARE}/totem"
! does-bin-exist "transmission-daemon" && remove "${HOME_CONFIG}/transmission-daemon"
! does-bin-exist "ulauncher" && remove "${HOME_LOCAL_SHARE}/ulauncher"
! does-bin-exist "vim" && remove \
    "${HOME}/.viminfo" \
    "${HOME}/.vimrc" \
    "${HOME_CACHE}/vim"
! does-bin-exist "vlc" && remove \
    "${HOME_CACHE}/vlc" \
    "${HOME_CONFIG}/vlc"
! does-bin-exist "whatsapp-nativefier" && remove "${HOME_CONFIG}/whatsapp-nativefier-d40211"
! does-bin-exist "whatsdesk" && remove "${HOME}/.whatsdesk"
! does-bin-exist "wike" && remove "${HOME_CACHE}/wike"
! does-bin-exist "wine" && remove "${HOME_CACHE}/wine"
! does-bin-exist "winetricks" && remove "${HOME_CACHE}/winetricks"
! does-bin-exist "yarn" && remove \
    "${HOME}/.yarn" \
    "${HOME}/.yarnrc"
! does-bin-exist "yay" && remove \
    "${HOME_CACHE}/yay" \
    "${HOME_CONFIG}/yay"
! does-bin-exist "youtube-dl" && remove "${HOME_CACHE}/youtube-dl"
! does-bin-exist "zsh" && remove "${HOME}/.zshrc"

# GNOME Extensions
! is_gnome_shell_extension_installed "tiling-assistant" && remove "${HOME_CONFIG}/tiling-assistant"

# Steam apps
! is_steam_app_installed "105600" && remove "${HOME_LOCAL_SHARE}/Terraria"
! is_steam_app_installed "322330" && remove \
    "${HOME}/.klei/DoNotStarveTogether" \
    "${HOME}/.klei/DoNotStarveTogetherBetaBranch"
! is_steam_app_installed "476240" && remove "${HOME_CONFIG}/unity3d/Arzola's/KNIGHTS"
! is_steam_app_installed "729040" && remove "${HOME_LOCAL_SHARE}/Steam/steamapps/common/BorderlandsGOTYEnhanced"
! is_steam_app_installed "736260" && remove "${HOME_LOCAL_SHARE}/Baba_Is_You"

# Unnecessary files
if [ -d "${HOME}/Downloads" ]; then
    while IFS='' read -r -d '' TORRENT_FILE; do
        remove "${TORRENT_FILE}"
    done < <(find "${HOME}/Downloads" -maxdepth 1 -type f -name "*.torrent" -print0)
fi

# Logs
remove "${HOME}/.config/logs"
remove "${HOME}/.minecraft/logs"
remove "${HOME_LOCAL_SHARE}/xorg/Xorg.0.log"
remove "${HOME_LOCAL_SHARE}/xorg/Xorg.0.log.old"

# Unwanted application launchers
remove "${HOME_REAL}/.local/share/applications/wine"
remove "${HOME_REAL}/.config/menus/applications-merged/user-chrome-apps.menu"
