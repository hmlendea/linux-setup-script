#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"

CLEAN_LOGS=true
CLEAN_BROWSER_LOGS=false

SYSTEM_FONTS_DIR="${ROOT_USR_SHARE}/fonts"

function remove_locales_from_directories() {
    for DIRECTORY in "${@}"; do
        remove_locales_from_directory "${DIRECTORY}"
    done
}

function remove_locales_from_directory() {
    local DIRECTORY="${1%/}"

    [ ! -d "${DIRECTORY}" ] && return

    local FILE_NAME_STEP1="${DIRECTORY}"
    local FILE_NAME_STEP2="${FILE_NAME_STEP1}"
    local FILE_NAME_STEP3="${FILE_NAME_STEP1}"
    local FILE_NAME_STEP4="${FILE_NAME_STEP1}"

    for LANGUAGE_CODE in \
        "aa" "ab" "ace" "ach" "af" "agr" "ain" "ak" "am" "an" "ang" "anp" "ar" "as" "ast" "ay" "ayc" "az" \
        "ba" "bal" "bar" "be" "bem" "ber" "bg" "bhb" "bho" "bi" "bn" "bo" "br" "brx" "bs" "by" "byn" \
        "ca" "ce" "ch" "chr" "ckb" "cmn" "crh" "cs" "csb" "cv" "cy" "da" "de" "doi" "dsb" "dv" "dz" \
        "ee" "eo" "el" "es" "et" "eu" "fa" "ff" "fi" "fil" "fo" "fr" "frp" "fur" "fy" "ga" "gbm" "gd" "gez" "gl" "gn" "gr" "gu" "gv" \
        "ha" "haw" "hak" "he" "hi" "hif" "hne" "hr" "hsb" "ht" "hu" "hy" "ia" "id" "ie" "ig" "ik" "ilo" "io" "is" "it" "iu" "ja" "jam" "jp" \
        "ka" "kab" "kg" "ki" "kk" "kl" "km" "kmr" "kn" "ko" "kok" "ks" "ku" "kv" "kw" "ky" \
        "la" "lb" "lg" "li" "lij" "ln" "lo" "lt" "lv" "lzh" "mag" "mai" "mfe" "mg" "mhr" "mi" "miq" "mjw" "mk" "ml" "mn" "mni" "mnw" "mo" "mr" "ms" "mt" "my" \
        "na" "nah" "nan" "nb"  "nds" "ne" "nhn" "niu" "nl" "nn" "no" "nr" "nso" "nv" "oc" "om" "or" "os" "pa" "pap" "pi" "pl" "ps" "pt" "quz" "raj" "rif" "ru" "rw" \
        "sa" "sah" "sat" "sc" "sd" "se" "sgs" "shn" "shs" "si" "sid" "sk" "sl" "sm" "so" "son" "sq" "sr" "ss" "ssy" "st" "su" "sv" "sw" "syr" "szl" \
        "ta" "tatar-cyr" "tcy" "te" "tg" "th" "the" "ti" "tig" "tk" "tl" "tn" "to" "tok" "tpi" "tr" "ts" "tt" "tzm" "ug" "uk" "unm" "ur" "uz" "ve" "vi" \
        "wa" "wa" "wae" "wal" "wo" "xh" "yi" "yo" "yue" "yuw" "zgh" "zh" "zu"; do

        FILE_NAME_STEP2="${FILE_NAME_STEP1}/${LANGUAGE_CODE}"

        remove "${FILE_NAME_STEP2}"
        ! does_any_file_or_dir_exist "${FILE_NAME_STEP2}"* ] && continue

        for COUNTRY_CODE in \
            "" "AD" "AE" "AF" "AL" "AM" "AR" "AT" "AQ" "AW" "AZ" "BA" "BD" "BE" "BG" "BH" "BO" "BR" "BT" "BY" "CA" "CD" "CH" "CL" "CN" "CO" "CR" "CU" "CW" "CY" "CZ" \
            "DE" "DJ" "DO" "DK" "DZ" "EC" "EG" "EE" "ER" "ES" "ET" "FI" "FJ" "FO" "FR" "GB" "GE" "GH" "GL" "GR" "GT" \
            "Hans" "Hant" "HK" "HN" "HR" "HT" "HU" "IE" "ID" "IL" "IN" "IQ" "IR" "IS" "IT" "JO" "JP" "KE" "KG" "KH" "KK" "KR" "KW" "KZ" "LA" "LB" "LI" "LK" "LT" "LU" "LV" "LY" \
            "MA" "ME" "MG" "MK" "MM" "MN" "MT" "MU" "MV" "MX" "MY" "NG" "NI" "NL" "NO" "NP" "NU" "NZ" "OM" "PA" "PE" "PG" "PH" "PK" "PL" "PR" "PT" "PY" "QA" "RS" "RU" "RW" \
            "SA" "SD" "SE" "SG" "SI" "SK" "SN" "SO" "SS" "SV" "SY" "TH" "TM" "TJ" "TN" "TO" "TR" "TW" "TZ" "UA" "UG" "US" "UY" "UZ" "VE" "VN" "VU" "WS" "YE" "ZA" "ZM"; do

            for COUNTRY_CODE_SEPARATOR in "-" "_"; do
                if [ -z "${COUNTRY_CODE}" ]; then
                    FILE_NAME_STEP3="${FILE_NAME_STEP2}"
                else
                    FILE_NAME_STEP3="${FILE_NAME_STEP2}${COUNTRY_CODE_SEPARATOR}${COUNTRY_CODE}"
                fi
    
                remove "${FILE_NAME_STEP3}"
                ! does_any_file_or_dir_exist "${FILE_NAME_STEP3}"* ] && continue
    
                for KEYBOARD_LAYOUT in "" "big5" "big5hkscs" "gb18030" "gbk" "iso-8859-2" "ISO8859-1" "JIS" "SJIS" "tcvn" "us-ascii" "UTF-8" "viscii"; do
                    if [ -z "${KEYBOARD_LAYOUT}" ]; then
                        FILE_NAME_STEP4="${FILE_NAME_STEP3}"
                    else
                        FILE_NAME_STEP4="${FILE_NAME_STEP3}.${KEYBOARD_LAYOUT}"
                    fi
    
                    remove "${FILE_NAME_STEP4}"
                    ! does_any_file_or_dir_exist "${FILE_NAME_STEP4}"* ] && continue
                    
                    for VARIANT in "abegede" "cyrillic" "Cyrillic" "devanagari" "euro" "Euro" "hebrew" "ije" "iqtelif" "latin" "Latn" "valencia"; do
                        remove "${FILE_NAME_STEP4}@${VARIANT}"
                    done
                done
            done
        done
    done
}

