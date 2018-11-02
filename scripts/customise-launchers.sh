#!/bin/bash

USER_REAL=$SUDO_USER

if [ ! -n "$USER_REAL" ]; then
    USER_REAL=$USER
fi

GLOBAL_LAUNCHERS_PATH="/usr/share/applications"
LOCAL_LAUNCHERS_PATH="/home/$USER_REAL/.local/share/applications"
STEAM_LAUNCHERS_PATH="$LOCAL_LAUNCHERS_PATH/Steam"
STEAM_APPS_PATH=$(cat "/home/$USER_REAL/.local/share/Steam/steamapps/libraryfolders.vdf" | grep "\"/" | sed 's/\"[0-9]\"//g' | sed 's/^ *//g' | sed 's/\t//g' | sed 's/\"//g')$(echo "/steamapps/")
ICON_THEME_PATH="/usr/share/icons/Numix-Circle"

cd /usr/share/applications

set_launcher_entry() {
    FILE="$1"
    KEY="$2"
    VAL="$3"

    if [ ! -f "$FILE" ]; then
        return
    fi

    KEY_ESC=$(echo "$KEY" | sed -e 's/[]\/$*.^|[]/\\&/g')
    VAL_ESC=$(echo "$VAL" | sed -e 's/[]\/$*.^|[]/\\&/g')

    HAS_MULTIPLE_SECTIONS=0
    LAST_SECTION_LINE=$(wc -l "$FILE" | awk '{print $1}')

    FILE_CONTENTS=$(cat "$FILE")

    if [ $(grep -c "^\[.*\]$" <<< "$FILE_CONTENTS") -gt 1 ]; then
        HAS_MULTIPLE_SECTIONS=1
        LAST_SECTION_LINE=$(grep -n "^\[.*\]$" "$FILE" | sed '2q;d' | awk -F: '{print $1}')
        FILE_CONTENTS=$(echo "$FILE_CONTENTS" | head -n "${LAST_SECTION_LINE}")
    fi

    if [ $(grep -c "^${KEY_ESC}=${VAL}$" <<< "$FILE_CONTENTS") == 0 ]; then
        if [ $(grep -c "^${KEY_ESC}=.*$" <<< "$FILE_CONTENTS") -gt 0 ]; then
            sed -i '1,'"${LAST_SECTION_LINE}"' s|^'"${KEY_ESC}"'=.*$|'"${KEY_ESC}"'='"${VAL}"'|g' "$FILE"
        else
            if [ $HAS_MULTIPLE_SECTIONS == 1 ]; then
                sed -i "$LAST_SECTION_LINE i ${KEY_ESC}=${VAL_ESC}" "$FILE"
            else
                printf "$KEY=$VAL\n" >> "$FILE"
            fi
        fi

        echo "$FILE >>> $KEY=$VAL"
    fi

    if [ "$KEY_ESC" = "Comment" ]; then
        set_launcher_entry_english "$FILE" "Comment" "$VAL"
    elif [ "$KEY_ESC" = "Name" ]; then
        set_launcher_entry_english "$FILE" "Name" "$VAL"
        set_launcher_entry_english "$FILE" "X-GNOME-FullName" "$VAL"
        set_launcher_entry_english "$FILE" "X-MATE-FullName" "$VAL"
    elif [ "$KEY_ESC" = "Keywords" ]; then
        set_launcher_entry_english "$FILE" "Keywords" "$VAL"
    elif [ "$KEY_ESC" = "X-GNOME-FullName" ]; then
        set_launcher_entry_english "$FILE" "X-GNOME-FullName" "$VAL"
    elif [ "$KEY_ESC" = "X-MATE-FullName" ]; then
        set_launcher_entry_english "$FILE" "X-MATE-FullName" "$VAL"
    elif [ "$KEY_ESC" = "Icon" ]; then
        set_launcher_entry_english "$FILE" "Icon" "$VAL"
    fi

    if [ "$KEY_ESC" = "Comment\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "Comment" "$VAL"
    elif [ "$KEY_ESC" = "Name\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "Name" "$VAL"
        set_launcher_entry_romanian "$FILE" "X-GNOME-FullName" "$VAL"
        set_launcher_entry_romanian "$FILE" "X-MATE-FullName" "$VAL"
    elif [ "$KEY_ESC" = "Keywords\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "Keywords" "$VAL"
    elif [ "$KEY_ESC" = "X-GNOME-FullName\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "X-GNOME-FullName" "$VAL"
    elif [ "$KEY_ESC" = "X-MATE-FullName\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "X-MATE-FullName" "$VAL"
    elif [ "$KEY_ESC" = "Icon\[ro\]" ]; then
        set_launcher_entry_romanian "$FILE" "Icon" "$VAL"
    fi
}

set_launcher_entry_romanian() {
    FILE="$1"
    KEY_ROMANIAN="$2"
    VAL="$3"

    set_launcher_entry "$FILE" "$KEY_ROMANIAN[ro_RO]" "$VAL"
    set_launcher_entry "$FILE" "$KEY_ROMANIAN[ro_MD]" "$VAL"
}

set_launcher_entry_english() {
    FILE="$1"
    KEY_ENGLISH="$2"
    VAL="$3"

    set_launcher_entry "$FILE" "$KEY_ENGLISH[en_AU]" "$VAL"
    set_launcher_entry "$FILE" "$KEY_ENGLISH[en_CA]" "$VAL"
    set_launcher_entry "$FILE" "$KEY_ENGLISH[en_GB]" "$VAL"
    set_launcher_entry "$FILE" "$KEY_ENGLISH[en_US]" "$VAL"
}

create_launcher() {
    FILE="$*"
    NAME=$(basename $FILE | cut -f 1 -d '.')
    if [ ! -f "$FILE" ]; then
        touch $FILE
        printf "[Desktop Entry]\n" >> $FILE
        printf "Version=1.0\n" >> $FILE
        printf "Encoding=UTF-8\n" >> $FILE
        printf "Type=Application\n" >> $FILE
        printf "Exec=$NAME\n" >> $FILE
        printf "StartupWMClass=$NAME\n" >> $FILE

        set_launcher_entry "$FILE" "Name" "$NAME"
        set_launcher_entry "$FILE" "Comment" "$NAME"
        set_launcher_entry "$FILE" "Keywords" "$NAME;"
        set_launcher_entry "$FILE" "Icon" "$NAME"

        chmod +x "$FILE"
        echo "Created file '$FILE'"
    fi
}

set_theme() {
    FILE="$1"
    THEME="$2"
    LINE="export GTK2_RC_FILES=\"\/usr\/share\/themes\/$THEME\/gtk-2.0\/gtkrc\""
    MODIFIED=0

    if [ ! -f "$FILE" ]; then
        return
    fi

    if [ $(grep -c '^export GTK2_RC_FILES=.*$' "$FILE") -eq 0 ]; then
        MODIFIED=1
        sed -i '2s/^/'"$LINE"'\n/' "$FILE"
    elif [ $(grep -c '^'"$LINE"'$' "$FILE") -eq 0 ]; then
        MODIFIED=1
        sed -i 's/^export GTK2_RC_FILES=.*$/'"$LINE"'/' "$FILE"
    fi

    if [ $MODIFIED == 1 ]; then
        echo "$FILE --> $LINE"
    fi
}

# ICONS
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-chrome-unstable.desktop" Icon "google-chrome"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ca.desrt.dconf-editor.desktop" Icon "dconf-editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Cisco-PacketTracer.desktop" Icon "logview"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/CMake.desktop" Icon "cmake"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/code-oss" Icon "visual-studio-code"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.vinszent.GnomeTwitch.desktop" Icon "gnome-twitch"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Discord.desktop" Icon "discord"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/factorio.desktop" Icon "factorio"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/fluxgui.desktop" Icon "fluxgui"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/genymotion.desktop" Icon "genymotion"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ghetto-skype.desktop" Icon "skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/hardinfo.desktop" Icon "hardinfo"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce.desktop" Icon "idea"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce-eap.desktop" Icon "idea"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ipython2.desktop" Icon "ipython"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jetbrains-idea-ce.desktop" Icon "idea"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-disk.desktop" Icon "gnome-disks"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/messengerfordesktop.desktop" Icon "fbmessenger"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nemo.desktop" Icon "nemo"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nfs2se.desktop" Icon "nfs2se"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nvidia-settings.desktop" Icon "nvidia-settings"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nylas.desktop" Icon "gmail"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.baedert.corebird.desktop" Icon "twitter"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.freedesktop.Piper.desktop" Icon "gnome-settings-mouse"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Cheese.desktop" Icon "camera"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FeedReader.desktop" Icon "feedreader"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.gnome-2048.desktop" Icon "2048"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Photos.desktop" Icon "multimedia-photo-manager"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.tweaks.desktop" Icon "utilities-tweak-tool"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Lollypop.desktop" Icon "lollypop"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/PCSX2.desktop" Icon "pcsx2"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/playonlinux.desktop" Icon "playonlinux"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorn-time-ce.desktop" Icon "popcorn-time"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/postman.desktop" Icon "postman"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pycharm-com-eap.desktop" Icon "pycharm"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/rider.desktop" Icon "rider"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skype-desktop.desktop" Icon "skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skype.desktop" Icon "skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skypeforlinux.desktop" Icon "skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jre8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jre9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jre10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-java-jre11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/io.elementary.code.desktop" Icon "accessories-text-editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk8.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk9.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk10.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk11.desktop" Icon "java"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/teamviewer.desktop" Icon "teamviewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.teamviewer.TeamViewer.desktop" Icon "teamviewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tor-browser-en.desktop" Icon "tor-browser-en"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-editor.desktop" Icon "unity-editor-icon"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-monodevelop.desktop" Icon "unity-monodevelop"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsapp-desktop.desktop" Icon "whatsappfordesktop"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsie.desktop" Icon "whatsapp"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wmail.desktop" Icon "gmail"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/www.octave.org-octave.desktop" Icon "octave-logo"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xampp-manager.desktop" Icon "xampp"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Icon "google-keep"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Icon "whatsappfordesktop"


# CATEGORIES
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/caja-browser.desktop" Categories "GTK;Utility;Core;FileManager;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Cisco-PacketTracer.desktop" Categories "Network;Development;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/code-oss.desktop" Categories "TextEditor;Development;IDE;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.teamviewer.TeamViewer.desktop" Categories "Network;RemoteAccess;FileTransfer;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/dosbox.desktop" Categories "Application;Emulator;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/dropbox.desktop" Categories "Network;Cloud;FileSharing;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/firefox-developer.desktop" Categories "Network;WebBrowser;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/GameConqueror.desktop" Categories "Utility;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/genymotion.desktop" Categories "Development;Emulator;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ghetto-skype.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnome-twofactorauth.desktop" Categories "GNOME;GTK;Utility;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/godot.desktop" Categories "Development;IDE;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-earth.desktop" Categories "Application;Network;Navigation;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/hardinfo.desktop" Categories "System;Monitor;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ipython2.desktop" Categories "Development;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ipython.desktop" Categories "Development;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/messengerfordesktop.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nvidia-settings.desktop" Categories "System;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nylas.desktop" Categories "GNOME;GTK;Email;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.baedert.corebird.desktop" Categories "Network;GTK;Communication;Social;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.freedesktop.Piper.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Calendar.desktop" Categories "GNOME;GTK;Utility;Calendar;Core;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Contacts.desktop" Categories "GNOME;GTK;Utility;ContactManagement;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.DiskUtility.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FeedReader.desktop" Categories "Network;Feed;Utility;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Maps.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.SoundRecorder.desktop" Categories "GNOME;GTK;Utility;Audio;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.tweaks.desktop" Categories "GNOME;GTK;System;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Weather.Application.desktop" Categories "GNOME;GTK;Utility;Navigation;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pavucontrol.desktop" Categories "Audio;Mixer;System;GTK;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pcmanfm.desktop" Categories "Utility;Core;FileManager;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/playonlinux.desktop" Categories "Application;Emulator;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorntime.desktop" Categories "AudioVideo;Video;Player;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/postman.desktop" Categories "Development;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skype.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skype-desktop.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skypeforlinux.desktop" Categories "Application;Network;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/steam.desktop" Categories "Game;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/teamviewer.desktop" Categories "Network;RemoteAccess;FileTransfer;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tiled.desktop" Categories "Development;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tor-browser-en.desktop" Categories "Network;WebBrowser;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-editor.desktop" Categories "Development;IDE;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-monodevelop.desktop" Categories "Development;IDE;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsapp-desktop.desktop" Categories "Network;Chat;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsie.desktop" Categories "Network;Chat;Communication;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-et.desktop" Categories "QT;Office;Spreadsheet;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-wpp.desktop" Categories "QT;Office;Presentation;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-wps.desktop" Categories "QT;Office;WordProcessor;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xchat.desktop" Categories "Network;Communication;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Categories "ChromeApp;Education;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" Categories "ChromeApp;Office;WordProcessor;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-hkgndiocipalkpejnpafdbdlfdjihomd-Default.desktop.desktop" Categories "ChromeApp;Network;FileTransfer;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Categories "ChromeApp;Utility;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Categories "ChromeApp;Network;Navigation;"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Categories "ChromeApp;Network;Chat;Communication;"


# NAMES[RO]
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/atril.desktop" Name[ro] "Documente"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ca.desrt.dconf-editor.desktop" Name[ro] "Editor de configurări"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/caja-browser.desktop" Name[ro] "Fișiere"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.vinszent.GnomeTwitch.desktop" Name[ro] "Twitch"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/engrampa.desktop" Name[ro] "Arhive"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/eog.desktop" Name[ro] "Imagini"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/eom.desktop" Name[ro] "Imagini"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/evince.desktop" Name[ro] "Documente"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/galculator.desktop" Name[ro] "Calculator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnome-disks.desktop" Name[ro] "Discuri"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnome-system-monitor.desktop" Name[ro] "Monitor de Sistem"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnubg.desktop" Name[ro] "Table"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gparted.desktop" Name[ro] "Editor de Partiții"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gpicview.desktop" Name[ro] "Imagini"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/hardinfo.desktop" Name[ro] "Informații Hardware"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/leafpad.desktop" Name[ro] "Editor Text"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxhotkey-gtk.desktop" Name[ro] "Scurtături de tastatură"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxmusic.desktop" Name[ro] "Muzică"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxsession-default-apps.desktop" Name[ro] "Aplicații implicite"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxterminal.desktop" Name[ro] "Terminal"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-calc.desktop" Name[ro] "Calculator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-dictionary.desktop" Name[ro] "Dicționar"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-disk.desktop" Name[ro] "Discuri"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-disk-usage-analyzer.desktop" Name[ro] "Spațiu pe Disc"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-screenshot.desktop" Name[ro] "Captură de ecran"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-system-monitor.desktop" Name[ro] "Monitor de Sistem"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-terminal.desktop" Name[ro] "Terminal"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nemo.desktop" Name[ro] "Fișiere"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FileRoller.desktop" Name[ro] "Arhive"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pcmanfm.desktop" Name[ro] "Fișiere"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pluma.desktop" Name[ro] "Editor Text"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pluma.desktop" X-MATE-FullName[ro] "Editor Text"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/simple-scan.desktop" Name[ro] "Scanner"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/system-config-printer.desktop" Name[ro] "Configurare Imprimantă"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Thunar.desktop" Name[ro] "Fișiere"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xarchiver.desktop" Name[ro] "Arhive"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Name[ro] "Hărți"


# NAMES
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/atril.desktop" Name "Documents"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ca.desrt.dconf-editor.desktop" Name "Configuration Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/caja-browser.desktop" Name "Files"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/codeblocks.desktop" Name "Code::Blocks"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.teamviewer.TeamViewer.desktop" Name "TeamViewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.vinszent.GnomeTwitch.desktop" Name "Twitch"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/diffuse.desktop" Name "Diffuse"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/dosbox.desktop" Name "DosBox"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/engrampa.desktop" Name "Archive Manager"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/eom.desktop" Name "Image Viewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/fluxgui.desktop" Name "F.lux"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/fma-config-tool.desktop" Name "File Manager Actions Configurator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/galculator.desktop" Name "Calculator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gedit.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ghetto-skype.desktop" Name "Skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gimp.desktop" Name "GIMP"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnome-twofactorauth.desktop" Name "Authenticator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnubg.desktop" Name "Backgammon"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-chrome.desktop" Name "Chrome"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-chrome-unstable.desktop" Name "Chrome"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gparted.desktop" Name "Partition Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/hardinfo.desktop" Name "Hardware Information"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/idea.desktop" Name "IntelliJ"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/inkscape.desktop" Name "Inkscape"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce.desktop" Name "IntelliJ"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce-eap.desktop" Name "IntelliJ"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/io.elementary.code.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jetbrains-idea-ce.desktop" Name "IntelliJ"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/leafpad.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxmusic.desktop" Name "Music"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxsession-default-apps.desktop" Name "Default Applications"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxterminal.desktop" Name "Terminal"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-calc.desktop" Name "Calculator"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-dictionary.desktop" Name "Dictionary"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-disk-usage-analyzer.desktop" Name "Disk Usage Analyzer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-screenshot.desktop" Name "Screenshot"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-system-monitor.desktop" Name "System Monitor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-terminal.desktop" Name "Terminal"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/medit.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/messengerfordesktop.desktop" Name "Facebook Messenger"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/minecraft-launcher.desktop" Name "Minecraft"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nemo.desktop" Name "Files"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nfs2se.desktop" Name "Need for Speed 2"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nvidia-settings.desktop" Name "Nvidia Settings"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nylas.desktop" Name "GMail"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.baedert.corebird.desktop" Name "Twitter"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.freedesktop.Piper.desktop" Name "Mouse Settings"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Cheese.desktop" Name "Camera"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Epiphany.desktop" Name "Epiphany"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Evolution.desktop" Name "Mail"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FeedReader.desktop" Name "Feed Reader"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.gedit.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.pantheon.scratch.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pavucontrol.desktop" Name "Audio Settings"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pcmanfm.desktop" Name "Files"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pluma.desktop" Name "Text Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorntime-ce.desktop" Name "Popcorn Time"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pycharm-com-eap.desktop" Name "PyCharm"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/simple-scan.desktop" Name "Scanner"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/simplescreenrecorder.desktop" Name "Screen Recorder"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skypeforlinux.desktop" Name "Skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/steam.desktop" Name "Steam"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/teamviewer.desktop" Name "TeamViewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Thunar.desktop" Name "Files"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tor-browser-en.desktop" Name "Tor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/transmission-gtk.desktop" Name "Torrents"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-editor.desktop" Name "Unity Editor"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/unity-monodevelop.desktop" Name "MonoDevelop - Unity"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/virtualbox.desktop" Name "VirtualBox"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/visual-studio-code.desktop" Name "Code"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/code.desktop" Name "Code"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/vivaldi-preview.desktop" Name "Vivaldi"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/vlc.desktop" Name "VLC"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsie.desktop" Name "WhatsApp"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wireshark-gtk.desktop" Name "Wireshark"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wmail.desktop" Name "GMail"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xarchiver.desktop" Name "Archive Manager"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xchat.desktop" Name "XChat"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-aiahmijlpehemcpleichkcokhegllfjl-Default.desktop" Name "Duolingo"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" Name "Keep"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" Name "Maps"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Name "WhatsApp"

# WMCLASSES
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/amidst.desktop" StartupWMClass "amidst-Amidst"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/android-studio.desktop" StartupWMClass "jetbrains-studio"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Cisco-PacketTracer.desktop" StartupWMClass "PacketTracer6"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/com.teamviewer.TeamViewer.desktop" StartupWMClass "TeamViewer"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/fluxgui.desktop" StartupWMClass "Fluxgui.py"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/geogebra.desktop" StartupWMClass "org-geogebra-desktop-GeoGebra3D"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gimp.desktop" StartupWMClass "Gimp-2.10"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/godot.desktop" StartupWMClass "Godot"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-chrome.desktop" StartupWMClass "Google-chrome-stable"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/google-chrome-unstable.desktop" StartupWMClass "Google-chrome-unstable"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/idea.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/intellij-idea-ce-eap.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jetbrains-idea-ce.desktop" StartupWMClass "jetbrains-idea-ce"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/messengerfordesktop.desktop" StartupWMClass "fbmessenger"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/minecraft-launcher.desktop" StartupWMClass "Minecraft 1.13.2"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Monogame\ Pipeline.desktop" StartupWMClass "Pipeline"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/MonogamePipeline.desktop" StartupWMClass "Pipeline"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nfs2se.desktop" StartupWMClass "nfs2se"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FileRoller.desktop" StartupWMClass "File-Roller"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/picard.desktop" StartupWMClass ""
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/playonlinux.desktop" StartupWMClass "Mainwindow.py"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorn-time-ce.desktop" StartupWMClass "popcorntime"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorntime.desktop" StartupWMClass "crx_hecfofbbdfadifpemejbbdcjmfmboohj"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pycharm-community-edition.desktop" StartupWMClass "jetbrains-pycharm-ce"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skype-desktop.desktop" StartupWMClass "crx_monljlleikpphbhopghghdbggidfahha"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/skypeforlinux.desktop" StartupWMClass "Skype"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/teamviewer.desktop" StartupWMClass "TeamViewer.exe"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tor-browser-en.desktop" StartupWMClass "Tor Browser"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/visual-studio-code.desktop" StartupWMClass "Code"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/code.desktop" StartupWMClass "code-oss"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/whatsapp-desktop.desktop" StartupWMClass "whatsapp"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-et.desktop" StartupWMClass "Et"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-wpp.desktop" StartupWMClass "Wpp"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/wps-office-wps.desktop" StartupWMClass "Wps"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/www.octave.org-octave.desktop" StartupWMClass "octave-gui"

# EXEC
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/dropbox.desktop" Exec "dropbox start -i"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/messengerfordesktop.desktop" Exec "start-wmclass messengerfordesktop fbmessenger"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/monodevelop.desktop" Exec "env GNOME_DESKTOP_SESSION_ID="" monodevelop %F"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/nvidia-settings.desktop" Exec "gksu nvidia-settings"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorn-time-ce.desktop" Exec "start-wmclass popcorntime popcorntime"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/popcorntime.desktop" Exec "start-wmclass popcorntime popcorntime"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/steam.desktop" Exec "steam-start"

# MimeType
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxmusic.desktop" MimeType "application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/vorbis;audio/x-vorbis;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-mpegurl;audio/x-flac;audio/mp4;x-scheme-handler/itms;x-scheme-handler/itmss;"

# OnlyShowIn
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gnome-terminal.desktop" OnlyShowIn "GNOME;Unity;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lxterminal.desktop" OnlyShowIn "LXDE;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Nautilus.desktop" OnlyShowIn "GNOME;Unity;"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/pcmanfm.desktop" OnlyShowIn "LXDE;"

# Hide
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/7zFM.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/alltray.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/amidst.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/assistant.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/assistant-qt4.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/avahi-discover.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/bssh.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/bvnc.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/caffeine-indicator.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/CMake.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/cmake.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/cmake-gui.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/cups.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qv4l2.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qvidcap.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/designer.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/designer-qt4.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/electron.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/eog.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ffadomixer.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/freeciv-mp.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/freeciv-mp-gtk2.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/freeciv-server.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gksu.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gksu-properties.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gtk-lshw.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/gucharmap.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/htop.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ipython2.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ipython.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/laptop-mode-tools.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/libreoffice-base.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/libreoffice-draw.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/libreoffice-math.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/libreoffice-startcenter.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/linguist.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/linguist-qt4.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/lstopo.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-color-select.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/mate-search-tool.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/midori-private.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Monogame\ Pipeline.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/MonogamePipeline.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/openarena-server.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Cheese.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.FileRoller.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.font-viewer.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Screenshot.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jmc-jdk10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qdbusviewer.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qdbusviewer-qt4.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qtconfig-qt4.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/qv4l2.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/steam-native.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/steam-runtime.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jdk9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/policytool-jre9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/ibus-setup.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jconsole-jdk11.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/jvisualvm-jdk11.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jdk11.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun_java-jre11.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-javaws-jre8.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-javaws-jre9.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-javaws-jre10.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/sun-javaws-jre11.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/Thunar-bulk-rename.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/thunar-settings.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/thunar-volman-settings.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tilda.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tracker-needle.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/tracker-preferences.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/uxterm.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/vim.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xdvi.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/xterm.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/yelp.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/zenmap.desktop" NoDisplay "true"
set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/zenmap-root.desktop" NoDisplay "true"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-app-list.desktop" NoDisplay "true"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-aohghmighlieiainnegkcijnfilokake-Default.desktop" NoDisplay "false"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop" NoDisplay "false"
set_launcher_entry "$LOCAL_LAUNCHERS_PATH/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" NoDisplay "false"

[ -f "$GLOBAL_LAUNCHERS_PATH/io.elementary.files.desktop" ]  && set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/org.gnome.Nautilus.desktop" NoDisplay "true"

# Themes
set_theme "/usr/bin/tor-browser-en" "Adwaita"

rm -rf "/home/$USER_REAL/.local/share/applications/wine-*"
rm -rf "/home/$USER_REAL/.local/share/applications/wine"
rm -rf "/home/$USER_REAL/.config/menus/applications-merged/user-chrome-apps.menu"

# CREATE ICONS

if [ -f "/usr/bin/wine" ]; then
    if [ ! -f "winecfg.desktop" ]; then
        create_launcher "$GLOBAL_LAUNCHERS_PATH/winecfg.desktop"
        set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/winecfg.desktop" Name "Wine Configuration"
        set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/winecfg.desktop" Categories "Wine;Emulator;System;Settings;"
        set_launcher_entry "$GLOBAL_LAUNCHERS_PATH/winecfg.desktop" StartupWMClass "winecfg.exe"
    fi
fi

if [ -f "/usr/bin/winetricks" ]; then
    NEWLAUNCHER="$GLOBAL_LAUNCHERS_PATH/winetricks.desktop"

    if [ ! -f "winetricks.desktop" ]; then
        create_launcher "$NEWLAUNCHER"
    fi

    set_launcher_entry "$NEWLAUNCHER" Name "Winetricks"
    set_launcher_entry "$NEWLAUNCHER" Icon "winetricks"
    set_launcher_entry "$NEWLAUNCHER" Categories "Wine;Emulator;"
    set_launcher_entry "$NEWLAUNCHER" StartupWMClass "winetricks"
    set_launcher_entry "$NEWLAUNCHER" NoDisplay "true"
fi

if [ -f "/usr/bin/mono" ]; then
    NEWLAUNCHER="$GLOBAL_LAUNCHERS_PATH/run-mono.desktop"

    if [ ! -f "$NEWLAUNCHER" ]; then
        create_launcher "$NEWLAUNCHER"
    fi

    set_launcher_entry "$NEWLAUNCHER" Name "Run Software with Mono"
    set_launcher_entry "$NEWLAUNCHER" Icon "mono"
    set_launcher_entry "$NEWLAUNCHER" Exec "mono %U"
    set_launcher_entry "$NEWLAUNCHER" Terminal "true"
    set_launcher_entry "$NEWLAUNCHER" NoDisplay "true"
fi

#if [ -f "/usr/bin/python" ]; then
#    NEWLAUNCHER="$GLOBAL_LAUNCHERS_PATH/run-python.desktop"
#
#    if [ ! -f "$NEWLAUNCHER" ]; then
#        create_launcher "$NEWLAUNCHER"
#    fi
#
#    set_launcher_entry "$NEWLAUNCHER" Name "Python"
#    set_launcher_entry "$NEWLAUNCHER" Icon "python"
#    set_launcher_entry "$NEWLAUNCHER" Exec "bash -c 'python %f ; /bin/bash'"
#    set_launcher_entry "$NEWLAUNCHER" StartupWMClass "python"
#    set_launcher_entry "$NEWLAUNCHER" MimeType "text/x-python"
#    set_launcher_entry "$NEWLAUNCHER" Terminal "true"
#    set_launcher_entry "$NEWLAUNCHER" NoDisplay "true"
#fi

if [ -d "/opt/android-studio" ]; then
    if [ ! -f "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" ]; then
        create_launcher "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop"
    fi

    if [ ! -f "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop" ]; then
        create_launcher "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop"
    fi

    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" Name "Android SDK Manager"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" Exec "\/home\/"$USER_REAL"\/Android\/Sdk\/tools\/android sdk"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" Categories "Development;"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" StartupWMClass "Android SDK Manager"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" Icon "android-sdk"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-sdk-manager.desktop" NoDisplay "true"

    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop" Name "Android Virtual Device Manager"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop" Exec "\/home\/"$USER_REAL"\/Android\/Sdk\/tools\/android avd"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop" Categories "Emulator;"
    set_launcher_entry "$LOCAL_LAUNCHERS_PATH/android-avd-manager.desktop" Icon "android-sdk"
fi

# CREATE STEAM ICONS

WMCLASSES_FILE="/home/$USER_REAL/Documents/.steam-wmclasses"

if [ -d "$STEAM_APPS_PATH" ] && [ -d "$ICON_THEME_PATH" ]; then
    if [ ! -d "$STEAM_LAUNCHERS_PATH" ]; then
        mkdir -p "$STEAM_LAUNCHERS_PATH"
    fi

    APP_IDS=$(ls "$STEAM_APPS_PATH" | grep "appmanifest_.*.acf" | awk -F_ '{print $2}' | awk -F. '{print $1}')

    for APP_ID in $APP_IDS; do
        if [ -f "$ICON_THEME_PATH/48/apps/steam_icon_$APP_ID.svg" ]; then
            APP_NAME=$(grep -h "\"name\"" "$STEAM_APPS_PATH/appmanifest_$APP_ID.acf" | sed 's/\"name\"//' | grep -o "\".*\"" | sed 's/\"//g')
            APP_WMCLASS=$(echo "$APP_NAME" | sed 's/\ //g')

            if [ ! -f "$WMCLASSES_FILE" ]; then
                touch "$WMCLASSES_FILE"
            fi

            if [ $(grep -c "^$APP_ID=" "$WMCLASSES_FILE") -ne 0 ]; then
                APP_WMCLASS=$(cat "$WMCLASSES_FILE" | grep "^$APP_ID=" | awk -F= '{print $2}')
            else
                echo "CANNOT GET WMCLASS FOR STEAMAPP $APP_ID - $APP_NAME"
            fi

            create_launcher "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Name "$APP_NAME"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Comment "Play $APP_NAME on Steam"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Comment[ro] "Joacă $APP_NAME pe Steam"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Keywords "Game;Steam;$APP_ID;$APP_NAME;"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Keywords[ro] "Joc;Steam;$APP_ID;$APP_NAME;"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Exec "steam steam:\/\/rungameid\/$APP_ID"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Icon "steam_icon_$APP_ID"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" Categories "Game;Steam;"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" StartupWMClass "$APP_WMCLASS"
            set_launcher_entry "$STEAM_LAUNCHERS_PATH/app_$APP_ID.desktop" NoDisplay "true"
        fi
    done

    chown -R $USER_REAL "$STEAM_LAUNCHERS_PATH"
fi

# Dropbox tray icons
if [ -e "/usr/bin/dropbox" ]; then
    DROPBOX_TRAY_ICONS_PATH="/home/$USER_REAL/Pictures/Icons/Trays/opt/dropbox/images/hicolor/16x16/status"

    if [ -d "$DROPBOX_TRAY_ICONS_PATH" ]; then
        DROPBOX_DIST_NAME=$(ls "/home/$USER_REAL/.dropbox-dist/" | grep "dropbox-lnx")

        cp -rf "$DROPBOX_TRAY_ICONS_PATH" "/opt/dropbox/images/hicolor/16x16/"
        cp -rf "$DROPBOX_TRAY_ICONS_PATH" "/home/$USER_REAL/.dropbox-dist/$DROPBOX_DIST_NAME/images/hicolor/16x16/"

        # TODO: Check if it is currently running
        #killall dropbox
        #sudo -u $USER_REAL "dropbox start" </dev/null &>/dev/null &
    fi
fi

# Rebuild icon theme caches
ICON_THEMES=$(find "/usr/share/icons/" -mindepth 1 -type d)

for ICON_THEME in $ICON_THEMES; do
    if [ -f "/usr/share/icons/$ICON_THEMES/index.theme" ]; then
        gtk-update-icon-cache "/usr/share/icons/$ICON_THEME"
    fi
done

update-desktop-database
