#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"

! does_bin_exist "aircrack-ng" && remove "${HOME}/.aircrack"
! does_bin_exist "alsi" && remove "${HOME_CONFIG}/alsi"
! does_bin_exist "audacity" && remove "${HOME}/.audacity-data"
! does_bin_exist "autokey-shell" && remove \
    "${HOME_CONFIG}/autokey" \
    "${HOME_LOCAL_SHARE}/autokey"
! does_bin_exist "avidemux" && remove "${HOME}/.avidemux6"
! does_bin_exist "balena-etcher" "balena-etcher-electron" "etcher" && remove \
    "${HOME_CONFIG}/balena-etcher" \
    "${HOME_CONFIG}/balena-etcher-electron"
! does_bin_exist "bleachbit" && remove \
    "${HOME_CACHE}/bleachbit" \
    "${HOME_CONFIG}/bleachbit"
! does_bin_exist "blesh" && remove "${HOME}/.blerc"
! does_bin_exist "bna" && remove "${HOME_CONFIG}/bna"
! does_bin_exist "brave" && remove \
    "${HOME_CACHE}/BraveSoftware" \
    "${HOME_CONFIG}/BraveSoftware"
! does_bin_exist "brz" && remove "${HOME_CACHE}/breezy"
! does_bin_exist "cairo-dock" && remove "${HOME_CONFIG}/cairo-dock"
! does_bin_exist "chiaki" && remove \
    "${HOME_CONFIG}/Chiaki" \
    "${HOME_LOCAL_SHARE}/Chiaki"
! does_bin_exist "chromium" && remove \
    "${HOME_CACHE}/chromium" \
    "${HOME_CONFIG}/chromium"
! does_bin_exist "code" && remove \
    "${HOME_CONFIG}/Code" \
    "${HOME}/.vscode"
! does_bin_exist "code-oss" && remove \
    "${HOME_CONFIG}/Code - OSS" \
    "${HOME_CONFIG}/code-oss" \
    "${HOME}/.vscode-oss"
! does_bin_exist "codium" && remove "${HOME_CONFIG}/VSCodium"
! does_bin_exist "code-oss" "codium" && remove "${HOME}/.vscode-oss"
! does_bin_exist "discord" && remove "${HOME_CONFIG}/discord"
! does_bin_exist "dockx" && remove "${HOME_LOCAL_SHARE}/dockbarx"
! does_bin_exist "droidcam" && remove "${HOME_CONFIG}/droidcam"
! does_bin_exist "duolingo-desktop" && remove "${HOME_CONFIG}/Duolingo"
#! does_bin_exist "evolution" && remove \
#    "${HOME_CACHE}/evolution" \
#    "${HOME_CONFIG}/evolution" \
#    "${HOME_LOCAL_SHARE}/evolution"
! does_bin_exist "electronmail-bin" && remove "${HOME_CONFIG}/electron-mail"
! does_bin_exist "eog" && remove "${HOME_CONFIG}/eog"
! does_bin_exist "fastfetch" && remove \
    "${HOME_CACHE}/fastfetch" \
    "${HOME_CONFIG}/fastfetch"
! does_bin_exist "fltk-config" && remove "${HOME}/.fltk"
! does_bin_exist "fma-config-tool" && remove "${HOME_CONFIG}/filemanager-actions"
! does_bin_exist "fragments" && remove \
    "${HOME_CACHE}/fragments" \
    "${HOME_CONFIG}/fragments" \
    "${HOME_LOCAL_SHARE}/fragments"
! does_bin_exist "gedit" && \
    remove "${HOME_CONFIG}/gedit" \
    remove "${HOME_LOCAL_SHARE}/gedit"
! does_bin_exist "/opt/geforcenow-electron/geforcenow-electron" && remove "${HOME_CONFIG}/GeForce NOW"
! does_bin_exist "gkraken" && remove "${HOME_CONFIG}/gkraken"
! does_bin_exist "gksu" && remove "${HOME}/.gksu.lock"
! does_bin_exist "gnome-calculator" && remove "${HOME_CACHE}/gnome-calculator"
! does_bin_exist "gnome-photos" && remove \
    "${HOME_CACHE}/gnome-photos" \
    "${HOME_LOCAL_SHARE}/gnome-photos"