remove "${LOCAL_INSTALL_TEMP_DIR}"

remove "${SYSTEM_FONTS_DIR}/TTF/seguiemj.ttf"
remove "${ROOT_ETC}/motd"
remove "${ROOT_USR_SHARE}/licenses"

remove_old_items "${XDG_CACHE_HOME}/electron"
remove_old_items "${XDG_CACHE_HOME}/nuget/packages"

remove \
    "${HOME}/.electron-gyp" \
    "${XDG_CACHE_HOME}/electron-builder"

remove \
    "${ROOT_VAR_LIB_FLATPAK}/.removed"

#remove_locales_from_directories \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Containers/tasks/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/DotnetTools/dotnet-format/"*"/tools/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/DotnetTools/dotnet-watch/"*"/tools/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Sdks/"*"/tools/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Sdks/Microsoft.Build.Tasks.Git/tools/core" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Sdks/Microsoft.NET.Sdk/analyzers" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Sdks/Microsoft.NET.Sdk/codestyle/"*"/" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Extensions" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/FSharp" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Roslyn" \
#    "${ROOT_USR_SHARE}/dotnet/sdk/"*"/Roslyn/bincore" \
#    "${ROOT_USR_SHARE}/dotnet/packs/Microsoft.NETCore.App.Ref/"*"/analyzers/dotnet/cs" \
#    "${ROOT_USR_SHARE}/help" \
#    "${ROOT_USR_SHARE}/i18n/locales" \
#    "${ROOT_USR_SHARE}/locale" \
#    "${ROOT_USR_SHARE}/man" \
#    "${ROOT_USR_SHARE}/X11/locale"

remove \
    "${ROOT_ROOT}/Desktop" \
    "${ROOT_ROOT}/Documents" \
    "${ROOT_ROOT}/Downloads" \
    "${ROOT_ROOT}/Music" \
    "${ROOT_ROOT}/Pictures" \
    "${ROOT_ROOT}/Public" \
    "${ROOT_ROOT}/Templates" \
    "${ROOT_ROOT}/Videos" \
    "${ROOT_ROOT}/.cache"

! does_bin_exist "aircrack-ng" && remove "${HOME}/.aircrack"
! does_bin_exist "alsi" && remove "${XDG_CONFIG_HOME}/alsi"
! does_bin_exist "asciinema" && remove "${XDG_CONFIG_HOME}/asciinema"
! does_bin_exist "audacity" && remove \
    "${HOME}/.audacity-data" \
    "${XDG_CONFIG_HOME}/audacity" \
    "${XDG_DATA_HOME}/audacity"
! does_bin_exist "autokey-shell" && remove \
    "${XDG_CONFIG_HOME}/autokey" \
    "${XDG_DATA_HOME}/autokey"
! does_bin_exist "avidemux" && remove "${HOME}/.avidemux6"
! does_bin_exist 'balena-etcher' 'balena-etcher-electron' 'etcher' && remove \
    "${XDG_CONFIG_HOME}/balena-etcher" \
    "${XDG_CONFIG_HOME}/balenaEtcher" \
    "${XDG_CONFIG_HOME}/balena-etcher-electron"
! does_bin_exist "bleachbit" && remove \
    "${XDG_CACHE_HOME}/bleachbit" \
    "${XDG_CONFIG_HOME}/bleachbit"
! does_bin_exist "blesh" && remove "${HOME}/.blerc"
! does_bin_exist "bna" && remove "${XDG_CONFIG_HOME}/bna"
! does_bin_exist "brave" && remove \
    "${XDG_CACHE_HOME}/BraveSoftware" \
    "${XDG_CONFIG_HOME}/BraveSoftware"
! does_bin_exist "brz" && remove "${XDG_CACHE_HOME}/breezy"
! does_bin_exist "cairo-dock" && remove "${XDG_CONFIG_HOME}/cairo-dock"
! does_bin_exist "chiaki" && remove \
    "${XDG_CONFIG_HOME}/Chiaki" \
    "${XDG_DATA_HOME}/Chiaki"
! does_bin_exist "chromium" && remove \
    "${XDG_CACHE_HOME}/chromium" \
    "${XDG_CONFIG_HOME}/chromium"
! does_bin_exist "code" && remove \
    "${XDG_CONFIG_HOME}/Code" \
    "${HOME}/.vscode"
! does_bin_exist "code-oss" && remove \
    "${XDG_CONFIG_HOME}/Code - OSS" \
    "${XDG_CONFIG_HOME}/code-oss" \
    "${HOME}/.vscode-oss"
! does_bin_exist "codium" && remove "${XDG_CONFIG_HOME}/VSCodium"
! does_bin_exist "code-oss" "codium" && remove "${HOME}/.vscode-oss"
! does_bin_exist "convert" && remove "${XDG_CACHE_HOME}/ImageMagick"
! does_bin_exist "docker" && remove "${ROOT_VAR_LIB}/docker"
! does_bin_exist "dockx" && remove "${XDG_DATA_HOME}/dockbarx"
! does_bin_exist "dotnet" && \
    remove "${HOME}/.dotnet" \
    remove "${HOME}/.templateengine"
! does_bin_exist "droidcam" && remove "${XDG_CONFIG_HOME}/droidcam"
! does_bin_exist "duolingo-desktop" && remove \
    "${XDG_CONFIG_HOME}/DL: language lessons" \
    "${XDG_CONFIG_HOME}/Duolingo"
#! does_bin_exist "evolution" && remove \
#    "${XDG_CACHE_HOME}/evolution" \
#    "${XDG_CONFIG_HOME}/evolution" \
#    "${XDG_DATA_HOME}/evolution"
! does_bin_exist "electronmail-bin" && remove "${XDG_CONFIG_HOME}/electron-mail"
! does_bin_exist "eog" && remove "${XDG_CONFIG_HOME}/eog"
! does_bin_exist "fastfetch" && remove \
    "${XDG_CACHE_HOME}/fastfetch" \
    "${XDG_CONFIG_HOME}/fastfetch"
