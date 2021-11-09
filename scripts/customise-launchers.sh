#!/bin/bash
source "scripts/common/common.sh"

(! ${HAS_GUI}) && exit

GLOBAL_LAUNCHERS_PATH="${ROOT_USR_SHARE}/applications"
LOCAL_LAUNCHERS_PATH="${HOME_REAL}/.local/share/applications"

ICON_THEME=$(sudo -u "${USER_REAL}" -H gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
ICON_THEME_PATH="${ROOT_USR_SHARE}/icons/${ICON_THEME}"

function find_launcher_by_name() {
    local NAME_ENTRY_VALUE="$1"

    if [ -d "${LOCAL_LAUNCHERS_PATH}" ]; then
        find "${LOCAL_LAUNCHERS_PATH}" -type f -iname "*.desktop" -print0 | while IFS= read -r -d $'\0' LAUNCHER; do
            if grep -q "^Name="${NAME_ENTRY_VALUE}"$" "${LAUNCHER}"; then
                echo "${LAUNCHER}"
                return 0
            fi
        done
    fi

    find "${GLOBAL_LAUNCHERS_PATH}" -type f -iname "*.desktop" -print0 | while IFS= read -r -d $'\0' LAUNCHER; do
        if grep -q "^Name="${NAME_ENTRY_VALUE}"$" "${LAUNCHER}"; then
            echo "${LAUNCHER}"
            return
        fi
    done

    return 1
}

function set_launcher_entries() {
    local FILE="${1}"
    shift

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entries: ${*}" >&2
        exit 1
    fi

    local PAIRS_COUNT=$(($# / 2))

    if [ ! -f "${FILE}" ]; then
        return
    fi

    for I in $(seq 1 ${PAIRS_COUNT}); do
        local KEY="${1}" && shift
        local VAL="${1}" && shift

        if [ -n "${KEY}" ] && [ -n "${VAL}" ]; then
            set_launcher_entry "${FILE}" "${KEY}" "${VAL}"
        fi
    done
}

function set_launcher_entry() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${@:3}"

    if [ "$#" != "3" ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entry: ${*}" >&2
    fi

    if [ ! -f "${FILE}" ]; then
        return
    fi

    if [ ! -x "${FILE}" ]; then
        chmod +x "${FILE}"
    fi

    local KEY_ESC=$(echo "${KEY}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    local VAL_ESC=$(echo "${VAL}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    local HAS_MULTIPLE_SECTIONS=false
    local LAST_SECTION_LINE=$(wc -l "${FILE}" | awk '{print $1}')

    local FILE_CONTENTS=$(cat "${FILE}")

    if [ $(grep -c "^\[.*\]$" <<< "${FILE_CONTENTS}") -gt 1 ]; then
        HAS_MULTIPLE_SECTIONS=true
        LAST_SECTION_LINE=$(grep -n "^\[.*\]$" "${FILE}" | sed '2q;d' | awk -F: '{print $1}')
        FILE_CONTENTS=$(echo "${FILE_CONTENTS}" | head -n "${LAST_SECTION_LINE}")
    fi

    if [[ $(grep -c "^${KEY_ESC}=${VAL}$" <<< "${FILE_CONTENTS}") == 0 ]] || \
       [[ $(grep -c "^${KEY_ESC}=$" <<< "${FILE_CONTENTS}") == 1 ]]; then
        if [ $(grep -c "^${KEY_ESC}=.*$" <<< "${FILE_CONTENTS}") -gt 0 ]; then
            if [ -z "${VAL}" ]; then
                sed -i '1,'"${LAST_SECTION_LINE}"' {/^'"${KEY_ESC}"'=.*$/d}' "${FILE}"
            else
                sed -i '1,'"${LAST_SECTION_LINE}"' s|^'"${KEY_ESC}"'=.*$|'"${KEY_ESC}"'='"${VAL}"'|g' "${FILE}"
            fi
        elif [ -n "${VAL}" ]; then
            if ${HAS_MULTIPLE_SECTIONS}; then
                sed -i "${LAST_SECTION_LINE} i ${KEY_ESC}=${VAL_ESC}" "${FILE}"
            else
                printf "${KEY}=${VAL}\n" >> "${FILE}"
            fi
        fi

        echo "${FILE} >>> ${KEY}=${VAL}"
    fi

    KEY_ID=$(echo "${KEY}" | sed 's/^\([^\[]*\).*/\1/g')
    KEY_LANGUAGE=$(echo "${KEY}" | sed 's/^[^\[]*\[\([a-zA-Z_]*\)]/\1/g')

    if [[ "${KEY_LANGUAGE}" == "en" ]]; then
        if [[ "${KEY_ID}" == "Name" ]]; then
            set_launcher_entry_english "${FILE}" "Name" "${VAL}"
            set_launcher_entry_english "${FILE}" "GenericName" "${VAL}"
            set_launcher_entry_english "${FILE}" "X-GNOME-FullName" "${VAL}"
            set_launcher_entry_english "${FILE}" "X-MATE-FullName" "${VAL}"
        else
            set_launcher_entry_english "${FILE}" "${KEY_ID}" "${VAL}"
        fi
    elif [[ "${KEY_LANGUAGE}" == "es" ]]; then
        if [[ "${KEY_ID}" == "Name" ]]; then
            set_launcher_entry_spanish "${FILE}" "Name" "${VAL}"
            set_launcher_entry_spanish "${FILE}" "GenericName" "${VAL}"
            set_launcher_entry_spanish "${FILE}" "X-GNOME-FullName" "${VAL}"
            set_launcher_entry_spanish "${FILE}" "X-MATE-FullName" "${VAL}"
        else
            set_launcher_entry_spanish "${FILE}" "${KEY_ID}" "${VAL}"
        fi
    elif [[ "${KEY_LANGUAGE}" == "ro" ]]; then
        if [[ "${KEY_ID}" == "Name" ]]; then
            set_launcher_entry_romanian "${FILE}" "Name" "${VAL}"
            set_launcher_entry_romanian "${FILE}" "GenericName" "${VAL}"
            set_launcher_entry_romanian "${FILE}" "X-GNOME-FullName" "${VAL}"
            set_launcher_entry_romanian "${FILE}" "X-MATE-FullName" "${VAL}"
        else
            set_launcher_entry_romanian "${FILE}" "${KEY_ID}" "${VAL}"
        fi
    fi
}

function set_launcher_entry_english() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${@:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[en_AU]" "${VAL}" \
        "${KEY}[en_CA]" "${VAL}" \
        "${KEY}[en_GB]" "${VAL}" \
        "${KEY}[en_NZ]" "${VAL}" \
        "${KEY}[en_US]" "${VAL}" \
        "${KEY}[en_ZA]" "${VAL}"
}
function set_launcher_entry_romanian() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${@:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[ro_RO]" "${VAL}" \
        "${KEY}[ro_MD]" "${VAL}"
}
function set_launcher_entry_spanish() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${@:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[es_AR]" "${VAL}" \
        "${KEY}[es_CL]" "${VAL}" \
        "${KEY}[es_ES]" "${VAL}" \
        "${KEY}[es_MX]" "${VAL}"
}

function create_launcher() {
    local FILE_PATH="$*"
    local NAME=$(basename "${FILE_PATH}" | cut -f 1 -d '.')

    if [ ! -f "${FILE_PATH}" ]; then
        {
            echo "[Desktop Entry]"
            echo "Version=1.0"
            echo "NoDisplay=false"
            echo "Encoding=UTF-8"
            echo "Type=Application"
            echo "Terminal=false"
            echo "Exec=${NAME}"
            echo "StartupWMClass=${NAME}"
            echo "Name=${NAME}"
            echo "Comment=${NAME}"
            echo "Keywords=${NAME}"
            echo "Icon=${NAME}"
        } > "${FILE_PATH}"

        chmod +x "${FILE_PATH}"
        echo "Created file '${FILE_PATH}'"
    fi
}

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/amidst.desktop" \
    StartupWMClass "amidst-Amidst"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/cups.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/GameConqueror.desktop" Categories "Utility;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gnubg.desktop" \
    Name "Backgammon" \
    Name[ro] "Table"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gparted.desktop" \
    Name "Partition Editor" \
    Name[ro] "Editor de Partiții"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gtk-lshw.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" \
    Categories "System;Monitor;" \
    Icon "hardinfo" \
    Name "Hardware Information" \
    Name[ro] "Informații Hardware"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lstopo.desktop" NoDisplay true
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
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-color-select.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-search-tool.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nfs2se.desktop" \
    Name "Need for Speed 2" \
    Icon "nfs2se" \
    StartupWMClass "nfs2se"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nm-connection-editor.desktop" \
    Name "Network Connections" \
    Name[ro] "Conexiuni de Rețea" \
    NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/openarena-server.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" \
    Name "Mouse Settings" \
    Icon "gnome-settings-mouse" \
    Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Contacts.desktop" Categories "GNOME;GTK;Utility;ContactManagement;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.DiskUtility.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Epiphany.desktop" Name "Epiphany"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.font-viewer.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.gnome-2048.desktop" Icon "2048"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.SoundRecorder.desktop" Categories "GNOME;GTK;Utility;Audio;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.gnome.tweaks.desktop" \
    Icon "utilities-tweak-tool" \
    Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Weather.Application.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/pavucontrol.desktop" \
    Categories "GTK;System;Audio;Mixer;" \
    Name "Audio Settings" \
    Name[ro] "Setări Audio"
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/pcmanfm-desktop-pref.desktop" \
    Name "Desktop Customiser" \
    Name[ro] "Personalizare Desktop"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/picard.desktop" StartupWMClass ""
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/plank.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qv4l2.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qvidcap.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/simple-scan.desktop" \
    Name "Scanner" \
    Name[ro] "Scanner"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simplescreenrecorder.desktop" Name "Screen Recorder"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui-small.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/system-config-printer.desktop" Name[ro] "Configurare Imprimantă"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/virtualbox.desktop" Name "VirtualBox"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vlc.desktop" Name "VLC"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wireshark-gtk.desktop" Name "Wireshark"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-app-list.desktop" NoDisplay true
set_launcher_entry "$(find_launcher_by_name Netflix)" Categories "AudioVideo;Video;Player;"

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
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/7zFM.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" StartupWMClass "File-Roller"

#############
### AVAHI ###
#############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/avahi-discover.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/bssh.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/bvnc.desktop"; do
    set_launcher_entry "${LAUNCHER}.desktop" NoDisplay true
done

##########################
### BLUETOOTH MANAGERS ###
##########################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/blueman-manager.desktop" \
    Name "Bluetooth Manager" \
    Name[ro] "Manager Bluetooth"

############################
### BOOTABLE MEDIA MAKER ###
############################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/balena-etcher-electron.desktop" \
    Name "Etcher" \
    Name[ro] "Etcher" \
    Categories "Filesystem;X-GNOME-Utilities;"

###################
### CALCULATORS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/galculator.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-calc.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Calculator" \
        Name[ro] "Calculator"
done

################
### Calendar ###
################
CALENDAR_CATEGORIES="Office;Calendar;Utility;Core;"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Calendar.desktop" \
    Name "Calendar" \
    Name[ro] "Calendar" \
    Icon "calendar" \
    Categories "GNOME;GTK;${CALENDAR_CATEGORIES}"

##############
### CAMERA ###
##############
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Cheese.desktop" \
    Name "Camera" \
    Name[ro] "Cameră" \
    Icon "camera"

#################
### CHAT APPS ###
#################
CHAT_APP_CATEGORIES="Network;Chat;InstantMessaging;Communication;"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/discord.desktop" \
    Icon "discord" \
    Categories "${CHAT_APP_CATEGORIES}"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/teams.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/teams-insiders.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Teams" \
        Name[ro] "Teams" \
        Icon "teams" \
        Categories "${CHAT_APP_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/meowgram.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/telegramdesktop.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Telegram" \
        Name[ro] "Telegram"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/meowgram.desktop" Categories "GTK;${CHAT_APP_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/telegramdesktop.desktop" Categories "Qt;${CHAT_APP_CATEGORIES}"

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

##############
### CITRIX ###
##############

if [ -d "${ROOT_OPT}/Citrix" ]; then
    if [ ! -f "${GLOBAL_LAUNCHERS_PATH}wfsplash.desktop" ]; then
        create_launcher "${GLOBAL_LAUNCHERS_PATH}/wfsplash.desktop"
    fi
fi

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/configmgr.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/conncentre.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/wfcmgr.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/wfsplash.desktop" \
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
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/wfsplash.desktop" \
    Name "Citrix Splash" \
    Categories "Application;Network;X-Red-Hat-Base;X-SuSE-Core-Internet;" \
    StartupWMClass "Wfica_Splash" # InitPanel_popup
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
        NoDisplay true
done

################################
### DEVELOPMENT ENVIRONMENTS ###
################################
DEVELOPMENT_ENVIRONMENT_CATEGORIES="Development;IDE;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/code.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Code" \
        Name[ro] "Code" \
        Icon "code" \
        Keywords "VS;VSCode;Visual;Studio;Code;" \
        Categories "${DEVELOPMENT_ENVIRONMENT_CATEGORIES};TextEditor;"
done

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/monodevelop.desktop" \
    Exec "env GNOME_DESKTOP_SESSION_ID="" monodevelop %F" \
    Categories ${DEVELOPMENT_ENVIRONMENT_CATEGORIES}

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/unity-editor.desktop" \
    Name "Unity Editor" \
    Icon "unity-editor-icon" \
    Categories ${DEVELOPMENT_ENVIRONMENT_CATEGORIES}

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/unity-monodevelop.desktop" \
    Name "MonoDevelop - Unity" \
    Icon "unity-monodevelop" \
    Categories ${DEVELOPMENT_ENVIRONMENT_CATEGORIES}

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/codeblocks.desktop" \
    Name "Code::Blocks" \
    Categories "GTK;${DEVELOPMENT_ENVIRONMENT_CATEGORIES}"

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/android-studio.desktop" \
    StartupWMClass "jetbrains-studio"

if [[ "${ARCH_FAMILY}" == "x86" ]]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "code"
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss-url-handler.desktop" NoDisplay true
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code.desktop" StartupWMClass "code-oss"
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop" StartupWMClass "Code"
elif [[ "${ARCH_FAMILY}" == "arm" ]]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "Code - OSS (headmelted)"
fi

####################
### DICTIONARIES ###
####################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/mate-dictionary.desktop" \
    Name "Dictionary" \
    Name[ro] "Dicționar"

############################
### DISK USAGE ANALYZERS ###
############################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/baobab.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-disk-usage-analyzer.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.baobab.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Disk Usage" \
        Name[ro] "Utilizarea Discului" \
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
DOCUMENT_VIEWER_CATEGORIES="Office;Viewer;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/epdfview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/evince.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Evince.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Documents" \
        Name[ro] "Documente"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/epdfview.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GTK;${DOCUMENT_VIEWER_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/evince.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Evince.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GNOME;GTK;${DOCUMENT_VIEWER_CATEGORIES}"
done

################
### ELECTRON ###
################
for ELECTRON_VERSION in "" {1..16}; do
    LAUNCHER="${GLOBAL_LAUNCHERS_PATH}/electron${ELECTRON_VERSION}.desktop"
    set_launcher_entries "${LAUNCHER}" \
        NoDisplay true
done

#################
### EMULATORS ###
#################
EMULATOR_CATEGORIES="Game;Application;Emulator;"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/dosbox.desktop" \
    Name "DosBox" \
    Categories ${EMULATOR_CATEGORIES}

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/PCSX2.desktop" \
    Icon "pcsx2" \
    Categories ${EMULATOR_CATEGORIES}

##########################
### EXTENSION MANAGERS ###
##########################
EXTENSION_MANAGER_CATEGORIES="System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Extensions.desktop" Categories "GNOME;GTK;${EXTENSION_MANAGER_CATEGORIES}"

####################
### FEED READERS ###
####################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.dekstop" \
    Name "Feed Reader" \
    Icon "feedreader" \
    Categories "GNOME;GTK;Network;Feed;Utility;"

#####################
### FILE MANAGERS ###
#####################
FILE_MANAGER_CATEGORIES="Utility;Core;FileManager;FileTools;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/caja-browser.dekstop" \
                "${GLOBAL_LAUNCHERS_PATH}/io.elementary.files.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Nautilus.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/pcmanfm.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Files" \
        Name[ro] "Fișiere"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/caja.dekstop" \
                "${GLOBAL_LAUNCHERS_PATH}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/pcmanfm.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GTK;${FILE_MANAGER_CATEGORIES}"
done

set_launcher_entry "${GLOBAL_LAUNCHER_PATH}/io.elementary.files.desktop" Categories "Pantheon;GTK;${FILE_MANAGER_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHER_PATH}/org.gnome.Nautilus.desktop" Categories "GNOME;GTK;${FILE_MANAGER_CATEGORIES}"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/Thunar-bulk-rename.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar-bulk-rename.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar-settings.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar-volman-settings.desktop"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

#####################
### IMAGE EDITORS ###
#####################
IMAGE_EDITOR_CATEGORIES="Graphics;2DGraphics"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gimp.desktop" \
    Name "GIMP" \
    Categories "GTK;${IMAGE_EDITOR_CATEGORIES};RasterGraphics;" \
    StartupWMClass "Gimp-2.10"

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/inkscape.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.inkscape.Inkscape.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Inkscape" \
        Categories "GTK;${IMAGE_EDITOR_CATEGORIES};VectorGraphics;"
done

#####################
### IMAGE VIEWERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gpicview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eog.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eom.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.eog.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Images" \
        Name[ro] "Imagini"
done

#########################
### INTERNET BROWSERS ###
#########################
INTERNET_BROWSER_CATEGORIES="Network;WebBrowser;"

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/firefox-developer.desktop" Categories ${INTERNET_BROWSER_CATEGORIES}

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Chrome" \
        Name[ro] "Chrome" \
        Icon "google-chrome"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" StartupWMClass "Google-chrome-unstable"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" StartupWMClass "Google-chrome-stable"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" \
    Name "Tor" \
    Icon "tor-browser-en" \
    Categories ${INTERNET_BROWSER_CATEGORIES} \
    StartupWMClass "Tor Browser"

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
            NoDisplay true
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

####################
### MAIL CLIENTS ###
####################
MAIL_APP_CATEGORIES="Network;Email;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/electron-mail.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Evolution.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Mail" \
        Name[ro] "Mail" \
        Categories "${MAIL_APP_CATEGORIES}" \
        NoDisplay "false"
done

############
### MAPS ###
############
MAPS_APP_CATEGORIES="Utility;Navigation;"
for LAUNCHER in "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Maps.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Maps" \
        Name[ro] "Hărți" \
        NoDisplay "false"
done
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Categories "ChromeApp;${MAPS_APP_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Maps.desktop" Categories "GNOME;GTK;${MAPS_APP_CATEGORIES}"

#################
### MINECRAFT ###
#################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/minecraft-launcher.desktop" \
    Name "Minecraft" \
    StartupWMClass "Minecraft 1.17.1"

################
### MONOGAME ###
################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/Monogame\ Pipeline.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/MonogamePipeline.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        NoDisplay true \
        StartupWMClass "Pipeline"
done

####################
### MUSIC PLAYER ###
####################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/lxmusic.desktop" \
    Name "Music" \
    Name[ro] "Muzică" \
    MimeType "application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/vorbis;audio/x-vorbis;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-mpegurl;audio/x-flac;audio/mp4;x-scheme-handler/itms;x-scheme-handler/itmss;"

#################
### NOTE APPS ###
#################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" \
                "${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Keep" \
        Name[ro] "Keep" \
        Icon "google-keep" \
        Categories "Utility;" \
        NoDisplay false
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" StartupWMClass "google-keep-nativefier-d04d04"

##############
### NVIDIA ###
##############
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" \
    Name "Nvidia Settings" \
    Name[ro] "Setări Nvidia" \
    Icon "nvidia-settings" \
    Categories "System;"

if [ -f "${ROOT_USR_BIN}/optirun" ]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" Exec "optirun -b none nvidia-settings -c :8"
fi

###################
### Office Apps ###
###################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-base.desktop" \
    Name "Base" \
    Name[ro] "Baze" \
    NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-calc.desktop" \
    Name "Calc" \
    Name[ro] "Calcul" \
    NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-draw.desktop" \
    Name "Draw" \
    Name[ro] "Schițe" \
    NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-impress.desktop" \
    Name "Impress" \
    Name[ro] "Prezentări" \
    NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-math.desktop" \
    Name "Math" \
    Name[ro] "Mate" \
    NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/libreoffice-writer.desktop" \
    Name "Writer" \
    Name[ro] "Scriitor" \
    NoDisplay true

#########################
### PASSWORD MANAGERS ###
#########################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/org.gnome.seahorse.Application.desktop" \
    Name[ro] "Parole și Chei" \
    NoDisplay true

####################
### PHOTO ALBUMS ###
####################
set_launcher_entries "$(find_launcher_by_name \"Google Photos\")" \
    Name "Photos" \
    Name[ro] "Fotografii" \
    Categories "Network;Utility;Photography;"

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Photos.desktop" \
    Icon "multimedia-photo-manager"

############
### PLEX ###
############
for LAUNCHER in "${LOCAL_LAUNCHERS_PATH}/chrome-aghlkjcflkcaanjmefomlcfgflfdhkkg-Default.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/plexmediaplayer.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Plex" \
        Name[ro] "Plex" \
        Icon "plexhometheater" \
        Categories "AudioVideo;Audio;Video;Player;" 
done

set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aghlkjcflkcaanjmefomlcfgflfdhkkg-Default.desktop" StartupWMClass "crx_aghlkjcflkcaanjmefomlcfgflfdhkkg"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/plexmediaplayer.desktop" StartupWMClass "plexmediaplayer"

###############
### POSTMAN ###
###############
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/postman.desktop" \
    Icon "postman" \
    Categories "Development;"

##############
### PYTHON ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/ipython.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/ipython2.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "Development;" \
        NoDisplay true \
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

#####################
### SETTINGS APPS ###
#####################
SETTINGS_APP_CATEGORIES="System;" #"Settings;"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/gnome-control-center.desktop" \
    Name "Settings" \
    Name[ro] "Setări" \
    Categories "GNOME;GTK;${SETTINGS_APP_CATEGORIES}"

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/ca.desrt.dconf-editor.desktop" \
    Name "Configurator" \
    Name[ro] "Configurator" \
    Icon "dconf-editor" \
    Categories "GNOME;GTK;${SETTINGS_APP_CATEGORIES}"

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/openrgb.desktop" \
    Categories "Qt;${SETTINGS_APP_CATEGORIES}"

#############
### STEAM ###
#############
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/steam-native.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/steam-runtime.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/valve-URI-steamvr.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/valve-URI-vrmonitor"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/steam.desktop" \
    Name "Steam" \
    Name[ro] "Steam" \
    Categories "Game;Steam;" \
    Exec "steam-start"

set_launcher_entries "${LOCAL_LAUNCHERS_PATH}/valve-vrmonitor.desktop" \
    Name "SteamVR Monitor" \
    NoDisplay true

#####################
### TASK MANAGERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gnome-system-monitor.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-system-monitor.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "System Monitor" \
        Name[ro] "Monitor de Sistem"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxtask.desktop" Name[ro] "Manager de Activități"

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

for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/xterm.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/uxterm.desktop"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

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

###########################
### TORRENT DOWNLOADERS ###
###########################
TORRENT_APP_CATEGORIES="Network;FileTransfer;P2P;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/de.haeckerfelix.Fragments.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/transmission-gtk.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Torrents" \
        Name[ro] "Torente"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/de.haeckerfelix.Fragments.desktop" Categories "GNOME;GTK;${TORRENT_APP_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/transmission-gtk.desktop" Categories "GTK;${TORRENT_APP_CATEGORIES}"

########################
### TRANSLATION APPS ###
########################
set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/com.github.gi_lom.dialect.desktop" \
    Name "Translate" \
    Name[ro] "Traduceri" \
    Categories "GNOME;GTK;Utility;"

############
### WINE ###
############
rm -rf "${HOME_REAL}/.local/share/applications/wine-*"
rm -rf "${HOME_REAL}/.local/share/applications/wine"
rm -rf "${HOME_REAL}/.config/menus/applications-merged/user-chrome-apps.menu"

# CREATE ICONS

if [ -d "${ROOT_USR_SHARE}/gnome-shell/extensions/gsconnect@andyholmes.github.io" ] \
|| [ -d "${HOME}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io" ]; then
    LAUNCHER="${GLOBAL_LAUNCHERS_PATH}/io.github.andyholmes.gsconnect.desktop"

    [ ! -f "${LAUNCHER}" ] && create_launcher "${LAUNCHER}"

    set_launcher_entries "${LAUNCHER}" \
        Name "GSConnect" \
        Exec "${ROOT_USR_SHARE}/gnome-shell/extensions/gsconnect@andyholmes.github.io/gsconnect-preferences" \
        Comment "GSConnect" \
        Keywords "GSConnect;KDEConnect;" \
        Icon "org.gnome.Shell.Extensions.GSConnect" \
        StartupWMClass "gsconnect" \
        NoDisplay true
fi

if [ -f "${ROOT_USR_BIN}/wine" ]; then
    if [ ! -f "winecfg.desktop" ]; then
        create_launcher "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop"

        set_launcher_entries "${GLOBAL_LAUNCHERS_PATH}/winecfg.desktop" \
            Name "Wine Configuration" \
            Categories "Wine;Emulator;System;Settings;" \
            StartupWMClass "winecfg.exe"
    fi
fi

if [ -f "${ROOT_USR_BIN}/winetricks" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/winetricks.desktop"

    [ ! -f "winetricks.desktop" ] && create_launcher "${NEWLAUNCHER}"

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Winetricks" \
        Icon "winetricks" \
        Categories "Wine;Emulator;" \
        StartupWMClass "winetricks" \
        NoDisplay true
fi

if [ -f "${ROOT_USR_BIN}/java" ] || [ -L "${ROOT_USR_BIN}/java" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/run-java.desktop"

    [ ! -f "${NEWLAUNCHER}" ] && create_launcher "${NEWLAUNCHER}"

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Java" \
        Icon "java" \
        Exec "java -jar %U" \
        Terminal true \
        NoDisplay true
fi

if [ -f "${ROOT_USR_BIN}/mono" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/run-mono.desktop"

    [ ! -f "${NEWLAUNCHER}" ] && create_launcher "${NEWLAUNCHER}"

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Mono" \
        Icon "mono" \
        Exec "mono %U" \
        Terminal true \
        NoDisplay true
fi

if [ -f "${ROOT_USR_BIN}/steam" ]; then
    LAUNCHER_FILE_NAME="steam-streaming-client.desktop"
    LAUNCHER_FILE_PATH="${GLOBAL_LAUNCHERS_PATH}/${LAUNCHER_FILE_NAME}"

    [ ! -f "steam-streaming-client.desktop" ] && create_launcher "${LAUNCHER_FILE_PATH}"

    set_launcher_entries "${LAUNCHER_FILE_PATH}" \
        Name "Streaming Client" \
        Comment "Steam Streaming Client" \
        Exec "steam" \
        Icon "steam" \
        Categories "Game;Steam;" \
        StartupWMClass "streaming_client" \
        NoDisplay true
fi

# CREATE STEAM ICONS

function getSteamAppIconPath() {
    local STEAM_APP_ID="${@}"
    local APPS_DIR_NAME="48x48/apps"

    [ ! -d "${ICON_THEME_PATH}/${APPS_DIR_NAME}" ] && APPS_DIR_NAME="48/apps"

    local APP_ICON_PATH="${ICON_THEME_PATH}/${APPS_DIR_NAME}/steam_icon_${APP_ID}.svg"

    if [ -f "${MAIN_APP_ICON_PATH}" ]; then
        echo "${MAIN_APP_ICON_PATH}"
    else
        for ICON_THEME_CANDIDATE in "${ROOT_USR_SHARE}/icons/"* ; do
            if [ -d "${ICON_THEME_CANDIDATE_PATH}/48/apps" ]; then
                APPS_DIR_NAME="48/apps"
            elif [ -d "${ICON_THEME_CANDIDATE_PATH}/48x48/apps" ]; then
                APPS_DIR_NAME="48x48/apps"
            else
                continue
            fi

            APP_ICON_PATH=$(find "${ICON_THEME_CANDIDATE}/${APPS_DIR_NAME}" -type f,l -iname "steam_icon_${APP_ID}.*" -exec readlink -f {} +)

            if [ -f "${APP_ICON_PATH}" ]; then
                echo "${APP_ICON_PATH}"
                return
            fi
        done
    fi

    if [ ! -f "${APP_ICON_PATH}" ]; then
        APP_ICON_PATH="${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"
        [ -f "${APP_ICON_PATH}" ] && echo "${APP_ICON_PATH}"
    fi
}

if [ -f "${ROOT_USR_BIN}/steam" ]; then
    STEAM_PATH="${HOME_REAL}/.local/share/Steam"
    STEAM_LAUNCHERS_PATH="${LOCAL_LAUNCHERS_PATH}/Steam"
    STEAM_ICON_THEME_PATH="${HOME_REAL}/.local/share/icons/steam"
    STEAM_LIBRARY_PATHS="${STEAM_PATH}/steamapps"
    STEAM_LIBRARY_CUSTOM_PATHS=$(grep "\"/" "${STEAM_PATH}/steamapps/libraryfolders.vdf")
    STEAM_WMCLASSES_FILE="data/steam-wmclasses.txt"
    STEAM_NAMES_FILE="data/steam-names.txt"

    if [ -n "${STEAM_LIBRARY_CUSTOM_PATHS}" ]; then
        STEAM_LIBRARY_CUSTOM_PATHS=$(echo ${STEAM_LIBRARY_CUSTOM_PATHS} | \
                                        sed 's/\"[0-9]\"//g' | \
                                        sed 's/^ *//g' | \
                                        sed 's/\t//g' | \
                                        sed 's/\"//g' | \
                                        sed 's/^ *path *//g' | \
                                        sed 's/$/\/steamapps/g')
        STEAM_LIBRARY_PATHS=$(printf "${STEAM_LIBRARY_PATHS}\n${STEAM_LIBRARY_CUSTOM_PATHS}" | sort | uniq)
    fi

    [ ! -d "${STEAM_LAUNCHERS_PATH}" ]              && mkdir -p "${STEAM_LAUNCHERS_PATH}"
    [ ! -f "${STEAM_ICON_THEME_PATH}/48x48/apps" ]  && mkdir -p "${STEAM_ICON_THEME_PATH}/48x48/apps"

    for STEAM_APP_LAUNCHER in "${STEAM_LAUNCHERS_PATH}"/* ; do
        APP_ID=$(grep "^Exec" "${STEAM_APP_LAUNCHER}" | awk -F/ '{print $4}')
        IS_APP_MISSING=true

        for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
            if [ -f "${STEAM_LIBRARY_PATH}/appmanifest_${APP_ID}.acf" ]; then
                IS_APP_MISSING=false
                break
            fi
        done

        set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" NoDisplay "${IS_APP_MISSING}"
        update-file-if-needed "${STEAM_PATH}/appcache/librarycache/${APP_ID}_icon.jpg" "${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"
    done

    for STEAM_LIBRARY_PATH in ${STEAM_LIBRARY_PATHS}; do
        if [ -d "${STEAM_LIBRARY_PATH}" ] && [ -d "${ICON_THEME_PATH}" ]; then
            [ ! -f "${STEAM_WMCLASSES_FILE}" ]  && touch "${STEAM_WMCLASSES_FILE}"
            [ ! -f "${STEAM_NAMES_FILE}" ]      && touch "${STEAM_NAMES_FILE}"

            APP_IDS=$(ls "${STEAM_LIBRARY_PATH}" | grep "appmanifest_.*.acf" | awk -F_ '{print $2}' | awk -F. '{print $1}' | sort -h)
            APPS_DIR_NAME="48x48/apps"

            if [ ! -d "${ICON_THEME_PATH}/${APPS_DIR_NAME}" ]; then
                APPS_DIR_NAME="48/apps"
            fi

            for APP_ID in ${APP_IDS}; do
                APP_ICON_PATH=$(getSteamAppIconPath "${APP_ID}")
                APP_NAME=$(grep -h "\"name\"" "${STEAM_LIBRARY_PATH}/appmanifest_${APP_ID}.acf" | sed 's/\"name\"//' | grep -o "\".*\"" | sed 's/\"//g')

                if [ $(grep -c "^${APP_ID}=" "${STEAM_NAMES_FILE}") -ne 0 ]; then
                    APP_NAME=$(grep "^${APP_ID}=" "${STEAM_NAMES_FILE}" | awk -F= '{print $2}')
                fi

                DO_CREATE_LAUNCHER=true

                if [[ "${APP_NAME}" == "Steamworks Common Redistributables" ]] || \
                   [[ "${APP_NAME}" =~ ^Proton\ [0-9]+\.[0-9]+$ ]] || \
                   [[ "${APP_NAME}" == "Steam Linux Runtime"* ]]; then
                    DO_CREATE_LAUNCHER=false
                fi

                if ${DO_CREATE_LAUNCHER}; then
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
                        Comment[es] "Juega ${APP_NAME} en Steam" \
                        Comment[ro] "Joacă ${APP_NAME} pe Steam" \
                        Keywords "Game;Steam;${APP_ID};" \
                        Keywords[es] "Juego;Steam;${APP_ID};" \
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
ICON_THEMES=$(find "${ROOT_USR_SHARE}/icons/" -mindepth 1 -type d)

for ICON_THEME in ${ICON_THEMES}; do
    if [ -f "${ROOT_USR_SHARE}/icons/${ICON_THEMES}/index.theme" ]; then
        gtk-update-icon-cache "${ROOT_USR_SHARE}/icons/${ICON_THEME}"
    fi
done

update-desktop-database
update-desktop-database "${LOCAL_LAUNCHERS_PATH}"
