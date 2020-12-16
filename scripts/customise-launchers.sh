#!/bin/bash

ARCH=${1}

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"

USER_REAL=${SUDO_USER}
[ ! -n "${USER_REAL}" ] && USER_REAL=${USER}
HOME_REAL="/home/${USER_REAL}"

GLOBAL_LAUNCHERS_PATH="/usr/share/applications"
LOCAL_LAUNCHERS_PATH="${HOME_REAL}/.local/share/applications"

ICON_THEME=$(sudo -u ${USER_REAL} -H gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
ICON_THEME_PATH="/usr/share/icons/"${ICON_THEME}

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
            return -
        fi
    done

    return 1
}

set_launcher_entry() {
    FILE="$1"
    KEY="$2"
    VAL="$3"

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
        elif [ ! -z "${VAL}" ]; then
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

    set_launcher_entry "${FILE}" "${KEY_ROMANIAN}[ro_RO]" "${VAL}"
    set_launcher_entry "${FILE}" "${KEY_ROMANIAN}[ro_MD]" "${VAL}"
}

set_launcher_entry_english() {
    FILE="$1"
    KEY_ENGLISH="$2"
    VAL="$3"

    set_launcher_entry "${FILE}" "${KEY_ENGLISH}[en_AU]" "${VAL}"
    set_launcher_entry "${FILE}" "${KEY_ENGLISH}[en_CA]" "${VAL}"
    set_launcher_entry "${FILE}" "${KEY_ENGLISH}[en_GB]" "${VAL}"
    set_launcher_entry "${FILE}" "${KEY_ENGLISH}[en_US]" "${VAL}"
}

create_launcher() {
    FILE="$*"
    NAME=$(basename ${FILE} | cut -f 1 -d '.')
    if [ ! -f "${FILE}" ]; then
        touch ${FILE}
        printf "[Desktop Entry]\n" >> ${FILE}
        printf "Version=1.0\n" >> ${FILE}
        printf "NoDisplay=false\n" >> ${FILE}
        printf "Encoding=UTF-8\n" >> ${FILE}
        printf "Type=Application\n" >> ${FILE}
        printf "Terminal=false\n" >> ${FILE}
        printf "Exec=${NAME}\n" >> ${FILE}
        printf "StartupWMClass=${NAME}\n" >> ${FILE}

        set_launcher_entry "${FILE}" "Name" "${NAME}"
        set_launcher_entry "${FILE}" "Comment" "${NAME}"
        set_launcher_entry "${FILE}" "Keywords" "${NAME};"
        set_launcher_entry "${FILE}" "Icon" "${NAME}"

        chmod +x "${FILE}"
        echo "Created file '${FILE}'"
    fi
}

set_theme() {
    FILE="$1"
    THEME="$2"
    LINE="export GTK2_RC_FILES=\"\/usr\/share\/themes\/${THEME}\/gtk-2.0\/gtkrc\""
    MODIFIED=0

    if [ ! -f "${FILE}" ]; then
        return
    fi

    if [ $(grep -c '^export GTK2_RC_FILES=.*$' "${FILE}") -eq 0 ]; then
        MODIFIED=1
        sed -i '2s/^/'"${LINE}"'\n/' "${FILE}"
    elif [ $(grep -c '^'"${LINE}"'$' "${FILE}") -eq 0 ]; then
        MODIFIED=1
        sed -i 's/^export GTK2_RC_FILES=.*$/'"${LINE}"'/' "${FILE}"
    fi

    if [ ${MODIFIED} == 1 ]; then
        echo "${FILE} --> ${LINE}"
    fi
}