! does_bin_exist "fltk-config" && remove "${HOME}/.fltk"
! does_bin_exist "fma-config-tool" && remove "${XDG_CONFIG_HOME}/filemanager-actions"
! does_bin_exist "fragments" && remove \
    "${XDG_CACHE_HOME}/fragments" \
    "${XDG_CONFIG_HOME}/fragments" \
    "${XDG_DATA_HOME}/fragments"
! does_bin_exist "geforcenow-electron" && remove "${XDG_CONFIG_HOME}/GeForce NOW"
! does_bin_exist "gimp" && \
    remove "${XDG_CACHE_HOME}/gimp" \
    remove "${XDG_CONFIG_HOME}/GIMP"
! does_bin_exist "gkraken" && remove "${XDG_CONFIG_HOME}/gkraken"
! does_bin_exist "gksu" && remove "${HOME}/.gksu.lock"
! does_bin_exist "gmic" && remove "${XDG_CONFIG_HOME}/gmic"
! does_bin_exist "gnome-calculator" && remove "${XDG_CACHE_HOME}/gnome-calculator"
! does_bin_exist "gnome-photos" && remove \
    "${XDG_CACHE_HOME}/gnome-photos" \
    "${XDG_DATA_HOME}/gnome-photos"
! does_bin_exist 'gnome-screenshot' && remove "${XDG_CACHE_HOME}/gnome-screenshot"
! does_bin_exist 'gnome-software' && remove "${XDG_CACHE_HOME}/gnome-software"
! does_bin_exist 'gnome-sound-recorder' && remove "${XDG_DATA_HOME}/org.gnome.SoundRecorder"
! does_bin_exist 'gnubg' && remove "${HOME}/.gnubg"
! does_bin_exist 'go' && remove "${XDG_CACHE_HOME}/go-build"
! does_bin_exist 'gradle' && remove \
    "${HOME}/.gradle" \
    "${XDG_DATA_HOME}/gradle"
! does_bin_exist 'gsconnect' && remove \
    "${XDG_CACHE_HOME}/gsconnect" \
    "${XDG_CONFIG_HOME}/gsconnect"
! does_bin_exist 'hardinfo' && remove "${XDG_CONFIG_HOME}/hardinfo"
! does_bin_exist 'hashcat' && remove \
    "${XDG_CACHE_HOME}/hashcat" \
    "${XDG_CONFIG_HOME}/hashcat" \
    "${XDG_DATA_HOME}/hashcat"
! does_bin_exist 'icaclient' && remove \
    "${HOME}/.ICAClient"
! does_bin_exist 'inkscape' && remove \
    "${XDG_CACHE_HOME}/inkscape" \
    "${XDG_CONFIG_HOME}/inkscape"
! does_bin_exist 'jan' && remove "${XDG_CONFIG_HOME}/Jan"
! does_bin_exist 'java' && remove "${HOME}/.java"
! does_bin_exist 'kupfer' && remove "${XDG_CONFIG_HOME}/kupfer"
! does_bin_exist 'libreoffice' && remove "${XDG_CONFIG_HOME}/libreoffice"
! does_bin_exist 'lollypop' && remove "${XDG_DATA_HOME}/lollypop"
! does_bin_exist 'lsd' && remove "${XDG_CONFIG_HOME}/lsd"
! does_bin_exist 'lutris' && remove \
    "${XDG_CACHE_HOME}/lutris" \
    "${XDG_CONFIG_HOME}/lutris" \
    "${XDG_DATA_HOME}/lutris"
! does_bin_exist 'lyrebird' && remove \
    "${XDG_CONFIG_HOME}/lyrebird"
! does_bin_exist 'mcaselector' && remove \
    "${HOME}/.mcaselector" \
    "${XDG_CACHE_HOME}/mcaselector" \
    "${XDG_CONFIG_HOME}/mcaselector" \
    "${XDG_DATA_HOME}/mcaselector"
! does_bin_exist 'mcedit' && remove "${HOME}/.mcedit"
! does_bin_exist 'minetest' && remove "${XDG_CACHE_HOME}/minetest"
! does_bin_exist 'mono' && remove "${HOME}/.mono"
! does_bin_exist 'mpv' && remove "${XDG_CONFIG_HOME}/mpv"
! does_bin_exist 'nano' && remove \
    "${HOME}/.nanorc" \
    "${XDG_DATA_HOME}/nano"
! does_bin_exist 'nemo' && remove \
    "${XDG_DATA_HOME}/nemo" \
    "${XDG_DATA_HOME}/nemo-python"
! does_bin_exist 'neofetch' && remove "${XDG_CONFIG_HOME}/neofetch"
! does_bin_exist 'notion-app' && remove "${XDG_CONFIG_HOME}/Notion"
! does_bin_exist 'npm' && remove \
    "${HOME}/.npm" \
    "${HOME}/.npmrc" \
    "${XDG_DATA_HOME}/npm" \
    "${XDG_CACHE_HOME}/npm" \
    "${XDG_CONFIG_HOME}/npm" \
    "${XDG_RUNTIME_HOME}/npm"
! does_bin_exist 'nvidia-settings' && remove \
    "${HOME}/.nvidia-settings-rc" \
    "${XDG_CONFIG_HOME}/nvidia/settings" \
    "${HOME_VAR_APP}/"*"/cache/nvidia"
! does_bin_exist 'nvidia-settings' && remove \
    "${XDG_CACHE_HOME}/nvidia" \
    "${XDG_CONFIG_HOME}/nvidia"
! does_bin_exist 'onlyoffice-desktopeditors' && remove \
    "${XDG_CONFIG_HOME}/onlyoffice" \
    "${XDG_DATA_HOME}/onlyoffice"
! does_bin_exist 'openrazer-daemon' && remove "${XDG_DATA_HOME}/openrazer"
! does_bin_exist 'openrgb' && remove "${XDG_CONFIG_HOME}/OpenRGB"
! does_bin_exist 'openshot-qt' && remove "${HOME}/.openshot_qt"
! does_bin_exist 'pavucontrol' && remove "${XDG_CONFIG_HOME}/pavucontrol.ini"
! does_bin_exist 'pip' && remove "${XDG_CACHE_HOME}/pip"
! does_bin_exist 'plank' && remove \
    "${XDG_CACHE_HOME}/plank" \
    "${XDG_CONFIG_HOME}/plank" \
    "${XDG_DATA_HOME}/plank"