! does_bin_exist "gnome-software" && remove "${HOME_CACHE}/gnome-software"
! does_bin_exist "gnome-sound-recorder" && remove "${HOME_LOCAL_SHARE}/org.gnome.SoundRecorder"
! does_bin_exist "gnubg" && remove "${HOME}/.gnubg"
! does_bin_exist "google-chrome" && remove \
    "${HOME_CACHE}/google-chrome" \
    "${HOME_CONFIG}/google-chrome"
! does_bin_exist "google-chrome-beta" && remove \
    "${HOME_CACHE}/google-chrome-beta" \
    "${HOME_CONFIG}/google-chrome-beta"
! does_bin_exist "google-chrome-unstable" && remove \
    "${HOME_CACHE}/google-chrome-unstable" \
    "${HOME_CONFIG}/google-chrome-unstable"
! does_bin_exist "gradle" && remove "${HOME}.gradle"
! does_bin_exist "hardinfo" && remove "${HOME_CONFIG}/hardinfo"
! does_bin_exist "hashcat" && remove \
    "${HOME_CONFIG}/hashcat" \
    "${HOME_LOCAL_SHARE}/hashcat"
! does_bin_exist "inkscape" && remove \
    "${HOME_CACHE}/inkscape" \
    "${HOME_CONFIG}/inkscape"
! does_bin_exist "java" && remove "${HOME}/.java"
! does_bin_exist "kupfer" && remove "${HOME_CONFIG}/kupfer"
! does_bin_exist "libreoffice" && remove "${HOME_CONFIG}/libreoffice"
! does_bin_exist "lollypop" && remove "${HOME_LOCAL_SHARE}/lollypop"
! does_bin_exist "lsd" && remove "${HOME_CONFIG}/lsd"
! does_bin_exist "lutris" && remove \
    "${HOME_CACHE}/lutris" \
    "${HOME_CONFIG}/lutris" \
    "${HOME_LOCAL_SHARE}/lutris"
! does_bin_exist "mcaselector" && remove \
    "${HOME}/.mcaselector" \
    "${HOME_CACHE}/mcaselector"
! does_bin_exist "mcedit" && remove "${HOME}/.mcedit"
! does_bin_exist "microsoft-edge-beta" && remove \
    "${HOME_CACHE}/microsoft-edge-beta" \
    "${HOME_CACHE}/Microsoft/Edge" \
    "${HOME_CONFIG}/microsoft-edge-beta"
! does_bin_exist "microsoft-edge-dev" && remove \
    "${HOME_CACHE}/microsoft-edge-dev" \
    "${HOME_CACHE}/Microsoft/Edge" \
    "${HOME_CONFIG}/microsoft-edge-dev"
! does_bin_exist "minetest" && remove "${HOME_CACHE}/minetest"
! does_bin_exist "mono" && remove "${HOME}/.mono"
! does_bin_exist "mpv" && remove "${HOME_CONFIG}/mpv"
! does_bin_exist "neofetch" && remove "${HOME_CONFIG}/neofetch"
! does_bin_exist "notion-app" && remove "${HOME_CONFIG}/Notion"
! does_bin_exist "npm" && remove "${HOME}/.npm"
! does_bin_exist "nvidia-settings" && remove "${HOME}/.nvidia-settings-rc"
! does_bin_exist "onlyoffice-desktopeditors" && remove \
    "${HOME_CONFIG}/onlyoffice" \
    "${HOME_LOCAL_SHARE}/onlyoffice"
