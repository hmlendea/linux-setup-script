#!/bin/bash
ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g')
[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"

USER_REAL="${SUDO_USER}"
[ -z "${USER_REAL}" ] && USER_REAL="${USER}"
HOME_REAL="/home/${USER_REAL}"

GLOBAL_LAUNCHERS_PATH="/usr/share/applications"
LOCAL_LAUNCHERS_PATH="${HOME_REAL}/.local/share/applications"

ICON_THEME=$(sudo -u "${USER_REAL}" -H gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
ICON_THEME_PATH="/usr/share/icons/${ICON_THEME}"

find_launcher_by_name() {
    NAME_ENTRY_VALUE="$1"

    find "${LOCAL_LAUNCHERS_PATH}" -type f -iname "*.desktop" -print0 | while IFS= read -r -d $'\0' LAUNCHER; do
        if grep -q "^Name="${NAME_ENTRY_VALUE}"$" "${LAUNCHER}"; then
            echo "${LAUNCHER}"
            return 0
        fi
    done

    find "${GLOBAL_LAUNCHERS_PATH}" -type f -iname "*.desktop" -print0 | while IFS= read -r -d $'\0' LAUNCHER; do
        if grep -q "^Name="${NAME_ENTRY_VALUE}"$" "${LAUNCHER}"; then
            echo "${LAUNCHER}"
            return
        fi
    done

    return 1
}

set_launcher_entries() {
    FILE="${1}"
    shift

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entries: $@" >&2
        exit 1
    fi

    PAIRS_COUNT=$(($# / 2))

    if [ ! -f "${FILE}" ]; then
        return
    fi

    for I in $(seq 1 ${PAIRS_COUNT}); do
        KEY="${1}" && shift
        VAL="${1}" && shift

        if [ -n "${KEY}" ] && [ -n "${VAL}" ]; then
            set_launcher_entry "${FILE}" "${KEY}" "${VAL}"
        fi
    done
}

set_launcher_entry() {
    FILE="${1}"
    KEY="${2}"
    VAL="${3}"

    if [ "$#" != "3" ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entry: $@" >&2
    fi

    if [ ! -f "${FILE}" ]; then
        return
    fi

    if [ ! -x "${FILE}" ]; then
        chmod +x "${FILE}"
    fi

    KEY_ESC=$(echo "${KEY}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    VAL_ESC=$(echo "${VAL}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    HAS_MULTIPLE_SECTIONS=0
    LAST_SECTION_LINE=$(wc -l "${FILE}" | awk '{print $1}')

    FILE_CONTENTS=$(cat "${FILE}")

    if [ $(grep -c "^\[.*\]$" <<< "${FILE_CONTENTS}") -gt 1 ]; then
        HAS_MULTIPLE_SECTIONS=1
        LAST_SECTION_LINE=$(grep -n "^\[.*\]$" "${FILE}" | sed '2q;d' | awk -F: '{print $1}')
        FILE_CONTENTS=$(echo "${FILE_CONTENTS}" | head -n "${LAST_SECTION_LINE}")
    fi

    if [ $(grep -c "^${KEY_ESC}=${VAL}$" <<< "${FILE_CONTENTS}") == 0 ] || \
       [ $(grep -c "^${KEY_ESC}=$" <<< "${FILE_CONTENTS}") == 1 ]; then
        if [ $(grep -c "^${KEY_ESC}=.*$" <<< "${FILE_CONTENTS}") -gt 0 ]; then
            if [ -z "${VAL}" ]; then
                sed -i '1,'"${LAST_SECTION_LINE}"' {/^'"${KEY_ESC}"'=.*$/d}' "${FILE}"
            else
                sed -i '1,'"${LAST_SECTION_LINE}"' s|^'"${KEY_ESC}"'=.*$|'"${KEY_ESC}"'='"${VAL}"'|g' "${FILE}"
            fi
        elif [ -n "${VAL}" ]; then
            if [ ${HAS_MULTIPLE_SECTIONS} == 1 ]; then
                sed -i "${LAST_SECTION_LINE} i ${KEY_ESC}=${VAL_ESC}" "${FILE}"
            else
                printf "${KEY}=${VAL}\n" >> "${FILE}"
            fi
        fi

        echo "${FILE} >>> ${KEY}=${VAL}"
    fi

    if [ "${KEY_ESC}" = "Comment" ]; then
        set_launcher_entry_english "${FILE}" "Comment" "${VAL}"
    elif [ "${KEY_ESC}" = "Name" ]; then
        set_launcher_entry_english "${FILE}" "Name" "${VAL}"
        set_launcher_entry_english "${FILE}" "GenericName" "${VAL}"
        set_launcher_entry_english "${FILE}" "X-GNOME-FullName" "${VAL}"
        set_launcher_entry_english "${FILE}" "X-MATE-FullName" "${VAL}"
    elif [ "${KEY_ESC}" = "Keywords" ]; then
        set_launcher_entry_english "${FILE}" "Keywords" "${VAL}"
    elif [ "${KEY_ESC}" = "X-GNOME-FullName" ]; then
        set_launcher_entry_english "${FILE}" "X-GNOME-FullName" "${VAL}"
    elif [ "${KEY_ESC}" = "X-MATE-FullName" ]; then
        set_launcher_entry_english "${FILE}" "X-MATE-FullName" "${VAL}"
    elif [[ "${KEY_ESC}" == "Icon" ]]; then
        set_launcher_entry_english "${FILE}" "Icon" "${VAL}"
    fi

    if [ "${KEY_ESC}" = "Comment\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "Comment" "${VAL}"
    elif [ "${KEY_ESC}" = "Name\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "Name" "${VAL}"
        set_launcher_entry_romanian "${FILE}" "GenericName" "${VAL}"
        set_launcher_entry_romanian "${FILE}" "X-GNOME-FullName" "${VAL}"
        set_launcher_entry_romanian "${FILE}" "X-MATE-FullName" "${VAL}"
    elif [ "${KEY_ESC}" = "Keywords\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "Keywords" "${VAL}"
    elif [ "${KEY_ESC}" = "X-GNOME-FullName\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "X-GNOME-FullName" "${VAL}"
    elif [ "${KEY_ESC}" = "X-MATE-FullName\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "X-MATE-FullName" "${VAL}"
    elif [ "${KEY_ESC}" = "Icon\[ro\]" ]; then
        set_launcher_entry_romanian "${FILE}" "Icon" "${VAL}"
    fi
}

set_launcher_entry_romanian() {
    FILE="$1"
    KEY_ROMANIAN="$2"
    VAL="$3"

    set_launcher_entries "${FILE}" \
        "${KEY_ROMANIAN}[ro_RO]" "${VAL}" \
        "${KEY_ROMANIAN}[ro_MD]" "${VAL}"
}

set_launcher_entry_english() {
    FILE="$1"
    KEY_ENGLISH="$2"
    VAL="$3"

    set_launcher_entries "${FILE}" \
        "${KEY_ENGLISH}[en_AU]" "${VAL}" \
        "${KEY_ENGLISH}[en_CA]" "${VAL}" \
        "${KEY_ENGLISH}[en_GB]" "${VAL}" \
        "${KEY_ENGLISH}[en_US]" "${VAL}"
}

create_launcher() {
    FILE="$*"
    NAME=$(basename "${FILE}" | cut -f 1 -d '.')
    if [ ! -f "${FILE}" ]; then
        touch "${FILE}"
        printf "[Desktop Entry]\n" >> "${FILE}"
        printf "Version=1.0\n" >> "${FILE}"
        printf "NoDisplay=false\n" >> "${FILE}"
        printf "Encoding=UTF-8\n" >> "${FILE}"
        printf "Type=Application\n" >> "${FILE}"
        printf "Terminal=false\n" >> "${FILE}"
        printf "Exec=${NAME}\n" >> "${FILE}"
        printf "StartupWMClass=${NAME}\n" >> "${FILE}"

        set_launcher_entries "${FILE}" \
            Name "${NAME}" \
            Comment "${NAME}" \
            Keywords "${NAME};" \
            Icon "${NAME}"

        chmod +x "${FILE}"
        echo "Created file '${FILE}'"
    fi
}

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/7zFM.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/alltray.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/amidst.desktop" \
    StartupWMClass "amidst-Amidst"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/android-studio.desktop" StartupWMClass "jetbrains-studio"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/assistant-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/assistant.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/avahi-discover.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/balena-etcher-electron.desktop" \
    Name "Etcher" \
    Name[ro] "Etcher"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/bssh.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/bvnc.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/ca.desrt.dconf-editor.desktop" \
    Icon "dconf-editor" \
    Name "Configuration Editor" \
    Name[ro] "Editor de Configurări"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/caffeine-indicator.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/codeblocks.desktop" Name "Code::Blocks"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/cups.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/designer-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/designer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/diffuse.desktop" Name "Diffuse"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Discord.desktop" Icon "discord"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ffadomixer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/firefox-developer.desktop" Categories "Network;WebBrowser;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fluid.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/GameConqueror.desktop" Categories "Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gimp.desktop" Name "GIMP"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gimp.desktop" StartupWMClass "Gimp-2.10"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gksu-properties.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gksu.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gnome-twofactorauth.desktop" \
    Categories "GNOME;GTK;Utility;" \
    Name "Authenticator"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gnubg.desktop" \
    Name "Backgammon" \
    Name[ro] "Table"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gparted.desktop" \
    Name "Partition Editor" \
    Name[ro] "Editor de Partiții"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gtk-lshw.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gucharmap.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" \
    Categories "System;Monitor;" \
    Icon "hardinfo" \
    Name "Hardware Information" \
    Name[ro] "Informații Hardware"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/htop.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ibus-setup.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/inkscape.desktop" Name "Inkscape"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/libfm-pref-apps.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/linguist-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/linguist.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lstopo.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxhotkey-gtk.desktop" Name[ro] "Scurtături de tastatură"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/lxappearance.desktop" \
    Name "Look and Feel" \
    Name[ro] "Tema Interfeței"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/lxsession-edit.desktop" \
    Name "Desktop Session Settings" \
    Name[ro] "Opțiuni ale Sesiunilor Desktop"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/lxsession-default-apps.desktop" \
    Name "Default Applications" \
    Name[ro] "Aplicații Implicite"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxtask.desktop" Name[ro] "Manager de Activități"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-color-select.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-search-tool.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/minecraft-launcher.desktop" Name "Minecraft"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/minecraft-launcher.desktop" StartupWMClass "Minecraft* 1.16.4"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/monodevelop.desktop" Exec "env GNOME_DESKTOP_SESSION_ID="" monodevelop %F"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nfs2se.desktop" \
    Name "Need for Speed 2" \
    Icon "nfs2se" \
    StartupWMClass "nfs2se"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nm-connection-editor.desktop" \
    Name "Network Connections" \
    Name[ro] "Conexiuni de Rețea"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" \
    Name "Nvidia Settings" \
    Name[ro] "Setări Nvidia" \
    Icon "nvidia-settings" \
    Categories "System;" \
    Exec "gksu nvidia-settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/openarena-server.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Icon "gnome-settings-mouse"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Name "Mouse Settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Calendar.desktop" Categories "GNOME;GTK;Utility;Calendar;Core;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Contacts.desktop" Categories "GNOME;GTK;Utility;ContactManagement;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.DiskUtility.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Epiphany.desktop" Name "Epiphany"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Evolution.desktop" Name "Mail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Categories "Network;Feed;Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Icon "feedreader"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Name "Feed Reader"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.font-viewer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.gnome-2048.desktop" Icon "2048"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Photos.desktop" Icon "multimedia-photo-manager"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.seahorse.Application.desktop" Name[ro] "Parole și Chei"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.SoundRecorder.desktop" Categories "GNOME;GTK;Utility;Audio;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.tweaks.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.tweaks.desktop" Icon "utilities-tweak-tool"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Weather.Application.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/pavucontrol.desktop" \
    Categories "Audio;Mixer;System;GTK;" \
    Name "Audio Settings" \
    Name[ro] "Setări Audio"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/pcmanfm-desktop-pref.desktop" \
    Name "Desktop Customiser" \
    Name[ro] "Personalizare Desktop"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/PCSX2.desktop" Icon "pcsx2"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/picard.desktop" StartupWMClass ""
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/plank.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qdbusviewer-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qdbusviewer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qtconfig-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qv4l2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qvidcap.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simple-scan.desktop" Name "Scanner"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simple-scan.desktop" Name[ro] "Scanner"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simplescreenrecorder.desktop" Name "Screen Recorder"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam-native.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam-runtime.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/steam.desktop" \
    Name "Steam" \
    Name[ro] "Steam" \
    Categories "Game;Steam;" \
    Exec "steam-start"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui-small.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/system-config-printer.desktop" Name[ro] "Configurare Imprimantă"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Thunar-bulk-rename.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-bulk-rename.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-settings.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-volman-settings.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tilda.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tiled.desktop" Categories "Development;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" \
    Name "Tor" \
    Icon "tor-browser-en" \
    Categories "Network;WebBrowser;" \
    StartupWMClass "Tor Browser"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tracker-needle.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tracker-preferences.desktop" NoDisplay "true"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/transmission-gtk.desktop" \
    Name "Torrents" \
    Name[ro] "Torente"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/unity-editor.desktop" \
    Name "Unity Editor" \
    Icon "unity-editor-icon" \
    Categories "Development;IDE;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/unity-monodevelop.desktop" \
    Name "MonoDevelop - Unity" \
    Icon "unity-monodevelop" \
    Categories "Development;IDE;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vim.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/virtualbox.desktop" Name "VirtualBox"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vlc.desktop" Name "VLC"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wireshark-gtk.desktop" Name "Wireshark"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xdvi.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/yelp.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/zenmap-root.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/zenmap.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Categories "ChromeApp;Education;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Name "Duolingo"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" Categories "ChromeApp;Office;WordProcessor;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" NoDisplay "false"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-app-list.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hkgndiocipalkpejnpafdbdlfdjihomd-Default.desktop" Categories "ChromeApp;Network;FileTransfer;"
set_launcher_entries "${LOCAL_LAUNCHERS_PATH}/valve-vrmonitor.desktop" \
    Name "SteamVR Monitor" \
    NoDisplay true
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-URI-steamvr.desktop" NoDisplay true
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-URI-vrmonitor.desktop" NoDisplay true

NETFLIX_LAUNCHER=$(find_launcher_by_name "Netflix")
if [ -n "${NETFLIX_LAUNCHER}" ]; then
    set_launcher_entry "$(find_launcher_by_name Netflix)" Categories "AudioVideo;Video;Player;"
fi

########################
### ARCHIVE MANAGERS ###
########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/engrampa.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/xarchiver.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Archives" \
        Name[ro] "Arhive"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" StartupWMClass "File-Roller"

##########################
### BLUETOOTH MANAGERS ###
##########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/blueman-manager.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Bluetooth Manager" \
        Name[ro] "Manager Bluetooth"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" StartupWMClass "File-Roller"

###################
### CALCULATORS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/galculator.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-calc.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Calculator" \
        Name[ro] "Calculator"
done

##############
### CAMERA ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Cheese.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Camera" \
        Name[ro] "Cameră" \
        Icon "camera"
done

##############
### CHROME ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Chrome" \
        Name[ro] "Chrome" \
        Icon "google-chrome"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" StartupWMClass "Google-chrome-unstable"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" StartupWMClass "Google-chrome-stable"

if [ -f "${GLOBAL_LAUNCHERS_PATH}/chromium.desktop" ] && [ ! -f "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" ]; then
    set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/chromium.desktop" \
        Name "Chrome" \
        Name[ro] "Chrome" \
        Icon "google-chrome"
fi

#################
### CHAT APPS ###
#################
CHAT_APP_CATEGORIES="Network;Chat;InstantMessaging;Communication;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/whatsapp-for-linux.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/whatsapp-desktop.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/whatsie.desktop" \
                "$(find_launcher_by_name WhatsApp)"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "WhatsApp" \
        Name[ro] "WhatsApp" \
        Icon "whatsapp" \
        Categories "${CHAT_APP_CATEGORIES}"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-desktop.desktop" StartupWMClass "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier.desktop" StartupWMClass "whatsapp-nativefier-d40211"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" StartupWMClass "whatsapp-nativefier-d52542"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Categories "ChromeApp;${CHAT_APP_CATEGORIES}"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/teams.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/teams-insiders.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Teams" \
        Name[ro] "Teams" \
        Icon "teams" \
        Categories "${CHAT_APP_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/telegramdesktop.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Telegram" \
        Name[ro] "Telegram" \
        Categories "Qt;${CHAT_APP_CATEGORIES};"
done

##############
### CITRIX ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/configmgr.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/conncentre.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/wfcmgr.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Icon "citrix-receiver" \
        NoDisplay true
done

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/configmgr.desktop" \
    Name "Citrix Receiver Preferences" \
    Name[ro] "Configurare Receptor Citrix" \
    StartupWMClass "Configmgr"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/conncentre.desktop" \
    Name "Citrix Connection Centre" \
    Name[ro] "Centrul de conexiuni Citrix" \
    StartupWMClass "Conncenter"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/wfcmgr.desktop" \
    Name "Citrix Receiver Self Service" \
    Name[ro] "Asistență Receptor Citrix" \
    StartupWMClass "Wfcmgr"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop" \
    Name "Citrix Receiver" \
    Name[ro] "Receptor Citrix" \
    StartupWMClass "Wfica"

#############
### CMAKE ###
#############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/cmake.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/cmake-gui.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/CMake.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Icon "cmake" \
        NoDisplay "true"
done

####################
### DICTIONARIES ###
####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/mate-dictionary.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Dictionary" \
        Name[ro] "Dicționar"
done

############################
### DISK USAGE ANALYZERS ###
############################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/baobab.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-disk-usage-analyzer.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Disk Usage" \
        Name[ro] "Ocuparea Spațiului" \
        OnlyShowIn ""
done

######################
### DISK UTILITIES ###
######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gnome-disks.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-disk.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name[ro] "Discuri" \
        Icon "gnome-disks"
done

########################
### DOCUMENT VIEWERS ###
########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/epdfview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/evince.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Documents" \
        Name[ro] "Documente"
done

################
### DOSBOX ###
################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/dosbox.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "Application;Emulator;" \
        Name "DosBox"
done

################
### ELECTRON ###
################
for ELECTRON_VERSION in "" {1..16}; do
    LAUNCHER="${GLOBAL_LAUNCHERS_PATH}/electron${ELECTRON_VERSION}.desktop"
    set_launcher_entries "${LAUNCHER}" \
        NoDisplay "true"
done

#####################
### FILE MANAGERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/caja-browser.dekstop" \
                "${GLOBAL_LAUNCHERS_PATH}/io.elementary.files.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Nautilus.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/pcmanfm.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Files" \
        Name[ro] "Fișiere" \
        Categories "Utility;Core;FileManager;"
done

###################
### GOOGLE KEEP ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" \
                "$${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Keep" \
        Name[ro] "Keep" \
        Icon "google-keep" \
        Categories "Utility;" \
        NoDisplay false
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" StartupWMClass "google-keep-nativefier-d04d04"

#####################
### GOOGLE PHOTOS ###
#####################
for LAUNCHER in "$(find_launcher_by_name \"Google Photos\")"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Photos" \
        Name[ro] "Fotografii" \
        Categories "Network;Utility;Photography;"
done

#####################
### IMAGE VIEWERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gpicview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eog.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eom.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Images" \
        Name[ro] "Imagini"
done

#################
### JRE & JDK ###
#################
for JAVA_VERSION in {8..24}; do
    for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/policytool-jre${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre${JAVA_VERSION}.desktop" \
                    "${GLOBAL_LAUNCHERS_PATH}/sun_javaws-jre${JAVA_VERSION}.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Icon "java" \
            NoDisplay "true"
    done
done

###################
### LOG VIEWERS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/mate-system-log.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Logs.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Logs" \
        Name[ro] "Loguri" \
        OnlyShowIn ""
done

############
### MAPS ###
############
MAPS_APP_CATEGORIES="Network;Utility;Navigation;"
for LAUNCHER in "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Maps.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Maps" \
        Name[ro] "Hărți" \
        Categories "${MAPS_APP_CATEGORIES}" \
        NoDisplay "false"
done
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Categories "ChromeApp;${MAPS_APP_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Maps.desktop" Categories "GNOME;GTK;${MAPS_APP_CATEGORIES}"

################
### MONOGAME ###
################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/Monogame\ Pipeline.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/MonogamePipeline.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        NoDisplay "true" \
        StartupWMClass "Pipeline"
done

####################
### MUSIC PLAYER ###
####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/lxmusic.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Music" \
        Name[ro] "Muzică" \
        MimeType "application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/vorbis;audio/x-vorbis;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-mpegurl;audio/x-flac;audio/mp4;x-scheme-handler/itms;x-scheme-handler/itmss;"
done

############
### PLEX ###
############
for LAUNCHER in "${LOCAL_LAUNCHERS_PATH}/chrome-aghlkjcflkcaanjmefomlcfgflfdhkkg-Default.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Plex" \
        Name[ro] "Plex" \
        Icon "plexhometheater" \
        Categories "AudioVideo;Audio;Video;Player;" \
        StartupWMClass "crx_aghlkjcflkcaanjmefomlcfgflfdhkkg"
done

###############
### POSTMAN ###
###############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/postman.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Icon "postman" \
        Categories "Development;"
done

##############
### PYTHON ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/ipython.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/ipython2.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "Development;" \
        NoDisplay "true" \
        Icon "ipython"
done

######################
### SCREENSHOOTERS ###
######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gscreenshot.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-screenshot.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Screenshot.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Screenshot" \
        Name[ro] "Captură de Ecran" \
        Icon "applets-screenshooter" \
        OnlyShowIn ""
done
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gscreenshot.desktop" \
    Categories "Utility;" \
    StartupWMClass "gscreenshot"

#######################
### SYSTEM MONITORS ###
#######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gnome-system-monitor.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-system-monitor.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "System Monitor" \
        Name[ro] "Monitor de Sistem"
done

###################
### TEAM VIEWER ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/com.teamviewer.TeamViewer.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/teamviewer.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "TeamViewer" \
        Name[ro] "TeamViewer" \
        Icon "teamviewer" \
        Categories "Network;RemoteAccess;FileTransfer;" \
        StartupWMClass "TeamViewer"
done

#################
### TERMINALS ###
#################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gnome-terminal.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/lxterminal.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-terminal.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Terminal" \
        Name[ro] "Terminal"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xterm.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/uxterm.desktop" NoDisplay "true"

####################
### TEXT EDITORS ###
####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gedit.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/io.elementary.code.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/leafpad.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.gedit.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.pantheon.scratch.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/medit.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/pluma.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Text Editor" \
        Name[ro] "Editor Text" \
        Icon "accessories-text-editor"
done

###############
### VS CODE ###
###############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/code.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Code" \
        Name[ro] "Code" \
        Icon "code" \
        Keywords "VS;VSCode;Visual;Studio;Code;" \
        Categories "Development;IDE;TextEditor;"
done
[ "${ARCH_FAMILY}" == "x86" ] && set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "code"
[ "${ARCH_FAMILY}" == "arm" ] && set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "Code - OSS (headmelted)"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss-url-handler.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code.desktop" StartupWMClass "code-oss"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop" StartupWMClass "Code"

rm -rf "${HOME_REAL}/.local/share/applications/wine-*"
rm -rf "${HOME_REAL}/.local/share/applications/wine"
rm -rf "${HOME_REAL}/.config/menus/applications-merged/user-chrome-apps.menu"

# CREATE ICONS

if [ -f "/usr/bin/wine" ]; then
    if [ ! -f "winecfg.desktop" ]; then
        create_launcher "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop"
        set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop" Name "Wine Configuration"
        set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop" Categories "Wine;Emulator;System;Settings;"
        set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop" StartupWMClass "winecfg.exe"
    fi
fi

if [ -f "/usr/bin/winetricks" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/winetricks.desktop"

    if [ ! -f "winetricks.desktop" ]; then
        create_launcher "${NEWLAUNCHER}"
    fi

    set_launcher_entry "${NEWLAUNCHER}" Name "Winetricks"
    set_launcher_entry "${NEWLAUNCHER}" Icon "winetricks"
    set_launcher_entry "${NEWLAUNCHER}" Categories "Wine;Emulator;"
    set_launcher_entry "${NEWLAUNCHER}" StartupWMClass "winetricks"
    set_launcher_entry "${NEWLAUNCHER}" NoDisplay "true"
fi

if [ -f "/usr/bin/java" ] || [ -L "/usr/bin/java" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/run-java.desktop"

    if [ ! -f "${NEWLAUNCHER}" ]; then
        create_launcher "${NEWLAUNCHER}"
    fi

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Java" \
        Icon "java" \
        Exec "java -jar %U" \
        Terminal "true" \
        NoDisplay "true"
fi

if [ -f "/usr/bin/mono" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/run-mono.desktop"

    if [ ! -f "${NEWLAUNCHER}" ]; then
        create_launcher "${NEWLAUNCHER}"
    fi

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Mono" \
        Icon "mono" \
        Exec "mono %U" \
        Terminal "true" \
        NoDisplay "true"
fi

if [ -f "/usr/bin/steam" ]; then
    LAUNCHER_FILE_NAME="steam-streaming-client.desktop"
    LAUNCHER_FILE_PATH="${GLOBAL_LAUNCHERS_PATH}/${LAUNCHER_FILE_NAME}"

    if [ ! -f "steam-streaming-client.desktop" ]; then
        create_launcher "${LAUNCHER_FILE_PATH}"
    fi

    set_launcher_entry "${LAUNCHER_FILE_PATH}" Name "Streaming Client"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" Comment "Steam Streaming Client"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" Exec "steam"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" Icon "steam"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" Categories "Game;Steam;"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" StartupWMClass "streaming_client"
    set_launcher_entry "${LAUNCHER_FILE_PATH}" NoDisplay "true"
fi

if [ -d "/opt/android-studio" ]; then
    if [ ! -f "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" ]; then
        create_launcher "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop"
    fi

    if [ ! -f "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop" ]; then
        create_launcher "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop"
    fi

    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" Name "Android SDK Manager"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" Exec ${HOME_REAL}"\/Android\/Sdk\/tools\/android sdk"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" Categories "Development;"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" StartupWMClass "Android SDK Manager"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" Icon "android-sdk"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-sdk-manager.desktop" NoDisplay "true"

    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop" Name "Android Virtual Device Manager"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop" Exec ${HOME_REAL}"\/Android\/Sdk\/tools\/android avd"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop" Categories "Emulator;"
    set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/android-avd-manager.desktop" Icon "android-sdk"
fi

# CREATE STEAM ICONS

if [ -f "/usr/bin/steam" ]; then
    STEAM_PATH="${HOME_REAL}/.local/share/Steam"
    STEAM_LAUNCHERS_PATH="${LOCAL_LAUNCHERS_PATH}/Steam"
    STEAM_ICON_THEME_PATH="${HOME_REAL}/.local/share/icons/steam"
    STEAM_LIBRARY_PATHS="${STEAM_PATH}/steamapps"
    STEAM_LIBRARY_CUSTOM_PATHS=$(cat "${STEAM_PATH}/steamapps/libraryfolders.vdf" | grep "\"/")
    STEAM_WMCLASSES_FILE="data/steam-wmclasses.txt"
    STEAM_NAMES_FILE="data/steam-names.txt"

    if [ -n "${STEAM_LIBRARY_CUSTOM_PATHS}" ]; then
        STEAM_LIBRARY_CUSTOM_PATHS=$(echo ${STEAM_LIBRARY_CUSTOM_PATHS} | sed 's/\"[0-9]\"//g' | sed 's/^ *//g' | sed 's/\t//g' | sed 's/\"//g')$(echo "/steamapps/")
        STEAM_LIBRARY_PATHS=$(printf "${STEAM_LIBRARY_PATHS}\n${STEAM_LIBRARY_CUSTOM_PATHS}")
    fi

    [ ! -d "${STEAM_LAUNCHERS_PATH}" ]              && mkdir -p "${STEAM_LAUNCHERS_PATH}"
    [ ! -f "${STEAM_ICON_THEME_PATH}/48x48/apps" ]  && mkdir -p "${STEAM_ICON_THEME_PATH}/48x48/apps"

    for STEAM_APP_LAUNCHER in ${STEAM_LAUNCHERS_PATH}/* ; do
        APP_ID=$(cat "${STEAM_APP_LAUNCHER}" | grep "^Exec" | awk -F/ '{print $4}')
        IS_APP_INSTALLED="false"

        for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
            if [ -f "${STEAM_LIBRARY_PATH}/appmanifest_${APP_ID}.acf" ]; then
                IS_APP_INSTALLED="true"
                break
            fi
        done

        if [ "${IS_APP_INSTALLED}" == "true" ]; then
            set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" NoDisplay "false"
        else
            set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" NoDisplay "true"
        fi

        SOURCE_ICON_PATH="${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"
        TARGET_ICON_PATH="${STEAM_PATH}/appcache/librarycache/${APP_ID}_icon.jpg"
        if [ -f "${SOURCE_ICON_PATH}" ] && [ ! -f "${TARGET_ICON_PATH}" ]; then
            echo "Copying icon for Steam AppID ${APP_ID} into the Steam icon pack..."
            cp "${SOURCE_ICON_PATH}" "${TARGET_ICON_PATH}"
        fi
    done

    for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
        if [ -d "${STEAM_LIBRARY_PATH}" ] && [ -d "${ICON_THEME_PATH}" ]; then
            [ ! -f "${STEAM_WMCLASSES_FILE}" ]  && touch "${STEAM_WMCLASSES_FILE}"
            [ ! -f "${STEAM_NAMES_FILE}" ]      && touch "${STEAM_NAMES_FILE}"

            APP_IDS=$(ls "${STEAM_LIBRARY_PATH}" | grep "appmanifest_.*.acf" | awk -F_ '{print $2}' | awk -F. '{print $1}')
            APPS_DIR_NAME="48/apps"

            if [ ! -d "${ICON_THEME_PATH}/48" ]; then
                APPS_DIR_NAME="48x48/apps"
            fi

            for APP_ID in ${APP_IDS}; do
                APP_ICON_PATH="${ICON_THEME_PATH}/${APPS_DIR_NAME}/steam_icon_${APP_ID}.svg"

                if [ ! -f "${APP_ICON_PATH}" ]; then
                    APP_ICON_PATH="${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"

                    for ICON_THEME_CANDIDATE in $(ls "/usr/share/icons/") ; do
                        ICON_THEME_CANDIDATE_PATH="/usr/share/icons/"${ICON_THEME_CANDIDATE}

                        if [ -d "${ICON_THEME_CANDIDATE_PATH}/48/apps" ]; then
                            APPS_DIR_NAME="48/apps"
                        elif [ -d "${ICON_THEME_CANDIDATE_PATH}/48x48/apps" ]; then
                            APPS_DIR_NAME="48x48/apps"
                        else
                            continue
                        fi

                        APP_ICON_PATH_CANDIDATE=$(find "${ICON_THEME_CANDIDATE_PATH}/${APPS_DIR_NAME}" -type f,l -iname "steam_icon_${APP_ID}.*" -exec readlink -f {} +)
                        if [ -f "${APP_ICON_PATH_CANDIDATE}" ]; then
                            APP_ICON_PATH=${APP_ICON_PATH_CANDIDATE}
                            break
                        fi
                    done

                    if [ ! -f "${APP_ICON_PATH}" ]; then
                        APP_ICON_PATH="steam_icon_${APP_ID}"
                    fi
                fi

                APP_NAME=$(grep -h "\"name\"" "${STEAM_LIBRARY_PATH}/appmanifest_${APP_ID}.acf" | sed 's/\"name\"//' | grep -o "\".*\"" | sed 's/\"//g')

                if [ $(grep -c "^${APP_ID}=" "${STEAM_NAMES_FILE}") -ne 0 ]; then
                    APP_NAME=$(grep "^${APP_ID}=" "${STEAM_NAMES_FILE}" | awk -F= '{print $2}')
                fi

                DO_CREATE_LAUNCHER="true"

                if [[ "${APP_NAME}" == "Steamworks Common Redistributables" ]] || \
                   [[ "${APP_NAME}" =~ ^Proton\ [0-9]+\.[0-9]+$ ]] || \
                   [[ ${APP_NAME} == "Steam Linux Runtime*" ]]; then
                    DO_CREATE_LAUNCHER="false"
                fi

                if [ "${DO_CREATE_LAUNCHER}" == "true" ]; then
                    APP_WMCLASS=""

                    if [ $(grep -c "^${APP_ID}=" "${STEAM_WMCLASSES_FILE}") -ne 0 ]; then
                        APP_WMCLASS=$(grep "^${APP_ID}=" "${STEAM_WMCLASSES_FILE}" | awk -F= '{print $2}')
                    else
                        APP_WMCLASS=$(echo "${APP_NAME}" | sed 's/\ //g')
                        echo "CANNOT GET WMCLASS FOR STEAMAPP ${APP_ID} - ${APP_NAME}"
                    fi

                    create_launcher "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop"
                    set_launcher_entries "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" \
                        Name "${APP_NAME}" \
                        Comment "Play ${APP_NAME} on Steam" \
                        Comment[ro] "Joacă ${APP_NAME} pe Steam" \
                        Keywords "Game;Steam;${APP_ID};" \
                        Keywords[ro] "Joc;Steam;${APP_ID};" \
                        Exec "steam steam:\/\/rungameid\/${APP_ID}" \
                        Icon "${APP_ICON_PATH}" \
                        Categories "Game;Steam;" \
                        StartupWMClass "${APP_WMCLASS}" \
                        NoDisplay false
                fi
            done

            chown -R "${USER_REAL}" "${STEAM_LAUNCHERS_PATH}"
        fi
    done
fi

# Rebuild icon theme caches
ICON_THEMES=$(find "/usr/share/icons/" -mindepth 1 -type d)

for ICON_THEME in ${ICON_THEMES}; do
    if [ -f "/usr/share/icons/${ICON_THEMES}/index.theme" ]; then
        gtk-update-icon-cache "/usr/share/icons/${ICON_THEME}"
    fi
done

update-desktop-database
update-desktop-database "${LOCAL_LAUNCHERS_PATH}"