set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/7zFM.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/alltray.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/amidst.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/amidst.desktop" StartupWMClass "amidst-Amidst"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/android-studio.desktop" StartupWMClass "jetbrains-studio"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/assistant-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/assistant.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/avahi-discover.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/balena-etcher-electron.desktop" Name "Etcher"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/balena-etcher-electron.desktop" Name[ro] "Etcher"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/bssh.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/bvnc.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ca.desrt.dconf-editor.desktop" Icon "dconf-editor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ca.desrt.dconf-editor.desktop" Name "Configuration Editor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ca.desrt.dconf-editor.desktop" Name[ro] "Editor de Configurări"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/caffeine-indicator.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/caja-browser.desktop" Categories "GTK;Utility;Core;FileManager;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/caja-browser.desktop" Name "Files"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/caja-browser.desktop" Name[ro] "Fișiere"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Cisco-PacketTracer.desktop" Categories "Network;Development;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Cisco-PacketTracer.desktop" Icon "logview"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Cisco-PacketTracer.desktop" StartupWMClass "PacketTracer6"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/cmake-gui.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/CMake.desktop" Icon "cmake"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/cmake.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/CMake.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" Categories "TextEditor;Development;IDE;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" Icon "visual-studio-code"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" Keywords "VS;Code;VSCode;Visual Studio;Visual Studio Code;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" Name "Code"
[ "${ARCH_FAMILY}" == "x86" ] && set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "code"
[ "${ARCH_FAMILY}" == "arm" ] && set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss.desktop" StartupWMClass "Code - OSS (headmelted)"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code-oss-url-handler.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code.desktop" Name "Code"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/code.desktop" StartupWMClass "code-oss"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/codeblocks.desktop" Name "Code::Blocks"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.teamviewer.TeamViewer.desktop" Categories "Network;RemoteAccess;FileTransfer;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.teamviewer.TeamViewer.desktop" Icon "teamviewer"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.teamviewer.TeamViewer.desktop" Name "TeamViewer"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.teamviewer.TeamViewer.desktop" StartupWMClass "TeamViewer"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.vinszent.GnomeTwitch.desktop" Icon "gnome-twitch"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.vinszent.GnomeTwitch.desktop" Name "Twitch"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/com.vinszent.GnomeTwitch.desktop" Name[ro] "Twitch"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/cups.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/designer-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/designer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/diffuse.desktop" Name "Diffuse"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Discord.desktop" Icon "discord"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/dosbox.desktop" Categories "Application;Emulator;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/dosbox.desktop" Name "DosBox"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/dropbox.desktop" Categories "Network;Cloud;FileSharing;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/dropbox.desktop" Exec "dropbox start -i"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/electron.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/electron2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/electron7.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/factorio.desktop" Icon "factorio"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ffadomixer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/firefox-developer.desktop" Categories "Network;WebBrowser;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fluid.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fluxgui.desktop" Icon "fluxgui"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fluxgui.desktop" Name "F.lux"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fluxgui.desktop" StartupWMClass "Fluxgui.py"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fma-config-tool.desktop" Icon "nautilus-actions"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/fma-config-tool.desktop" Name "File Manager Actions"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/freeciv-mp-gtk2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/freeciv-mp.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/freeciv-server.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/GameConqueror.desktop" Categories "Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/genymotion.desktop" Categories "Development;Emulator;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/genymotion.desktop" Icon "genymotion"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/geogebra.desktop" StartupWMClass "org-geogebra-desktop-GeoGebra3D"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ghetto-skype.desktop" Categories "Application;Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ghetto-skype.desktop" Icon "skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ghetto-skype.desktop" Name "Skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gimp.desktop" Name "GIMP"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gimp.desktop" StartupWMClass "Gimp-2.10"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gksu-properties.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gksu.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnome-disks.desktop" Name[ro] "Discuri"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnome-system-monitor.desktop" Name[ro] "Monitor de Sistem"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnome-twofactorauth.desktop" Categories "GNOME;GTK;Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnome-twofactorauth.desktop" Name "Authenticator"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnubg.desktop" Name "Backgammon"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gnubg.desktop" Name[ro] "Table"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/godot.desktop" Categories "Development;IDE;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/godot.desktop" StartupWMClass "Godot"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" Icon "google-chrome"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" Name "Chrome"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome-unstable.desktop" StartupWMClass "Google-chrome-unstable"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" Name "Chrome"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" StartupWMClass "Google-chrome-stable"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-earth.desktop" Categories "Application;Network;Navigation;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" Name "Keep"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" Name[ro] "Keep"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/google-keep.desktop" StartupWMClass "google-keep-nativefier-d04d04"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gparted.desktop" Name "Partition Editor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gparted.desktop" Name[ro] "Editor de Partiții"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gtk-lshw.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gucharmap.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" Categories "System;Monitor;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" Icon "hardinfo"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" Name "Hardware Information"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/hardinfo.desktop" Name[ro] "Informații Hardware"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/htop.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ibus-setup.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/idea.desktop" Name "IntelliJ"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/idea.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/inkscape.desktop" Name "Inkscape"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce-eap.desktop" Icon "idea"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce-eap.desktop" Name "IntelliJ"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce-eap.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce.desktop" Icon "idea"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce.desktop" Name "IntelliJ"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/intellij-idea-ce.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ipython.desktop" Categories "Development;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ipython.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ipython2.desktop" Categories "Development;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ipython2.desktop" Icon "ipython"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/ipython2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/java-java-openjdk.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-java-openjdk.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jconsole-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jetbrains-idea-ce.desktop" Icon "idea"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jetbrains-idea-ce.desktop" Name "IntelliJ"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jetbrains-idea-ce.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jmc-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jshell-java-openjdk.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/jvisualvm-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/laptop-mode-tools.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/libreoffice-base.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/libreoffice-draw.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/libreoffice-math.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/libreoffice-startcenter.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/linguist-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/linguist.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lstopo.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxhotkey-gtk.desktop" Name[ro] "Scurtături de tastatură"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxmusic.desktop" MimeType "application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/vorbis;audio/x-vorbis;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-mpegurl;audio/x-flac;audio/mp4;x-scheme-handler/itms;x-scheme-handler/itmss;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxmusic.desktop" Name "Music"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxmusic.desktop" Name[ro] "Muzică"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxsession-default-apps.desktop" Name "Default Applications"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxsession-default-apps.desktop" Name[ro] "Aplicații implicite"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/lxtask.desktop" Name[ro] "Manager de Activități"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-color-select.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-dictionary.desktop" Name "Dictionary"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-dictionary.desktop" Name[ro] "Dicționar"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-disk.desktop" Icon "gnome-disks"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-disk.desktop" Name[ro] "Discuri"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-search-tool.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-system-monitor.desktop" Name "System Monitor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/mate-system-monitor.desktop" Name[ro] "Monitor de Sistem"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/messengerfordesktop.desktop" Categories "Application;Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/messengerfordesktop.desktop" Exec "start-wmclass messengerfordesktop fbmessenger"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/messengerfordesktop.desktop" Icon "fbmessenger"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/messengerfordesktop.desktop" Name "Facebook Messenger"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/messengerfordesktop.desktop" StartupWMClass "fbmessenger"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/midori-private.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/minecraft-launcher.desktop" Name "Minecraft"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/minecraft-launcher.desktop" StartupWMClass "Minecraft* 1.16.4"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/monodevelop.desktop" Exec "env GNOME_DESKTOP_SESSION_ID="" monodevelop %F"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Monogame\ Pipeline.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Monogame\ Pipeline.desktop" StartupWMClass "Pipeline"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/MonogamePipeline.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/MonogamePipeline.desktop" StartupWMClass "Pipeline"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nemo.desktop" Icon "nemo"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nemo.desktop" Name "Files"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nemo.desktop" Name[ro] "Fișiere"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/netbeans.desktop" Icon "netbeans"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/netbeans.desktop" Name "Netbeans"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nfs2se.desktop" Icon "nfs2se"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nfs2se.desktop" Name "Need for Speed 2"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nfs2se.desktop" StartupWMClass "nfs2se"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" Categories "System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" Exec "gksu nvidia-settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" Icon "nvidia-settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nvidia-settings.desktop" Name "Nvidia Settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nylas.desktop" Categories "GNOME;GTK;Email;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nylas.desktop" Icon "gmail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/nylas.desktop" Name "GMail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/openarena-server.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.baedert.corebird.desktop" Categories "Network;GTK;Communication;Social;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.baedert.corebird.desktop" Icon "twitter"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.baedert.corebird.desktop" Name "Twitter"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Icon "gnome-settings-mouse"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.freedesktop.Piper.desktop" Name "Mouse Settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Calendar.desktop" Categories "GNOME;GTK;Utility;Calendar;Core;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Cheese.desktop" Icon "camera"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Cheese.desktop" Name "Camera"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Cheese.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Contacts.desktop" Categories "GNOME;GTK;Utility;ContactManagement;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.DiskUtility.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Epiphany.desktop" Name "Epiphany"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Evolution.desktop" Name "Mail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Categories "Network;Feed;Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Icon "feedreader"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FeedReader.desktop" Name "Feed Reader"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.font-viewer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.gnome-2048.desktop" Icon "2048"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Lollypop.desktop" Icon "lollypop"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Maps.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Photos.desktop" Icon "multimedia-photo-manager"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.SoundRecorder.desktop" Categories "GNOME;GTK;Utility;Audio;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.tweaks.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.tweaks.desktop" Icon "utilities-tweak-tool"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Weather.Application.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/pavucontrol.desktop" Categories "Audio;Mixer;System;GTK;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/pavucontrol.desktop" Name "Audio Settings"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/PCSX2.desktop" Icon "pcsx2"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/picard.desktop" StartupWMClass ""
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/plank.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/playonlinux.desktop" Categories "Application;Emulator;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/playonlinux.desktop" Icon "playonlinux"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/playonlinux.desktop" StartupWMClass "Mainwindow.py"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-java-openjdk.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/policytool-jre9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorn-time-ce.desktop" Exec "start-wmclass popcorntime popcorntime"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorn-time-ce.desktop" Icon "popcorn-time"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorn-time-ce.desktop" StartupWMClass "popcorntime"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorntime-ce.desktop" Name "Popcorn Time"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorntime.desktop" Categories "AudioVideo;Video;Player;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorntime.desktop" Exec "start-wmclass popcorntime popcorntime"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/popcorntime.desktop" StartupWMClass "Popcorn-Time"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/postman.desktop" Categories "Development;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/postman.desktop" Icon "postman"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/pycharm-com-eap.desktop" Icon "pycharm"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/pycharm-com-eap.desktop" Name "PyCharm"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/pycharm-community-edition.desktop" StartupWMClass "jetbrains-pycharm-ce"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qdbusviewer-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qdbusviewer.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qtconfig-qt4.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qv4l2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qv4l2.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/qvidcap.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/rider.desktop" Icon "rider"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simple-scan.desktop" Name "Scanner"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simple-scan.desktop" Name[ro] "Scanner"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/simplescreenrecorder.desktop" Name "Screen Recorder"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skype-desktop.desktop" Categories "Application;Network;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skype-desktop.desktop" Icon "skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skype-desktop.desktop" StartupWMClass "crx_monljlleikpphbhopghghdbggidfahha"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skype.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skype.desktop" Icon "skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skypeforlinux.desktop" Categories "Application;Network;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skypeforlinux.desktop" Icon "skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skypeforlinux.desktop" Name "Skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/skypeforlinux.desktop" StartupWMClass "Skype"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam-native.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam-runtime.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam.desktop" Categories "Game;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam.desktop" Exec "steam-start"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/steam.desktop" Name "Steam"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui-small.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/stoken-gui.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jdk9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun_java-jre9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jdk10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jdk11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jdk8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jdk9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jre10.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jre11.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jre8.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-java-jre9.desktop" Icon "java"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre10.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre11.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre12.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre13.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre8.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/sun-javaws-jre9.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/system-config-printer.desktop" Name[ro] "Configurare Imprimantă"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teamviewer.desktop" Categories "Network;RemoteAccess;FileTransfer;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teams.desktop" Categories "Application;Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teams.desktop" Name "Teams"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teamviewer.desktop" Icon "teamviewer"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teamviewer.desktop" Name "TeamViewer"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/teamviewer.desktop" StartupWMClass "TeamViewer.exe"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/Thunar-bulk-rename.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-bulk-rename.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-settings.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/thunar-volman-settings.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tilda.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tiled.desktop" Categories "Development;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" Categories "Network;WebBrowser;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" Icon "tor-browser-en"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" Name "Tor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tor-browser-en.desktop" StartupWMClass "Tor Browser"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tracker-needle.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/tracker-preferences.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/transmission-gtk.desktop" Name "Torrents"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/transmission-gtk.desktop" Name[ro] "Torente"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-editor.desktop" Categories "Development;IDE;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-editor.desktop" Icon "unity-editor-icon"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-editor.desktop" Name "Unity Editor"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-monodevelop.desktop" Categories "Development;IDE;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-monodevelop.desktop" Icon "unity-monodevelop"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/unity-monodevelop.desktop" Name "MonoDevelop - Unity"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/uxterm.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vim.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/virtualbox.desktop" Name "VirtualBox"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop" Name "Code"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop" Keywords "VS;Code;VSCode;Visual Studio;Visual Studio Code;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/visual-studio-code.desktop" StartupWMClass "Code"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vivaldi-preview.desktop" Name "Vivaldi"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/vlc.desktop" Name "VLC"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop" Icon "citrix-receiver"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop" Name "Citrix Receiver"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop" Name[ro] "Receptor Citrix"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wfica.desktop" StartupWMClass "Wfica"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-desktop.desktop" Categories "Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-desktop.desktop" Icon "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-desktop.desktop" StartupWMClass "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier.desktop" Categories "Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier.desktop" Icon "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier.desktop" StartupWMClass "whatsapp-nativefier-d40211"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" Categories "Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" Icon "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" Name "WhatsApp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsapp-nativefier-dark.desktop" StartupWMClass "whatsapp-nativefier-d52542"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsie.desktop" Categories "Network;Chat;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsie.desktop" Icon "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/whatsie.desktop" Name "WhatsApp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wireshark-gtk.desktop" Name "Wireshark"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wmail.desktop" Icon "gmail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wmail.desktop" Name "GMail"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-et.desktop" Categories "QT;Office;Spreadsheet;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-et.desktop" StartupWMClass "Et"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-wpp.desktop" Categories "QT;Office;Presentation;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-wpp.desktop" StartupWMClass "Wpp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-wps.desktop" Categories "QT;Office;WordProcessor;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/wps-office-wps.desktop" StartupWMClass "Wps"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/www.octave.org-octave.desktop" Icon "octave-logo"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/www.octave.org-octave.desktop" StartupWMClass "octave-gui"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xampp-manager.desktop" Icon "xampp"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xchat.desktop" Categories "Network;Communication;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xchat.desktop" Name "XChat"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xdvi.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/xterm.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/yelp.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/zenmap-root.desktop" NoDisplay "true"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/zenmap.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Categories "ChromeApp;Education;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Name "Duolingo"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" Categories "ChromeApp;Office;WordProcessor;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" NoDisplay "false"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-app-list.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hkgndiocipalkpejnpafdbdlfdjihomd-Default.desktop" Categories "ChromeApp;Network;FileTransfer;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Categories "ChromeApp;Utility;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Icon "google-keep"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Name "Keep"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" NoDisplay "false"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Categories "ChromeApp;Network;Navigation;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Name "Maps"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Name[ro] "Hărți"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" NoDisplay "false"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Categories "ChromeApp;Network;Chat;InstantMessaging;Communication;"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Icon "whatsapp"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Name "WhatsApp"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-vrmonitor.desktop" Name "SteamVR Monitor"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-vrmonitor.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-URI-steamvr.desktop" NoDisplay "true"
set_launcher_entry "${LOCAL_LAUNCHERS_PATH}/valve-URI-vrmonitor.desktop" NoDisplay "true"
set_launcher_entry $(find_launcher_by_name "Netflix") Categories "AudioVideo;Video;Player;"