! does_bin_exist "openrgb" && remove "${HOME_CONFIG}/OpenRGB"
! does_bin_exist "openshot-qt" && remove "${HOME}/.openshot_qt"
! does_bin_exist "pavucontrol" && remove "${HOME_CONFIG}/pavucontrol.ini"
! does_bin_exist "pcmanfm" && remove "${HOME_CONFIG}/pcmanfm"
! does_bin_exist "pcmanfm-qt" && remove "${HOME_CONFIG}/pcmanfm-qt"
! does_bin_exist "pip" && remove "${HOME_CACHE}/pip"
! does_bin_exist "plank" && remove \
    "${HOME_CACHE}/plank" \
    "${HOME_CONFIG}/plank" \
    "${HOME_LOCAL_SHARE}/plank"
! does_bin_exist "plexmediaplayer" && remove \
    "${HOME_CACHE}/plex-media-player" \
    "${HOME_CONFIG}/plex.tv" \
    "${HOME_LOCAL_SHARE}/plexmediaplayer"
! does_bin_exist "postman" && \
    remove "${HOME}/Postman" \
    remove "${HOME_CONFIG}/Postman"
! does_bin_exist "rhythmbox" && remove \
    "${HOME_CACHE}/rhythmbox" \
    "${HOME_LOCAL_SHARE}/rhythmbox"
! does_bin_exist "signal-desktop" && remove "${HOME_CONFIG}/Signal"
! does_bin_exist "simplescreenrecorder" && remove "${HOME}/.ssr"
! does_bin_exist "simplenote" && remove "${HOME_CONFIG}/Simplenote"
! does_bin_exist "snap" && remove "${HOME}/.snap"
! does_bin_exist "snapcraft" && remove \
    "${HOME_CACHE}/snapcraft" \
    "${HOME_CONFIG}/snapcraft"
! does_bin_exist "sokogrump" && remove "${HOME_LOCAL_SHARE}/SokoGrump"
! does_bin_exist "spotify" && remove \
    "${HOME_CACHE}/spotify" \
    "${HOME_CONFIG}/spotify"
! does_bin_exist "teams" && remove \
    "${HOME_CONFIG}/Microsoft Teams - Preview" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams"
! does_bin_exist "teams-insiders" && remove \
    "${HOME_CONFIG}/Microsoft Teams - Insiders" \
    "${HOME_CONFIG}/Microsoft/Microsoft Teams - Insiders"
! does_bin_exist "teams" "teams-insiders" && remove "${HOME_CONFIG}/teams"
! does_bin_exist "teamviewer" && remove \
    "${HOME_CACHE}/TeamViewer" \
    "${HOME_CONFIG}/teamviewer" \
    "${HOME_LOCAL_SHARE}/teamviewer15"
! does_bin_exist "telegram-desktop" && remove "${HOME_LOCAL_SHARE}/TelegramDesktop"
! does_bin_exist "thunar" && remove "${HOME_CONFIG}/Thunar"
! does_bin_exist "totem" && remove \
    "${HOME_CACHE}/totem" \
    "${HOME_CONFIG}/totem" \
    "${HOME_LOCAL_SHARE}/totem"
! does_bin_exist "transmission-daemon" && remove "${HOME_CONFIG}/transmission-daemon"
! does_bin_exist "ulauncher" && remove "${HOME_LOCAL_SHARE}/ulauncher"
! does_bin_exist "virtualbox" && remove "${HOME_CONFIG}/VirtualBox"
! does_bin_exist "vim" && remove \
    "${HOME}/.viminfo" \
    "${HOME}/.vimrc" \
    "${HOME_CACHE}/vim"
! does_bin_exist "vlc" && remove \
    "${HOME_CACHE}/vlc" \
    "${HOME_CONFIG}/vlc" \
    "${HOME_LOCAL_SHARE}/vlc"
! does_bin_exist "whatsapp-nativefier" && remove "${HOME_CONFIG}/whatsapp-nativefier-d40211"
! does_bin_exist "whatsdesk" && remove "${HOME}/.whatsdesk"
! does_bin_exist "wike" && remove "${HOME_CACHE}/wike"
! does_bin_exist "wine" && remove "${HOME_CACHE}/wine"
! does_bin_exist "winetricks" && remove "${HOME_CACHE}/winetricks"
! does_bin_exist "yarn" && remove \
    "${HOME}/.yarn" \
    "${HOME}/.yarnrc"