! does_bin_exist 'plexmediaplayer' && remove \
    "${XDG_CACHE_HOME}/plex-media-player" \
    "${XDG_CACHE_HOME}/plexmediaplayer" \
    "${XDG_CONFIG_HOME}/plex.tv" \
    "${XDG_DATA_HOME}/plexmediaplayer"
! does_bin_exist 'postman' && \
    remove "${HOME}/Postman" \
    remove "${XDG_CONFIG_HOME}/Postman"
! does_bin_exist 'protonfixes' && remove "${XDG_CACHE_HOME}/protonfixes"
! does_bin_exist 'protontricks' && remove "${XDG_CACHE_HOME}/protontricks"
! does_bin_exist 'rclone' && remove "${XDG_CONFIG_HOME}/rclone"
! does_bin_exist 'rhythmbox' && remove \
    "${XDG_CACHE_HOME}/rhythmbox" \
    "${XDG_DATA_HOME}/rhythmbox"
! does_bin_exist 'runelite' && remove "${HOME}/.runelite"
! does_bin_exist 'samrewritten' && remove "${XDG_CACHE_HOME}/SamRewritten"
! does_bin_exist 'simplescreenrecorder' && remove "${HOME}/.ssr"
! does_bin_exist 'simplenote' && remove "${XDG_CONFIG_HOME}/Simplenote"
! does_bin_exist 'snap' && remove "${HOME}/.snap"
! does_bin_exist 'snapcraft' && remove \
    "${XDG_CACHE_HOME}/snapcraft" \
    "${XDG_CONFIG_HOME}/snapcraft"
! does_bin_exist 'sokogrump' && remove "${XDG_DATA_HOME}/SokoGrump"
! does_bin_exist 'spotify' && remove \
    "${XDG_CACHE_HOME}/spotify" \
    "${XDG_CONFIG_HOME}/spotify"
! does_bin_exist 'teamviewer' && remove \
    "${XDG_CACHE_HOME}/TeamViewer" \
    "${XDG_CONFIG_HOME}/teamviewer" \
    "${XDG_DATA_HOME}/teamviewer15" \
    "${ROOT_VAR_LOG}/log/teamviewer15"
! does_bin_exist 'thunar' && remove "${XDG_CONFIG_HOME}/Thunar"
! does_bin_exist 'totem' && remove \
    "${XDG_CACHE_HOME}/totem" \
    "${XDG_CONFIG_HOME}/totem" \
    "${XDG_DATA_HOME}/totem"
! does_bin_exist 'transmission-daemon' && remove "${XDG_CONFIG_HOME}/transmission-daemon"
! does_bin_exist 'ulauncher' && remove "${XDG_DATA_HOME}/ulauncher"
! does_bin_exist 'virtualbox' && remove "${XDG_CONFIG_HOME}/VirtualBox"
! does_bin_exist 'vim' && remove \
    "${HOME}/.viminfo" \
    "${HOME}/.vimrc" \
    "${XDG_CACHE_HOME}/vim"
! does_bin_exist 'vlc' && remove \
    "${XDG_CACHE_HOME}/vlc" \
    "${XDG_CONFIG_HOME}/vlc" \
    "${XDG_DATA_HOME}/vlc"
! does_bin_exist 'wike' && remove "${XDG_CACHE_HOME}/wike"
! does_bin_exist 'yarn' && remove \
    "${HOME}/.yarn" \
    "${HOME}/.yarnrc"
! does_bin_exist 'yay' && remove \
    "${XDG_CACHE_HOME}/yay" \
    "${XDG_CONFIG_HOME}/yay"
! does_bin_exist 'youtube-dl' && remove "${XDG_CACHE_HOME}/youtube-dl"
! does_bin_exist 'yt-dlp' && remove "${XDG_CACHE_HOME}/yt-dlp"
! does_bin_exist 'zsh' && remove "${HOME}/.zshrc"

############
### Chat ###
############

# Discord
! does_bin_exist "discord" && remove "${XDG_CONFIG_HOME}/discord"
remove_logs_in_dirs "${HOME_VAR_APP}/com.discordapp.Discord/config/discord"

# Signal
! does_bin_exist "signal-desktop" && remove "${XDG_CONFIG_HOME}/Signal"
remove_logs_in_dirs "${HOME_VAR_APP}/org.signal.Signal/config/Signal"

# Teams
! does_bin_exist "teams" && remove \
    "${XDG_CONFIG_HOME}/Microsoft Teams - Preview" \
    "${XDG_CONFIG_HOME}/Microsoft/Microsoft Teams"
! does_bin_exist "teams-insiders" && remove \
    "${XDG_CONFIG_HOME}/Microsoft Teams - Insiders" \
    "${XDG_CONFIG_HOME}/Microsoft/Microsoft Teams - Insiders"
! does_bin_exist "teams" "teams-insiders" && remove "${XDG_CONFIG_HOME}/teams"


remove_logs_in_dirs "${HOME_VAR_APP}/com.microsoft.Teams/config/teams" \
                    "${HOME_VAR_APP}/com.microsoft.Teams/config/Microsoft/Microsoft Teams"

# Telegram
! does_bin_exist "telegram-desktop" && remove "${XDG_DATA_HOME}/TelegramDesktop"
remove_logs_in_dirs "${HOME_VAR_APP}/org.telegram.desktop/data/TelegramDesktop"

# WhatsApp
! does_bin_exist "whatsapp-nativefier" && remove \
    "${ROOT_OPT}/whatsapp-nativefier" \
    "${XDG_CONFIG_HOME}/whatsapp-nativefier-d40211"
! does_bin_exist "whatsdesk" && remove "${HOME}/.whatsdesk"

# Zoom
! does_bin_exist 'zoom' && remove \
    "${HOME}/.zoom" \
    "${XDG_DOCUMENTS_DIR}/Zoom" \
    "${HOME}/Documents/Zoom"

#####################
### File Managers ###
#####################
! does_bin_exist 'dolphin' && remove \
    "${XDG_CONFIG_HOME}/dolphinrc" \
    "${XDG_CONFIG_HOME}/kde.org/UserFeedback.org.kde.dolphin.conf" \
    "${XDG_DATA_HOME}/dolphin"