########################
### ARCHIVE MANAGERS ###
########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/engrampa.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/xarchiver.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Archives"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Arhive"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/org.gnome.FileRoller.desktop" StartupWMClass "File-Roller"

###################
### CALCULATORS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/galculator.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-calc.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Calculator"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Calculator"
done

############################
### DISK USAGE ANALYZERS ###
############################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/baobab.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-disk-usage-analyzer.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Disk Usage"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Ocuparea Spațiului"
    set_launcher_entry "${LAUNCHER}" OnlyShowIn ""
done

########################
### DOCUMENT VIEWERS ###
########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/epdfview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/evince.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Documents"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Documente"
done

#####################
### FILE MANAGERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/io.elementary.files.dekstop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Nautilus.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/pcmanfm.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Files"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Fișiere"
    set_launcher_entry "${LAUNCHER}" Categories "Utility;Core;FileManager;"
done

#####################
### IMAGE VIEWERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gpicview.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eog.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/eom.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Images"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Imagini"
done

###################
### LOG VIEWERS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/mate-system-log.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Logs.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Logs"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Loguri"
    set_launcher_entry "${LAUNCHER}" OnlyShowIn ""
done

######################
### SCREENSHOOTERS ###
######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gscreenshot.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-screenshot.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/org.gnome.Screenshot.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Screenshot"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Captură de Ecran"
    set_launcher_entry "${LAUNCHER}" Icon "applets-screenshooter"
    set_launcher_entry "${LAUNCHER}" OnlyShowIn ""