! does_bin_exist "yay" && remove \
    "${HOME_CACHE}/yay" \
    "${HOME_CONFIG}/yay"
! does_bin_exist "youtube-dl" && remove "${HOME_CACHE}/youtube-dl"
! does_bin_exist "zsh" && remove "${HOME}/.zshrc"

# GNOME Extensions
! is_gnome_shell_extension_installed "tiling-assistant" && remove "${HOME_CONFIG}/tiling-assistant"

# Steam games / apps

! is_steam_app_installed "8930" && remove \
    "${HOME_LOCAL_SHARE}/Aspyr/Sid Meier's Civilization 5" \
    "${HOME_LOCAL_SHARE}/Aspyr/com.aspyr.civ5xp.json"
! is_steam_app_installed "20920" && remove "${HOME_LOCAL_SHARE}/cdprojektred/witcher2"
! is_steam_app_installed "38700" && remove "${HOME_LOCAL_SHARE}/twotribes/toki_tori"
! is_steam_app_installed "105600" && remove "${HOME_LOCAL_SHARE}/Terraria"
! is_steam_app_installed "200510" && remove "${HOME_LOCAL_SHARE}/feral-interactive/XCOM"
! is_steam_app_installed "203160" && remove "${HOME_LOCAL_SHARE}/feral-interactive/Tomb Raider"
! is_steam_app_installed "200710" && remove "${HOME_LOCAL_SHARE}/Runic Games/Torchlight 2"
! is_steam_app_installed "215510" && remove "${HOME_LOCAL_SHARE}/rocketbirds"
! is_steam_app_installed "219150" && remove "${HOME_LOCAL_SHARE}/HotlineMiami"
! is_steam_app_installed "246110" && remove "${HOME_LOCAL_SHARE}/doublefine/massivechalice"
! is_steam_app_installed "250820" && remove \
    "${HOME}/steamvr" \
    "${HOME_CONFIG}/openvr" \
    "${HOME_CONFIG}/openxr" \
    "${HOME_CONFIG}/Valve/vrmonitor.conf"
! is_steam_app_installed "251910" && remove "${HOME_LOCAL_SHARE}/Firebrand Games/Solar Flux"
! is_steam_app_installed "252950" && remove "${HOME_LOCAL_SHARE}/Rocket League"
! is_steam_app_installed "255300" && remove "${HOME_LOCAL_SHARE}/Daedalic Entertainment/Journey of a Roach"
! is_steam_app_installed "284710" && remove "${HOME_CACHE}/ArtifexMundi/Abyss_TheWraithsOfEden"
! is_steam_app_installed "313340" && remove "${HOME_CONFIG}/unity3d/David\ OReilly/Mountain"
! is_steam_app_installed "319270" && remove "${HOME_LOCAL_SHARE}/great-permutator"
! is_steam_app_installed "322330" && remove \
    "${HOME}/.klei/DoNotStarveTogether" \
    "${HOME}/.klei/DoNotStarveTogetherBetaBranch"
! is_steam_app_installed "370360" && remove \
    "${HOME_CONFIG}/unity3d/Zachtronics/TIS-100" \
    "${HOME_LOCAL_SHARE}/TIS-100"
! is_steam_app_installed "385710" && remove "${HOME_CONFIG}/INK"
! is_steam_app_installed "434210" && remove "${HOME_CONFIG}/unity3d/BabaYaga/It's Spring Again"
! is_steam_app_installed "464920" && remove "${HOME_LOCAL_SHARE}/Surviving Mas"
! is_steam_app_installed "476240" && remove "${HOME_CONFIG}/unity3d/Arzola's/KNIGHTS"
! is_steam_app_installed "490230" && remove "${HOME_CONFIG}/SWARMRIDERS"
! is_steam_app_installed "517910" && remove "${HOME_LOCAL_SHARE}/ags/Sisyphus Reborn"
! is_steam_app_installed "729040" && remove "${HOME_LOCAL_SHARE}/Steam/steamapps/common/BorderlandsGOTYEnhanced"
! is_steam_app_installed "736260" && remove "${HOME_LOCAL_SHARE}/Baba_Is_You"