! does_bin_exist 'pcmanfm' && remove "${XDG_CONFIG_HOME}/pcmanfm"
! does_bin_exist 'pcmanfm-qt' && remove "${XDG_CONFIG_HOME}/pcmanfm-qt"

#############
### Games ###
#############

# Minecraft
remove_logs_in_dirs \
    "${HOME}/.minecraft" \
    "${HOME_VAR_APP}/com.mojang.Minecraft/.minecraft" \
    "${ROOT_SRV}/papermc"

for PRISMLAUNCHER_INSTANCE_DIR in "${HOME_VAR_APP}/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/"*; do
    remove "${PRISMLAUNCHER_INSTANCE_DIR}/.minecraft/baritone/"*"/"
    remove "${PRISMLAUNCHER_INSTANCE_DIR}/.minecraft/XaeroWaypoints_BACKUP"*
    remove_old_items "${PRISMLAUNCHER_INSTANCE_DIR}/.minecraft/downloads"
    remove_old_items "${PRISMLAUNCHER_INSTANCE_DIR}/.minecraft/.fabric/remappedJars"
done

if [ -d "${XDG_DATA_HOME}/Paradox Interactive" ]; then
    remove \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/.launcher-cache' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/cache' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/gfx' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/shadercache' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/terraincache'

    remove \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/crashes' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/dumps' \
        "${XDG_DATA_HOME}/Paradox Interactive/"*'/exceptions'
fi

#########################
### Internet Browsers ###
#########################

# Chrome
! does_bin_exist 'google-chrome' && remove \
    "${XDG_CACHE_HOME}/google-chrome" \
    "${XDG_CONFIG_HOME}/google-chrome"
! does_bin_exist "google-chrome-beta" && remove \
    "${XDG_CACHE_HOME}/google-chrome-beta" \
    "${XDG_CONFIG_HOME}/google-chrome-beta"
! does_bin_exist "google-chrome-unstable" && remove \
    "${XDG_CACHE_HOME}/google-chrome-unstable" \
    "${XDG_CONFIG_HOME}/google-chrome-unstable"

# Edge
! does_bin_exist "microsoft-edge-beta" && remove \
    "${XDG_CACHE_HOME}/microsoft-edge-beta" \
    "${XDG_CACHE_HOME}/Microsoft/Edge" \
    "${XDG_CONFIG_HOME}/microsoft-edge-beta"
! does_bin_exist "microsoft-edge-dev" && remove \
    "${XDG_CACHE_HOME}/microsoft-edge-dev" \
    "${XDG_CACHE_HOME}/Microsoft/Edge" \
    "${XDG_CONFIG_HOME}/microsoft-edge-dev"

# Firefox
FIREFOX_PROFILES_INI_FILE="${HOME_MOZILLA}/firefox/profiles.ini"
[ -f "${FIREFOX_PROFILES_INI_FILE}" ] && FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

if ! does_bin_exist 'firefox' \
&& ! does_bin_exist 'firefox-esr'; then
    remove "${XDG_CACHE_HOME}/mozilla/firefox"
fi

remove "${HOME}/.mozilla/firefox/Crash Reports" \
       "${HOME_VAR_APP}/org.mozilla.firefox/.mozilla/firefox/Crash Reports"        

for FIREFOX_PROFILES_DIR in "${HOME_VAR_APP}/org.mozilla.firefox/.mozilla/firefox" \
                            "${HOME_VAR_APP}/io.gitlab.librewolf-community/.librewolf" \
                            "${HOME}/.mozilla/firefox" \
                            "${HOME}/.librewolf"; do
    remove "${FIREFOX_PROFILES_DIR}/"*"/bookmarkbackups" \
           "${FIREFOX_PROFILES_DIR}/"*"/"*.bak \
           "${FIREFOX_PROFILES_DIR}/"*"/compatibility.ini" \
           "${FIREFOX_PROFILES_DIR}/"*"/crashes" \
           "${FIREFOX_PROFILES_DIR}/"*"/datareporting" \
           "${FIREFOX_PROFILES_DIR}/"*"/enumeratedevices.txt" \
           "${FIREFOX_PROFILES_DIR}/"*"/formhistory.sqlite" \
           "${FIREFOX_PROFILES_DIR}/"*"/gmp" \
           "${FIREFOX_PROFILES_DIR}/"*"/gmp-widevinecdm" \
           "${FIREFOX_PROFILES_DIR}/"*"/saved-telemetry-pings" \
           "${FIREFOX_PROFILES_DIR}/"*"/sessionstore-backups" \
           "${FIREFOX_PROFILES_DIR}/"*"/times.json" \
           "${FIREFOX_PROFILES_DIR}/"*"/weave/failed" \
           "${FIREFOX_PROFILES_DIR}/"*"/weave/logs" \
           "${FIREFOX_PROFILES_DIR}/"*"/weave/xulstore.json" \

    # Don't remove storage-sync-v2.sqlite-wal, as that clears all entries from the Authenticator extension
    remove "${FIREFOX_PROFILES_DIR}/"*"/cokies.sqlite-wal" \
           "${FIREFOX_PROFILES_DIR}/"*"/favicons.sqlite-wal" \
           "${FIREFOX_PROFILES_DIR}/"*"/places.sqlite-wal" \
           "${FIREFOX_PROFILES_DIR}/"*"/webappsstore.sqlite-wal" \
    
    remove "${HOME_MOZILLA}/firefox/${FIREFOX_PROFILE_ID}/formhistory.sqlite"
done

#################
### Terminals ###
#################
! does_bin_exist "konsole" && remove "${XDG_CONFIG_HOME}/konsolerc"

####################
### Text Editors ###
####################
! does_bin_exist "gedit" && \
    remove "${XDG_CONFIG_HOME}/gedit" \
    remove "${XDG_DATA_HOME}/gedit"

############
### WINE ###
############
! does_bin_exist "wine" && remove "${XDG_CACHE_HOME}/wine"
! does_bin_exist "winetricks" && remove "${XDG_CACHE_HOME}/winetricks"

remove "${XDG_CONFIG_HOME}/menus/applications-merged/"wine-*.menu
remove "${XDG_DATA_HOME}/applications/wine"
remove "${XDG_DATA_HOME}/applications/wine-"*