done
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gscreenshot.desktop" Categories "Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/gscreenshot.desktop" StartupWMClass "gscreenshot"

#################
### TERMINALS ###
#################
for LAUNCHER in "${GLOBAL_LAUNCHERS_PATH}/gnome-terminal.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/lxterminal.desktop" \
                "${GLOBAL_LAUNCHERS_PATH}/mate-terminal.desktop"; do
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Terminal"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Terminal"
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
    [ ! -f "${LAUNCHER}" ] && continue
    set_launcher_entry "${LAUNCHER}" Name "Text Editor"
    set_launcher_entry "${LAUNCHER}" Name[ro] "Editor Text"
    set_launcher_entry "${LAUNCHER}" Icon "accessories-text-editor"
done

if [ -f "${GLOBAL_LAUNCHERS_PATH}/chromium.desktop" ] && [ ! -f "${GLOBAL_LAUNCHERS_PATH}/google-chrome.desktop" ]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/chromium.desktop" Name "Chrome"
    set_launcher_entry "${GLOBAL_LAUNCHERS_PATH}/chromium.desktop" Icon "google-chrome"
fi

# Themes
set_theme "/usr/bin/tor-browser-en" "Adwaita"

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

if [ -f "/usr/bin/mono" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_PATH}/run-mono.desktop"

    if [ ! -f "${NEWLAUNCHER}" ]; then
        create_launcher "${NEWLAUNCHER}"
    fi

    set_launcher_entry "${NEWLAUNCHER}" Name "Run Software with Mono"
    set_launcher_entry "${NEWLAUNCHER}" Icon "mono"
    set_launcher_entry "${NEWLAUNCHER}" Exec "mono %U"
    set_launcher_entry "${NEWLAUNCHER}" Terminal "true"
    set_launcher_entry "${NEWLAUNCHER}" NoDisplay "true"
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

    if [ ! -z "${STEAM_LIBRARY_CUSTOM_PATHS}" ]; then
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

        STEAM_ICON_PATH="${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"
        if [ ! -f "${STEAM_ICON_PATH}" ]; then
            echo "Copying icon for Steam AppID ${APP_ID} into the Steam icon pack..."
            cp "${STEAM_PATH}/appcache/librarycache/${APP_ID}_icon.jpg" "${STEAM_ICON_PATH}"
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

                if [[ "${APP_NAME}" == "Steamworks Common Redistributables" ]] || [[ "${APP_NAME}" =~ ^Proton\ [0-9]+\.[0-9]+$ ]]; then
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
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Name "${APP_NAME}"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Comment "Play ${APP_NAME} on Steam"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Comment[ro] "Joacă ${APP_NAME} pe Steam"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Keywords "Game;Steam;${APP_ID};${APP_NAME};"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Keywords[ro] "Joc;Steam;${APP_ID};${APP_NAME};"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Exec "steam steam:\/\/rungameid\/${APP_ID}"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Icon "${APP_ICON_PATH}"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" Categories "Game;Steam;"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" StartupWMClass "${APP_WMCLASS}"
                    set_launcher_entry "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" NoDisplay "false"
                fi
            done

            chown -R ${USER_REAL} "${STEAM_LAUNCHERS_PATH}"
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
update-desktop-database ${LOCAL_LAUNCHERS_PATH}