for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
    if is_steam_app_installed "8930"; then
        remove "${STEAM_LIBRARY_PATH}/common/Sid Meier's Civilization V/steamassets/"*.mov
        remove "${STEAM_LIBRARY_PATH}/common/Sid Meier's Civilization V/steamassets/assets/dlc/"*/*.mov
    fi

    ! is_steam_app_installed "41070" && remove "${STEAM_LIBRARY_PATH}/common/Serious Sam 3"
    ! is_steam_app_installed "50300" && remove "${STEAM_LIBRARY_PATH}/common/SpecOps_TheLine"
    ! is_steam_app_installed "70000" && remove "${STEAM_LIBRARY_PATH}/common/Dino D-Day"
    ! is_steam_app_installed "91310" && remove "${STEAM_LIBRARY_PATH}/common/Dead Island"
    ! is_steam_app_installed "99910" && remove "${STEAM_LIBRARY_PATH}/common/Puzzle Pirates"
    ! is_steam_app_installed "206690" && remove "${STEAM_LIBRARY_PATH}/common/ibomber defense pacific"
    ! is_steam_app_installed "219150" && remove "${STEAM_LIBRARY_PATH}/common/hotline_miami"
    ! is_steam_app_installed "221380" && remove "${STEAM_LIBRARY_PATH}/common/Age2HD"
    ! is_steam_app_installed "234390" && remove "${STEAM_LIBRARY_PATH}/common/TeleglitchDME"
    ! is_steam_app_installed "250820" && remove "${STEAM_LIBRARY_PATH}/common/SteamVR"
    ! is_steam_app_installed "266840" && remove "${STEAM_LIBRARY_PATH}/common/Age of Mythology"
    ! is_steam_app_installed "271570" && remove "${STEAM_LIBRARY_PATH}/common/SpaceFarmers"
    ! is_steam_app_installed "304050" && remove "${STEAM_LIBRARY_PATH}/common/Trove"
    ! is_steam_app_installed "304930" && remove "${STEAM_LIBRARY_PATH}/common/Unturned"
    ! is_steam_app_installed "312900" && remove "${STEAM_LIBRARY_PATH}/common/Zoo Rampage"
    ! is_steam_app_installed "328080" && remove "${STEAM_LIBRARY_PATH}/common/Rise to Ruins"
    ! is_steam_app_installed "346010" && remove "${STEAM_LIBRARY_PATH}/common/Besiege"
    ! is_steam_app_installed "356040" && remove "${STEAM_LIBRARY_PATH}/common/Sheltered"
    ! is_steam_app_installed "552110" && remove "${STEAM_LIBRARY_PATH}/common/Puzzle Pirates Dark Seas"
done

# Unwanted files in the Downloads dir, by extension
if [ -d "${HOME_DOWNLOADS}" ]; then
    while IFS='' read -r -d '' UNWANTED_FILE; do
        remove "${UNWANTED_FILE}"
    done < <(find "${HOME_DOWNLOADS}" -maxdepth 1 -type f -iregex ".*\.\(ica\|torrent\)$" -print0)
fi

# Unwanted application launchers
remove "${HOME_LOCAL_SHARE}/applications/wine"
remove "${HOME_CONFIG}/menus/applications-merged/user-chrome-apps.menu"

if ls "${HOME_LOCAL_SHARE}/applications" | grep -q "*\.desktop$"; then
    for STEAM_APP_LAUNCHER in $(grep "^Exec=steam" "${HOME_LOCAL_SHARE}/applications"/*.desktop | awk -F":" '{print $1}' | sed 's/ /@SPACE@/g'); do
        STEAM_APP_LAUNCHER=$(echo "${STEAM_APP_LAUNCHER}" | sed 's/@SPACE@/ /g')
        remove "${STEAM_APP_LAUNCHER}"
    done
fi

# Empty directories
remove_dir_if_empty "${HOME}/.w3m"
remove_dir_if_empty "${HOME_CACHE}/ArtifexMundi"
remove_dir_if_empty "${HOME_CACHE}/Microsoft"
remove_dir_if_empty "${HOME_CONFIG}/ibus"
remove_dir_if_empty "${HOME_CONFIG}/Microsoft"
remove_dir_if_empty "${HOME_CONFIG}/paradox-launcher-v2"
remove_dir_if_empty "${HOME_CONFIG}/procps"
remove_dir_if_empty "${HOME_CONFIG}/unity3d"
remove_dir_if_empty "${HOME_CONFIG}/Valve"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/ags"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/Aspyr"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/cdprojektred"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/Daedalic\ Entertainment"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/doublefine"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/feral-interactive"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/Firebrand\ Games"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/gegl-0.4"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/pixmaps"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/Runic\ Games"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/twotribes"
remove_dir_if_empty "${HOME_LOCAL_SHARE}/xorg"

# Backups
remove "${HOME_CONFIG}/monitors.xml~"

# Logs
remove \
    "${HOME}/.mozilla/firefox/Crash Reports" \
    "${HOME_VAR}/app/org.mozilla.firefox/.mozilla/firefox/Crash Reports"
remove "${HOME_CONFIG}/logs"
remove "${HOME_LOCAL_SHARE}/xorg/"*".log"
remove "${HOME_LOCAL_SHARE}/xorg/"*".log.old"
remove \
    "${HOME}/.klei/DoNotStarveTogether/backup/client_chat_log" \
    "${HOME}/.klei/DoNotStarveTogether/backup/client_log"

for DIR in "${HOME}/.factorio" \
            "${HOME}/.ICAClient" \
            "${HOME}/.klei/DoNotStarveTogether" \
            "${HOME}/.minecraft" \
            "${HOME}/.npm" \
            "${HOME_CONFIG}/Code" \
            "${HOME_LOCAL_SHARE}/gvfs-metadata" \
            "${HOME_LOCAL_SHARE}/Paradox Interactive"/* \
            "${HOME_LOCAL_SHARE}/Steam" \
            "${HOME_LOCAL_SHARE}/Steam/steamapps/common"/* \
            "${HOME_LOCAL_SHARE}/Steam/steamapps/common"/*/*_Data \
            "${HOME_LOCAL_SHARE}/Steam/steamapps/compatdata/"*"/pfx/drive_c/users/steamuser/Temp" \
            "${HOME_LOCAL_SHARE}/Steam/steamapps/compatdata/"*"/pfx/drive_c/windows" \
            "${HOME_VAR}/app/"*"/data/gvfs-metadata"/*.log \
            "${HOME_VAR}/app/com.bitwarden.desktop/config/Bitwarden" \
            "${HOME_VAR}/app/com.getpostman.Postman/config/Postman" \
            "${HOME_VAR}/app/com.github.vladimiry.ElectronMail/config/electron-mail" \
            "${HOME_VAR}/app/com.microsoft.Teams/config/teams" \
            "${HOME_VAR}/app/com.microsoft.Teams/config/Microsoft/Microsoft Teams" \
            "${HOME_VAR}/app/com.mojang.Minecraft/.minecraft" \
            "${HOME_VAR}/app/com.simplenote.Simplenote/config" \
            "${HOME_VAR}/app/org.signal.Signal/config/Signal" \
            "${HOME_VAR}/app/org.telegram.desktop/data/TelegramDesktop"; do
    [ -d "${DIR}" ] && remove \
        "${DIR}/logs" \
        "${DIR}/_logs" \
        "${DIR}"/*-log.txt \
        "${DIR}"/*_log.txt \
        "${DIR}"/*-log-*.txt \
        "${DIR}"/*_log_*.txt \
        "${DIR}"/*-logs-*.txt \
        "${DIR}"/*_logs_*.txt \
        "${DIR}"/*.log \
        "${DIR}"/changelog.txt \
        "${DIR}"/log.txt \
        "${DIR}"/logs.txt \
        "${DIR}"/logfile.txt
done

does_bin_exist "journalctl" && run_as_su journalctl --vacuum-time=3days