[ "${NPM_CONFIG_USERCONFIG}" != "${HOME}/.npmrc" ] && remove "${HOME}/.npmrc"
[ -f "${XDG_DATA_HOME}/wget/hosts" ] && remove "${HOME}/.wget-hsts"
[ -f "${HOME}/.bash_logout" ] && [[ -z "$(grep -v '^\s*#.*$' ${HOME}/.bash_logout)" ]] && remove "${HOME}/.bash_logout"

# Redundant home directories
[ -d "${XDG_CACHE_HOME}/nuget/packages" ]   && remove "${HOME}/.nuget/packages"
[ -d "${XDG_CACHE_HOME}/nvidia" ]           && remove "${HOME}/.nv"
[ -d "${XDG_DATA_HOME}/cargo" ]             && remove "${HOME}/.cargo"
[ -d "${XDG_DATA_HOME}/pki" ]               && remove "${HOME}/.pki"

# Redundant home files
[ -f "${XDG_CACHE_HOME}/less/history" ]         && remove "${HOME}/.lesshst"
[ -f "${XDG_CONFIG_HOME}/git/config" ]          && remove "${HOME}/.gitconfig"
[ -f "${XDG_CONFIG_HOME}/gtk-2.0/gtkrc" ]       && remove "${HOME}/.gtkrc-2.0"
[ -f "${XDG_CONFIG_HOME}/nvidia/settings" ]     && remove "${HOME}/.nvidia-settings-rc"
[ -f "${XDG_CONFIG_HOME}/pulse/cookie" ]        && remove "${HOME}/.pulse-cookie"
[ -f "${XDG_CONFIG_HOME}/readline/inputrc" ]    && remove "${HOME}/.inputrc"
[ -f "${XDG_DATA_HOME}/bash/aliases" ]          && remove "${HOME}/.shell_aliases"
[ -f "${XDG_DATA_HOME}/bash/history" ]          && remove "${HOME}/.bash_history"
[ -f "${XDG_DATA_HOME}/bash/options" ]          && remove "${HOME}/.shell_opts"
[ -f "${XDG_DATA_HOME}/bash/prompt" ]           && remove "${HOME}/.shell_prompt"
[ -f "${XDG_DATA_HOME}/bash/variables" ]        && remove "${HOME}/.shell_vars"
[ -f "${XDG_DATA_HOME}/readline/inputrc" ]      && remove "${HOME}/.inputrc"
[ -f "${XDG_DATA_HOME}/wget/hosts" ]            && remove "${HOME}/.wget-hsts"
[ -f "${XDG_RUNTIME_DIR}/Xauthority" ]          && remove "${HOME}/.Xauthority"

# GNOME Extensions
! is_gnome_shell_extension_installed "tiling-assistant" && remove "${XDG_CONFIG_HOME}/tiling-assistant"

# Steam games / apps
does_bin_exist "steam" && remove \
    "${XDG_DATA_HOME}/Steam/"*"/steam-runtime/usr/share/doc"

! is_steam_app_installed "8930" && remove \
    "${XDG_DATA_HOME}/Aspyr/Sid Meier's Civilization 5" \
    "${XDG_DATA_HOME}/Aspyr/com.aspyr.civ5xp.json"
! is_steam_app_installed "20920" && remove "${XDG_DATA_HOME}/cdprojektred/witcher2"
! is_steam_app_installed "38700" && remove "${XDG_DATA_HOME}/twotribes/toki_tori"
! is_steam_app_installed "105600" && remove "${XDG_DATA_HOME}/Terraria"
! is_steam_app_installed "200510" && remove "${XDG_DATA_HOME}/feral-interactive/XCOM"
! is_steam_app_installed "203160" && remove "${XDG_DATA_HOME}/feral-interactive/Tomb Raider"
! is_steam_app_installed "200710" && remove "${XDG_DATA_HOME}/Runic Games/Torchlight 2"
! is_steam_app_installed "206690" && remove "${HOME}/.ibomberdefensepacific"
! is_steam_app_installed "215510" && remove "${XDG_DATA_HOME}/rocketbirds"
! is_steam_app_installed "218660" && remove "${HOME}/.Cobra Mobile/iBomber Attack"
! is_steam_app_installed "219150" && remove "${XDG_DATA_HOME}/HotlineMiami"
! is_steam_app_installed "246110" && remove "${XDG_DATA_HOME}/doublefine/massivechalice"
! is_steam_app_installed "250820" && remove \
    "${HOME}/steamvr" \
    "${XDG_CACHE_HOME}/SteamVR" \
    "${XDG_CONFIG_HOME}/openvr" \
    "${XDG_CONFIG_HOME}/openxr" \
    "${XDG_CONFIG_HOME}/unity3d/Valve/SteamVR\ Room\ Setup" \
    "${XDG_CONFIG_HOME}/Valve/vrmonitor.conf" \
    "${XDG_DATA_HOME}/applications/valve-vrmonitor.desktop"
! is_steam_app_installed "251910" && remove "${XDG_DATA_HOME}/Firebrand Games/Solar Flux"
! is_steam_app_installed "252950" && remove "${XDG_DATA_HOME}/Rocket League"
! is_steam_app_installed "255300" && remove "${XDG_DATA_HOME}/Daedalic Entertainment/Journey of a Roach"
! is_steam_app_installed "263060" && remove "${XDG_CONFIG_HOME}/unity3d/IndieGala/Blockstorm"
! is_steam_app_installed "284710" && remove "${XDG_CACHE_HOME}/ArtifexMundi/Abyss_TheWraithsOfEden"
! is_steam_app_installed "305620" && remove "${XDG_DATA_HOME}/Hinterland/TheLongDark"
! is_steam_app_installed "313340" && remove "${XDG_CONFIG_HOME}/unity3d/David\ OReilly/Mountain"
! is_steam_app_installed "319270" && remove "${XDG_DATA_HOME}/great-permutator"
! is_steam_app_installed "322330" && remove \
    "${HOME}/.klei/DoNotStarveTogether" \
    "${HOME}/.klei/DoNotStarveTogetherBetaBranch"
! is_steam_app_installed "356040" && remove "${STEAM_CONFIG}/unity3d/Team17/Sheltered"
! is_steam_app_installed "370360" && remove \
    "${XDG_CONFIG_HOME}/unity3d/Zachtronics/TIS-100" \
    "${XDG_DATA_HOME}/TIS-100"
! is_steam_app_installed "383870" && remove "${XDG_CONFIG_HOME}/unity3d/CampoSanto/Firewatch"
! is_steam_app_installed "385710" && remove "${XDG_CONFIG_HOME}/INK"
! is_steam_app_installed "434210" && remove "${XDG_CONFIG_HOME}/unity3d/BabaYaga/It's Spring Again"
! is_steam_app_installed "464920" && remove "${XDG_DATA_HOME}/Surviving Mars"
! is_steam_app_installed "476240" && remove "${XDG_CONFIG_HOME}/unity3d/Arzola's/KNIGHTS"
! is_steam_app_installed "490230" && remove "${XDG_CONFIG_HOME}/SWARMRIDERS"
! is_steam_app_installed "517910" && remove "${XDG_DATA_HOME}/ags/Sisyphus Reborn"
! is_steam_app_installed "680360" && remove "${XDG_CONFIG_HOME}/unity3d/voxGames/Regions of Ruin"
! is_steam_app_installed "729040" && remove "${XDG_DATA_HOME}/Steam/steamapps/common/BorderlandsGOTYEnhanced"
! is_steam_app_installed "736260" && remove "${XDG_DATA_HOME}/Baba_Is_You"
! is_steam_app_installed "1169040" && remove "${XDG_CONFIG_HOME}/Necesse"

for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
    remove \
        "${STEAM_LIBRARY_PATH}/common/"*"/licenses"

    is_steam_app_installed "8930" && remove \
        "${STEAM_LIBRARY_PATH}/common/Sid Meier's Civilization V/steamassets/"*.mov \
        "${STEAM_LIBRARY_PATH}/common/Sid Meier's Civilization V/steamassets/assets/dlc/"*/*.mov
    is_steam_app_installed "8980" && remove \
        "${STEAM_LIBRARY_PATH}/common/Borderlands/WillowGame/Movies/NVidia.bik"
    is_steam_app_installed "20920" && remove \
        "${STEAM_LIBRARY_PATH}/common/the witcher 2/CookedPC/movies/nvidia.usm"
    is_steam_app_installed "281990" && remove \
        "${STEAM_LIBRARY_PATH}/common/Stellaris/ebook" \
        "${STEAM_LIBRARY_PATH}/common/Stellaris/licenses" \
        "${STEAM_LIBRARY_PATH}/common/Stellaris/soundtrack"
    is_steam_app_installed "322330" && remove "${STEAM_LIBRARY_PATH}/common/Don't Starve Together/cached_mods"
    is_steam_app_installed "476600" && remove "${STEAM_LIBRARY_PATH}/common/Call of Duty WWII/SHG_Logo.bik"
    is_steam_app_installed "859580" && remove "${STEAM_LIBRARY_PATH}/common/ImperatorRome/licenses"
    is_steam_app_installed "990080" && remove "${STEAM_LIBRARY_PATH}/common/ShadowOfMordor/share/data/game/interface/videos"
    is_steam_app_installed "1158310" && remove "${STEAM_LIBRARY_PATH}/common/Crusader Kings III/game/licenses"

    ! is_steam_app_installed "8930" && remove "${STEAM_LIBRARY_PATH}/common/Sid Meier's Civilization V"
    ! is_steam_app_installed "41070" && remove "${STEAM_LIBRARY_PATH}/common/Serious Sam 3"
    ! is_steam_app_installed "50300" && remove "${STEAM_LIBRARY_PATH}/common/SpecOps_TheLine"
    ! is_steam_app_installed "70000" && remove "${STEAM_LIBRARY_PATH}/common/Dino D-Day"
    ! is_steam_app_installed "91310" && remove "${STEAM_LIBRARY_PATH}/common/Dead Island"
    ! is_steam_app_installed "99910" && remove "${STEAM_LIBRARY_PATH}/common/Puzzle Pirates"
    ! is_steam_app_installed "105600" && remove "${STEAM_LIBRARY_PATH}/common/Terraria"
    ! is_steam_app_installed "205910" && remove "${STEAM_LIBRARY_PATH}/common/TinyAndBig"
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
    ! is_steam_app_installed "322330" && remove "${STEAM_LIBRARY_PATH}/common/Don't Starve Together"
    ! is_steam_app_installed "328080" && remove "${STEAM_LIBRARY_PATH}/common/Rise to Ruins"
    ! is_steam_app_installed "346010" && remove "${STEAM_LIBRARY_PATH}/common/Besiege"
    ! is_steam_app_installed "356040" && remove "${STEAM_LIBRARY_PATH}/common/Sheltered"
    ! is_steam_app_installed "393080" && remove "${STEAM_LIBRARY_PATH}/common/Call of Duty Modern Warfare Remastered"
    ! is_steam_app_installed "442070" && remove "${STEAM_LIBRARY_PATH}/common/Drawful 2"
    ! is_steam_app_installed "552110" && remove "${STEAM_LIBRARY_PATH}/common/Puzzle Pirates Dark Seas"

    ! does_bin_exist "nvidia-settings" && remove \
        "${STEAM_LIBRARY_PATH}/common/Hogwarts Legacy/Engine/Plugins/Runtime/Nvidia"
done

# Unwanted files in the Downloads dir, by extension
if [ -d "${XDG_DOWNLOAD_DIR}" ]; then
    while IFS='' read -r -d '' UNWANTED_FILE; do
        remove "${UNWANTED_FILE}"
    done < <(find "${XDG_DOWNLOAD_DIR}" -maxdepth 1 -type f -iregex ".*\.\(ica\|torrent\)$" -print0)
fi

# Unwanted application launchers
remove "${XDG_CONFIG_HOME}/menus/applications-merged/user-chrome-apps.menu"

for APPLICATION_LAUNCHERS_DIR in "${XDG_DESKTOP_DIR}" "${XDG_DATA_HOME}/applications"; do
    if [ -n "${APPLICATION_LAUNCHERS_DIR}" ] \
    && [ -d "${APPLICATION_LAUNCHERS_DIR}" ] \
    && ls "${APPLICATION_LAUNCHERS_DIR}" | grep -q ".*\.desktop$"; then
        for STEAM_APP_LAUNCHER in $(grep "^Exec=steam" "${APPLICATION_LAUNCHERS_DIR}"/*.desktop | awk -F":" '{print $1}' | sed 's/ /@SPACE@/g'); do
            STEAM_APP_LAUNCHER=$(echo "${STEAM_APP_LAUNCHER}" | sed 's/@SPACE@/ /g')
            remove "${STEAM_APP_LAUNCHER}"
        done
    fi
done

# Backups
remove "${XDG_CONFIG_HOME}/monitors.xml~"

# Telemetry
remove "${HOME}/.dotnet/TelemetryStorageService"

# Logs
if ${CLEAN_LOGS}; then
    remove "${XDG_CONFIG_HOME}/logs"
    remove "${XDG_CONFIG_HOME}/unity3d"/*.log
    remove "${XDG_DATA_HOME}/xorg/"*".log"
    remove "${XDG_DATA_HOME}/xorg/"*".log.old"

    remove "${ROOT_VAR_LOG}/pacman.log"

    for SUBFOLDER_NAME in "crash-reports" "logs"; do
        remove "${HOME_VAR_APP}/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/"*"/.minecraft/${SUBFOLDER_NAME}"
    done

    remove \
        "${HOME}/.klei/DoNotStarveTogether/backup/client_chat_log" \
        "${HOME}/.klei/DoNotStarveTogether/backup/client_log"

    remove_logs_in_dirs "${HOME}/.factorio" \
                        "${HOME}/.gradle/daemon/"* \
                        "${HOME}/.ICAClient" \
                        "${HOME}/.klei/DoNotStarveTogether" \
                        "${HOME}/.npm" \
                        "${HOME}/.steam/steamcmd/workshopbuilds" \
                        "${HOME}/.vscode/extensions/"* \
                        "${HOME}/.vscode/extensions/"*"/file-types" \
                        "${HOME}/Zomboid" \
                        "${XDG_CONFIG_HOME}/Code" \
                        "${XDG_CONFIG_HOME}/unity3d" \
                        "${XDG_CONFIG_HOME}/unity3d"/*/* \
                        "${XDG_DATA_HOME}/gvfs-metadata" \
                        "${XDG_DATA_HOME}/Paradox Interactive"/* \
                        "${XDG_DATA_HOME}/Steam" \
                        "${XDG_DATA_HOME}/Steam/config/htmlcache" \
                        "${XDG_DATA_HOME}/Steam/config/htmlcache/VideoDecodeStats" \
                        "${XDG_DATA_HOME}/Steam/config/SteamVR/htmlcache" \
                        "${XDG_DATA_HOME}/Steam/steamapps/common"/* \
                        "${XDG_DATA_HOME}/Steam/steamapps/common"/*/*_Data \
                        "${XDG_DATA_HOME}/Steam/steamapps/compatdata/"*"/pfx" \
                        "${XDG_DATA_HOME}/Steam/steamapps/compatdata/"*"/pfx/drive_c/users/steamuser/Temp" \
                        "${XDG_DATA_HOME}/Steam/steamapps/compatdata/"*"/pfx/drive_c/windows" \
                        "${XDG_DATA_HOME}/Steam/workshopbuilds" \
                        "${XDG_DATA_HOME}/Surviving Mars" \
                        "${HOME_VAR_APP}"/*"/cache"/* \
                        "${HOME_VAR_APP}"/*"/config"/* \
                        "${HOME_VAR_APP}"/*"/config"/*/* \
                        "${HOME_VAR_APP}"/*"/data/gvfs-metadata" \
                        "${HOME_VAR_APP}/com.bitwarden.desktop/config/Bitwarden" \
                        "${HOME_VAR_APP}/com.getpostman.Postman/config/Postman" \
                        "${HOME_VAR_APP}/com.github.vladimiry.ElectronMail/config/electron-mail" \
                        "${HOME_VAR_APP}/com.simplenote.Simplenote/config" \
                        "${HOME_VAR_APP}/org.libreoffice.LibreOffice/config/libreoffice/4/user"

        if ${CLEAN_BROWSER_LOGS}; then
            if [ -d "${DIR}/IndexedDB" ] \
            || [ -d "${DIR}/shared_proto_db" ]; then
                remove_logs_in_dir "${DIR}/IndexedDB"/*
                remove_logs_in_dir "${DIR}/File System"/*
                remove_logs_in_dir "${DIR}/File System"/*/*/*
                remove_logs_in_dir "${DIR}/Session Storage"
                remove_logs_in_dir "${DIR}/Service Worker/Database"
                remove_logs_in_dir "${DIR}/shared_proto_db"
                remove_logs_in_dir "${DIR}/shared_proto_db/metadata"
            fi
        fi
fi

# Unused locales
#shopt -s extglob
#remove "${ROOT_USR_SHARE}/locale/"!(en*|ro*)
#remove "${ROOT_USR_SHARE}/man/"!(en*|ro*|man*)

# Empty directories
for DIR in  "${HOME}/.Cobra Mobile" \
            "${HOME}/.w3m" \
            "${XDG_CACHE_HOME}"/* \
            "${XDG_CONFIG_HOME}"/* \
            "${XDG_DATA_HOME}"/* \
            "${ROOT_USR_SHARE}/licenses"; do
    [ ! -d "${DIR}" ] && continue

    remove_dir_if_empty "${DIR}"
done
[ "${XDG_DOCUMENTS_DIR}" != "${HOME}/Documents" ] && remove_dir_if_empty "${HOME}/Documents"

# Flatpaks
for FLATPAK in "${HOME_VAR_APP}"/*; do
    FLATPAK=$(echo "${FLATPAK}" | sed 's/.*\/\([^\/]*\)$/\1/g')
    ! is_flatpak_installed "${FLATPAK}" && remove "${HOME_VAR_APP}/${FLATPAK}"
    remove "${HOME_VAR_APP}/${FLATPAK}/cache"
done

for FLATPAK_CACHE_DIR in "${ROOT_VAR}/tmp"/flatpak-cache-*; do
    remove "${FLATPAK_CACHE_DIR}"
done

# Other unwanted files
remove \
    "${HOME}/.ServiceHub" \
    "${ROOT_SRV}/papermc/plugins/.paper-remapped"

does_bin_exist 'journalctl' && run_as_su journalctl --vacuum-time=3days
does_bin_exist 'pacman' && yes | run_as_su pacman -Scc
