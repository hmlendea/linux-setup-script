#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/config.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

[ "${OS}" != "Linux" ] && exit
(! ${HAS_GUI}) && exit

ICON_THEME=$(sudo -u "${USER_REAL}" -H gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
ICON_THEME_PATH="${ROOT_USR_SHARE}/icons/${ICON_THEME}"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/amidst.desktop" \
    StartupWMClass "amidst-Amidst"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/GameConqueror.desktop" Categories "Utility;"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/gtk-lshw.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/hardinfo.desktop" \
    Categories "System;Monitor;" \
    Icon "hardinfo" \
    Name "Hardware Information" \
    Name[ro] "Informații Hardware"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/lstopo.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/lxhotkey-gtk.desktop" Name[ro] "Scurtături de tastatură"
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/lxappearance.desktop" \
    Name "Look and Feel" \
    Name[ro] "Tema Interfeței"
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/lxsession-edit.desktop" \
    Name "Desktop Session Settings" \
    Name[ro] "Opțiuni ale Sesiunilor Desktop"
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/lxsession-default-apps.desktop" \
    Name "Default Applications" \
    Name[ro] "Aplicații Implicite"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/mate-color-select.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/mate-search-tool.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/nm-connection-editor.desktop" \
    Name "Network Connections" \
    Name[ro] "Conexiuni de Rețea" \
    NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/org.gnome.SoundRecorder.desktop" Categories "GNOME;GTK;Utility;Audio;"
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/org.gnome.tweaks.desktop" \
    Icon "utilities-tweak-tool" \
    Categories "GNOME;GTK;System;"
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/pcmanfm-desktop-pref.desktop" \
    Name "Desktop Customiser" \
    Name[ro] "Personalizare Desktop"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/picard.desktop" StartupWMClass ""
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/plank.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/qv4l2.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/qvidcap.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/simplescreenrecorder.desktop" Name "Screen Recorder"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/stoken-gui-small.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/stoken-gui.desktop" NoDisplay true
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/system-config-printer.desktop" Name[ro] "Configurare Imprimantă"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/virtualbox.desktop" Name "VirtualBox"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/wireshark-gtk.desktop" Name "Wireshark"
set_launcher_entry "${LOCAL_LAUNCHERS_DIR}/chrome-app-list.desktop" NoDisplay true

##################
### App Stores ###
##################
APP_STORE_KEYWORDS="Updates;Upgrade;Sources;Repositories;Install;Uninstall;Program;Software;App;Store;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Software.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.kde.discover.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Application Store" \
        Keywords "Preferences;Flatpak;FlatHub;${APP_STORE_KEYWORDS}"
done

########################
### ARCHIVE MANAGERS ###
########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/engrampa.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/xarchiver.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Archives" \
        Name[ro] "Arhive"
done
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.FileRoller.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        StartupWMClass "File-Roller"
done
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/7zFM.desktop" NoDisplay true

#############
### AVAHI ###
#############
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/avahi-discover.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/bssh.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/bvnc.desktop"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

##########################
### BLUETOOTH MANAGERS ###
##########################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/blueman-manager.desktop" \
    Name "Bluetooth Manager" \
    Name[ro] "Manager Bluetooth"

############################
### BOOTABLE MEDIA MAKER ###
############################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/balena-etcher-electron.desktop" \
    Name "Etcher" \
    Name[ro] "Etcher" \
    Categories "Filesystem;X-GNOME-Utilities;"

###################
### Calculators ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/galculator.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-calc.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Calculator.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Calculator.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Calculator" \
        Name[ro] "Calculator"
done

################
### Calendar ###
################
CALENDAR_CATEGORIES="Office;Calendar;Utility;Core;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Calendar.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Calendar.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Calendar.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Calendar" \
        Name[ro] "Calendar" \
        Icon "calendar" \
        Categories "GNOME;GTK;${CALENDAR_CATEGORIES}"
done

##############
### CAMERA ###
##############
CAMERA_APP_KEYWORDS="photo;video;webcam;camera;selfie;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Cheese.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Cheese.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Cheese.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Camera" \
        Name[ro] "Cameră" \
        Icon "camera" \
        Keywords "${CAMERA_APP_KEYWORDS}cheese;" \
        Keywords[ro] "${CAMERA_APP_KEYWORDS}cheese;foto;cameră web;poze;"
done

#################
### CHAT APPS ###
#################
CHAT_APP_CATEGORIES="Network;Chat;InstantMessaging;Communication;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/discord.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.discordapp.Discord.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.discordapp.Discord.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Discord" \
        Icon "discord" \
        Categories "${CHAT_APP_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/teams.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/teams-for-linux.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/teams-insiders.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.github.IsmaelMartinez.teams_for_linux.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.microsoft.Teams.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.microsoft.Teams.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.github.IsmaelMartinez.teams_for_linux.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Teams" \
        Name[ro] "Teams" \
        Icon "teams" \
        Categories "${CHAT_APP_CATEGORIES}" \
        StartupNotify false
done

#if [ "$(get_gpu_family)" = "Intel" ]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/teams.desktop" Exec "/usr/bin/teams --disable-gpu --no-sandbox"
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/teams-insiders.desktop" Exec "/usr/bin/teams-insiders --disable-gpu --no-sandbox"
#fi

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/meowgram.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/telegramdesktop.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.telegram.desktop.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.telegram.desktop.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Telegram" \
        Name[ro] "Telegram"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/meowgram.desktop" Categories "GTK;${CHAT_APP_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/telegramdesktop.desktop" Categories "Qt;${CHAT_APP_CATEGORIES}"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/whatsapp-for-linux.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/whatsapp-desktop.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/whatsapp-nativefier.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/whatsapp-nativefier-dark.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/whatsie.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/io.github.mimbrero.WhatsAppDesktop.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/io.github.mimbrero.WhatsAppDesktop.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "WhatsApp" \
        Name[ro] "WhatsApp" \
        Icon "whatsapp" \
        Categories "${CHAT_APP_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/io.github.mimbrero.WhatsAppDesktop.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/io.github.mimbrero.WhatsAppDesktop.desktop"; do
    set_launcher_entry "${LAUNCHER}" \
        StartupWMClass "whatsapp-desktop-linux"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/whatsapp-desktop.desktop" StartupWMClass "whatsapp"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/whatsapp-nativefier.desktop" StartupWMClass "whatsapp-nativefier-d40211"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/whatsapp-nativefier-dark.desktop" StartupWMClass "whatsapp-nativefier-d52542"
set_launcher_entry "${LOCAL_LAUNCHERS_DIR}/chrome-nfjdjopfnbnkmfldmeffmhgodmlhdnei-Default.desktop" Categories "ChromeApp;${CHAT_APP_CATEGORIES}"

##############
### CITRIX ###
##############
if [ -d "${ROOT_OPT}/Citrix" ]; then
    [ ! -f "${GLOBAL_LAUNCHERS_DIR}wfsplash.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/wfsplash.desktop"

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/citrix-wfica.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/citrix-configmgr.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/citrix-conncenter.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/citrix-workspace.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/configmgr.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/conncentre.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/wfcmgr.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/wfsplash.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/wfica.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Icon "citrix-receiver" \
            NoDisplay true
    done

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/citrix-configmgr.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/configmgr.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "Citrix Receiver Preferences" \
            Name[ro] "Configurare Receptor Citrix" \
            StartupWMClass "Configmgr"
    done

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/citrix-conncenter.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/conncentre.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "Citrix Connection Centre" \
            Name[ro] "Centrul de conexiuni Citrix" \
            StartupWMClass "Conncenter"
    done

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/wfcmgr.desktop" \
        Name "Citrix Receiver Self Service" \
        Name[ro] "Asistență Receptor Citrix" \
        StartupWMClass "Wfcmgr"

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/wfsplash.desktop" \
        Name "Citrix Splash" \
        Categories "Application;Network;X-Red-Hat-Base;X-SuSE-Core-Internet;" \
        StartupWMClass "Wfica_Splash" # InitPanel_popup

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/citrix-wfica.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/wfica.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "Citrix Receiver" \
            Name[ro] "Receptor Citrix" \
            StartupWMClass "Wfica" \
            Exec "/opt/Citrix/ICAClient/wfica.sh %U" \
            TryExec ""
    done
else
    remove "${GLOBAL_LAUNCHERS_DIR}/wfsplash.desktop"
fi

#############
### CMAKE ###
#############
if does_bin_exist "cmake"; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/cmake.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/cmake-gui.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/CMake.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Icon "cmake" \
            NoDisplay true
    done
fi

################
### Contacts ###
################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Contacts.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Contacts.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Contacts.desktop"; do
    set_launcher_entries "${LAUNCHER}" Categories "GNOME;GTK;Utility;ContactManagement;"
done

################################
### DEVELOPMENT ENVIRONMENTS ###
################################
IDE_CATEGORIES="Development;IDE;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/code-oss.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/code.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/codium.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/visual-studio-code.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.visualstudio.code.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.visualstudio.code.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Code" \
        Name[ro] "Code" \
        GenericName "Code" \
        Icon "code" \
        Keywords "VS;VSCode;Visual;Studio;Code;" \
        Categories "${IDE_CATEGORIES};TextEditor;"
done

for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.jetbrains.PyCharm-Community.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.jetbrains.PyCharm-Community.desktop"; do
    set_launcher_entries "${LAUNCHER}" Name "PyCharm"
done

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/monodevelop.desktop" \
    Exec "env GNOME_DESKTOP_SESSION_ID="" monodevelop %F" \
    Categories "${IDE_CATEGORIES}"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/unity-editor.desktop" \
    Name "Unity Editor" \
    Icon "unity-editor-icon" \
    Categories "${IDE_CATEGORIES}"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/unity-monodevelop.desktop" \
    Name "MonoDevelop - Unity" \
    Icon "unity-monodevelop" \
    Categories "${IDE_CATEGORIES}"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/codeblocks.desktop" \
    Name "Code::Blocks" \
    Categories "GTK;${IDE_CATEGORIES}"

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/android-studio.desktop" \
    StartupWMClass "jetbrains-studio"

if [[ "${ARCH_FAMILY}" == "x86" ]]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/code-oss.desktop" StartupWMClass "code"
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/code-oss-url-handler.desktop" NoDisplay true
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/code.desktop" StartupWMClass "code-oss"
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/visual-studio-code.desktop" StartupWMClass "Code"
elif [[ "${ARCH_FAMILY}" == "arm" ]]; then
    set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/code-oss.desktop" StartupWMClass "Code - OSS (headmelted)"
fi

####################
### DICTIONARIES ###
####################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/mate-dictionary.desktop" \
    Name "Dictionary" \
    Name[ro] "Dicționar"

############################
### DISK USAGE ANALYZERS ###
############################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/baobab.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-disk-usage-analyzer.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.baobab.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.baobab.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.baobab.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Disk Usage" \
        Name[ro] "Utilizarea Discului" \
        OnlyShowIn ""
done

######################
### DISK UTILITIES ###
######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gnome-disks.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-disk.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name[ro] "Discuri" \
        Icon "gnome-disks"
done

########################
### DOCUMENT VIEWERS ###
########################
DOCUMENT_VIEWER_CATEGORIES="Office;Viewer;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/epdfview.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/evince.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Evince.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Evince.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Evince.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Documents" \
        Name[ro] "Documente"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/atril.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/epdfview.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GTK;${DOCUMENT_VIEWER_CATEGORIES}"
done

if does_bin_exist "evince"; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/evince.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Evince.desktop"; do
        set_launcher_entry "${LAUNCHER}" Categories "GNOME;GTK;${DOCUMENT_VIEWER_CATEGORIES}"
    done
fi

################
### ELECTRON ###
################
if does_bin_exist "electron"; then
    for ELECTRON_VERSION in "" {10..16}; do
        set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/electron${ELECTRON_VERSION}.desktop" NoDisplay true
    done
fi

#################
### EMULATORS ###
#################
EMULATOR_CATEGORIES="Game;Application;Emulator;"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/dosbox.desktop" \
    Name "DosBox" \
    Categories ${EMULATOR_CATEGORIES}

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/PCSX2.desktop" \
    Icon "pcsx2" \
    Categories ${EMULATOR_CATEGORIES}

##########################
### EXTENSION MANAGERS ###
##########################
EXTENSION_MANAGER_CATEGORIES="System;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Extensions.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Shell.Extensions.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.mattjakeman.ExtensionManager.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Extensions" \
        Name[ro] "Extensii" \
        Icon "org.gnome.Extensions" \
        Categories "GNOME;GTK;${EXTENSION_MANAGER_CATEGORIES}"
done

if is_flatpak_installed "com.mattjakeman.ExtensionManager"; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Extensions.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Shell.Extensions.desktop"; do
        set_launcher_entry "${LAUNCHER}" NoDisplay true
    done
fi

####################
### FEED READERS ###
####################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/org.gnome.FeedReader.dekstop" \
    Name "Feed Reader" \
    Icon "feedreader" \
    Categories "GNOME;GTK;Network;Feed;Utility;"

#####################
### FILE MANAGERS ###
#####################
FILE_MANAGER_CATEGORIES="Utility;Core;FileManager;FileTools;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/caja-browser.dekstop" \
                "${GLOBAL_LAUNCHERS_DIR}/io.elementary.files.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Nautilus.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.kde.dolphin.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/pcmanfm.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Files" \
        Name[ro] "Fișiere"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/caja.dekstop" \
                "${GLOBAL_LAUNCHERS_DIR}/Thunar.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/thunar.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/pcmanfm.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GTK;${FILE_MANAGER_CATEGORIES}"
done

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Nautilus.desktop" \
    Exec "nautilus ${HOME}" \
    Categories "GNOME;GTK;${FILE_MANAGER_CATEGORIES}"

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/io.elementary.files.desktop" Categories "Pantheon;GTK;${FILE_MANAGER_CATEGORIES}"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/org.kde.dolphin.desktop" Categories "KDE;Qt;${FILE_MANAGER_CATEGORIES}"

if does_bin_exist "thunar"; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/Thunar-bulk-rename.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/thunar-bulk-rename.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/thunar-settings.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/thunar-volman-settings.desktop"; do
        set_launcher_entry "${LAUNCHER}" NoDisplay true
    done
fi

#####################
### Font Managers ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.font-viewer.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.font-viewer.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.font-viewer.desktop"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

#############
### Games ###
#############
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/gnubg.desktop" \
    Name "Backgammon" \
    Name[ro] "Table"

if does_bin_exist "minecraft-launcher" "com.mojang.Minecraft" "org.prismlauncher.PrismLauncher"; then
    MC_DIR="${HOME}/.minecraft"
    MC_EXECUTABLE="minecraft-launcher"

    if is_flatpak_installed "com.mojang.Minecraft"; then
        MC_DIR="${HOME_VAR_APP}/com.mojang.Minecraft/.minecraft"
        MC_EXECUTABLE="com.mojang.Minecraft"
    elif is_flatpak_installed "org.prismlauncher.PrismLauncher"; then
        MC_EXECUTABLE="org.prismlauncher.PrismLauncher"
    fi

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/minecraft-launcher.desktop" \
                    "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.mojang.Minecraft.desktop" \
                    "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.prismlauncher.PrismLauncher.desktop" \
                    "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.mojang.Minecraft.desktop" \
                    "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.prismlauncher.PrismLauncher.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "Minecraft" \
            Comment "Play Minecraft" \
            Comment[de] "Spiele Minecraft" \
            Comment[es] "Juega Minecraft" \
            Comment[ro] "Joacă Minecraft" \
            Keywords "Game;Minecraft;MC;" \
            Keywords[de] "Spiel;Minecraft;MC;" \
            Keywords[es] "Juego;Minecraft;MC;" \
            Keywords[ro] "Joc;Minecraft;MC;" \
            Exec "${MC_EXECUTABLE}" \
            Icon "minecraft" \
            Categories "Game;" \
            PrefersNonDefaultGPU true
    done

    if [ -d "${MC_DIR}/versions" ]; then
        MC_LATEST_RELEASE=$(jq '.latest.release' "${MC_DIR}/versions/version_manifest_v2.json" | sed 's/\"//g')

        MC_VANILLA_LAUNCHER_FILE="${LOCAL_LAUNCHERS_DIR}/minecraft/minecraft_${MC_LATEST_RELEASE}_vanilla.desktop"
        MC_MODDED_LAUNCHER_FILE="${LOCAL_LAUNCHERS_DIR}/minecraft/minecraft_${MC_LATEST_RELEASE}_modded.desktop"
        
        [ ! -f "${MC_VANILLA_LAUNCHER_FILE}" ] && create_launcher "${MC_VANILLA_LAUNCHER_FILE}"
        [ ! -f "${MC_MODDED_LAUNCHER_FILE}" ] && create_launcher "${MC_MODDED_LAUNCHER_FILE}"

        for MC_LAUNCHER_FILE in "${MC_VANILLA_LAUNCHER_FILE}" \
                                "${MC_MODDED_LAUNCHER_FILE}"; do
            set_launcher_entries "${MC_LAUNCHER_FILE}" \
                Name "Minecraft" \
                FullName "Minecraft ${MC_LATEST_RELEASE}" \
                Comment "Play Minecraft ${MC_LATEST_RELEASE}" \
                Comment[de] "Spiele Minecraft ${MC_LATEST_RELEASE}" \
                Comment[es] "Juega Minecraft ${MC_LATEST_RELEASE}" \
                Comment[ro] "Joacă Minecraft ${MC_LATEST_RELEASE}" \
                Keywords "Game;Minecraft;" \
                Keywords[de] "Spiel;Minecraft;" \
                Keywords[es] "Juego;Minecraft;" \
                Keywords[ro] "Joc;Minecraft;" \
                Exec "${MC_EXECUTABLE}" \
                Icon "minecraft" \
                Categories "Game;" \
                PrefersNonDefaultGPU true \
                NoDisplay true
        done

        set_launcher_entry "${MC_VANILLA_LAUNCHER_FILE}" StartupWMClass "Minecraft ${MC_LATEST_RELEASE}"
        set_launcher_entry "${MC_MODDED_LAUNCHER_FILE}" StartupWMClass "Minecraft* ${MC_LATEST_RELEASE}"
    fi
fi

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/nfs2se.desktop" \
    Name "Need for Speed 2" \
    Icon "nfs2se" \
    StartupWMClass "nfs2se"

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/org.gnome.gnome-2048.desktop" Icon "2048"

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/openarena-server.desktop" NoDisplay true

#####################
### IMAGE EDITORS ###
#####################
IMAGE_EDITOR_CATEGORIES="Graphics;2DGraphics"

if does_bin_exist "gimp" "org.gimp.GIMP"; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gimp.desktop" \
                    "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gimp.GIMP.desktop" \
                    "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gimp.GIMP.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "GIMP" \
            Categories "GTK;${IMAGE_EDITOR_CATEGORIES};RasterGraphics;" \
            StartupWMClass "Gimp-2.10" \
            StartupNotify false
    done

    [ ! -f "${GLOBAL_LAUNCHERS_DIR}/gmic-qt.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/gmic-qt.desktop"

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/gmic-qt.desktop" \
        Exec "gmic_qt" \
        Name "GMIC QT for GIMP" \
        Name[ro] "GMIC QT pentru GIMP" \
        Icon "gimp" \
        StartupWMClass "gmic_qt" \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/gmic-qt.desktop"
fi

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/inkscape.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.inkscape.Inkscape.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.inkscape.Inkscape.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.inkscape.Inkscape.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Inkscape" \
        Categories "GTK;${IMAGE_EDITOR_CATEGORIES};VectorGraphics;"
done

#####################
### IMAGE VIEWERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gpicview.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/eog.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/eom.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.eog.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.eog.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Loupe.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.eog.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Loupe.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Images" \
        Name[ro] "Imagini" \
        Icon "eog" \
        Keywords "Photo;Picture;Slideshow;Graphics;Image Viewer;"
done

########################
### JAVA - JRE & JDK ###
########################
if does_bin_exist "java"; then
    [ ! -f "${GLOBAL_LAUNCHERS_DIR}/run-java.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/run-java.desktop"

    for JAVA_VERSION in {8..24}; do
        for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/jconsole-jdk${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/jmc-jdk${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/jvisualvm-jdk${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/policytool-jdk${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/policytool-jre${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/sun_java-jdk${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/sun_java-jre${JAVA_VERSION}.desktop" \
                        "${GLOBAL_LAUNCHERS_DIR}/sun_javaws-jre${JAVA_VERSION}.desktop"; do
            set_launcher_entries "${LAUNCHER}" \
                Icon "java" \
                NoDisplay true
        done
    done

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/run-java.desktop" \
        Name "Java" \
        Icon "java" \
        Exec "java -jar %U" \
        Terminal true \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/run-java.desktop"
fi

###################
### LOG VIEWERS ###
###################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/mate-system-log.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Logs.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Logs" \
        Name[ro] "Loguri" \
        OnlyShowIn ""
done

####################
### MAIL CLIENTS ###
####################
MAIL_APP_CATEGORIES="Network;Email;"
MAIL_APP_KEYWORDS="Email;Mail;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/electron-mail.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Evolution.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.github.vladimiry.ElectronMail.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.github.vladimiry.ElectronMail.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "${MAIL_APP_CATEGORIES}" \
        NoDisplay "false"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/electron-mail.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.github.vladimiry.ElectronMail.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.github.vladimiry.ElectronMail.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Proton Mail" \
        Icon "protonmail-desktop" \
        Keywords "${MAIL_APP_KEYWORDS}Electron;"
done

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Evolution.desktop" \
    Name "Mail" \
    Name[ro] "Mail" \
    Icon "mail-client" \
    Keywords "${MAIL_APP_KEYWORDS}"

############
### Maps ###
############
MAPS_APP_CATEGORIES="Utility;Navigation;"
for LAUNCHER in "${LOCAL_LAUNCHERS_DIR}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Maps.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Maps.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Maps.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Maps" \
        Name[ro] "Hărți" \
        NoDisplay "false"
done
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Maps.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Maps.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Maps.desktop"; do
    set_launcher_entry "${LAUNCHER}" \
        Categories "GNOME;GTK;${MAPS_APP_CATEGORIES}"
done

set_launcher_entry "${LOCAL_LAUNCHERS_DIR}/chrome-lneaknkopdijkpnocmklfnjbeapigfbh-Default.desktop" \
    Categories "ChromeApp;${MAPS_APP_CATEGORIES}"

################
### MonoGame ###
################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/Monogame\ Pipeline.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/MonogamePipeline.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        NoDisplay true \
        StartupWMClass "Pipeline"
done

#####################
### Music players ###
#####################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/lxmusic.desktop" \
    Name "Music" \
    Name[ro] "Muzică" \
    MimeType "application/x-ogg;application/ogg;audio/x-vorbis+ogg;audio/vorbis;audio/x-vorbis;audio/x-scpls;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-mpegurl;audio/x-flac;audio/mp4;x-scheme-handler/itms;x-scheme-handler/itmss;"

#############
### Notes ###
#############
for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.simplenote.Simplenote.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/google-keep.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.simplenote.Simplenote.desktop" \
                "${LOCAL_LAUNCHERS_DIR}/chrome-hmjkmjkepdijhoojdojkdfohbdgmmhki-Default.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "Utility;" \
        NoDisplay false \
        StartupNotify false
done
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/google-keep.desktop" StartupWMClass "google-keep-nativefier-d04d04"
set_launcher_entries "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.simplenote.Simplenote.desktop" \
    Name "Simplenote" \
    Icon "simplenote"

##############
### NVIDIA ###
##############
NVIDIA_SETTINGS_EXEC="/usr/bin/nvidia-settings --config=\"${XDG_CONFIG_HOME}/nvidia/settings\""

if does_bin_exist "nvidia-settings"; then
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/nvidia-settings.desktop" \
        Name "Nvidia Settings" \
        Name[ro] "Setări Nvidia" \
        Icon "nvidia-settings" \
        Categories "System;" \
        Exec "${NVIDIA_SETTINGS_EXEC}"

    does_bin_exist "optirun" && set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/nvidia-settings.desktop" \
        Exec "optirun -b none ${NVIDIA_SETTINGS_EXEC} -c :8"
fi

#################
### OCR Tools ###
#################
for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.github.dynobo.normcap.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.github.dynobo.normcap"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Text Extractor" \
        Name[ro] "Extrăgător de Text" \
        Icon "ocrfeeder"
done

###################
### Office Apps ###
###################
if does_bin_exist "libreoffice"; then
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-base.desktop" \
        Name "Base" \
        Name[ro] "Baze" \
        NoDisplay true
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-calc.desktop" \
        Name "Calc" \
        Name[ro] "Calcul" \
        NoDisplay true
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-draw.desktop" \
        Name "Draw" \
        Name[ro] "Schițe" \
        NoDisplay true
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-impress.desktop" \
        Name "Impress" \
        Name[ro] "Prezentări" \
        NoDisplay true
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-math.desktop" \
        Name "Math" \
        Name[ro] "Mate" \
        NoDisplay true
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/libreoffice-writer.desktop" \
        Name "Writer" \
        Name[ro] "Scriitor" \
        NoDisplay true
fi

#########################
### Partition Editors ###
#########################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/gparted.desktop" \
    Name "Partition Editor" \
    Name[ro] "Editor de Partiții"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/org.gnome.DiskUtility.desktop" Categories "GNOME;GTK;System;"

#########################
### Password Managers ###
#########################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.seahorse.Application.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.seahorse.Application.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.seahorse.Application.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name[ro] "Parole și Chei" \
        NoDisplay true
done

####################
### PHOTO ALBUMS ###
####################
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Photos.desktop" \
    Icon "multimedia-photo-manager"

###############
### POSTMAN ###
###############
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/postman.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.getpostman.Postman.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.getpostman.Postman.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Postman" \
        Icon "postman" \
        Categories "Development;" \
        StartupNotify false
done

###########################
### Printing & Scanning ###
###########################
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/cups.desktop" NoDisplay true
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/simple-scan.desktop" \
    Name "Scanner" \
    Name[ro] "Scanner"

##############
### PYTHON ###
##############
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/ipython.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/ipython2.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Categories "Development;" \
        NoDisplay true \
        Icon "ipython"
done

######################
### SCREENSHOOTERS ###
######################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gscreenshot.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-screenshot.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Screenshot.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.kde.spectacle.desktop"; do
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

### System Settings
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/gnome-control-center.desktop" \
    Name "Settings" \
    Name[ro] "Setări" \
    Categories "GNOME;GTK;${SETTINGS_APP_CATEGORIES}"

### Configuration Settings
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/ca.desrt.dconf-editor.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/ca.desrt.dconf-editor.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/ca.desrt.dconf-editor.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Configurator" \
        Name[ro] "Configurator" \
        Keywords "settings;configuration;dconf;" \
        Keywords[ro] "settings;configuration;dconf;setări;configurare;configurări;configurație;" \
        Icon "dconf-editor" \
        Categories "GNOME;GTK;${SETTINGS_APP_CATEGORIES}"
done

### Audio Settings
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/pavucontrol.desktop" \
    Categories "GTK;System;Audio;Mixer;" \
    Name "Audio Settings" \
    Name[ro] "Setări Audio"

### Mouse Settings
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/org.freedesktop.Piper.desktop" \
    Name "Mouse Settings" \
    Icon "gnome-settings-mouse" \
    Categories "GNOME;GTK;System;"

### Network Displays
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.NetworkDisplays.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.NetworkDisplays.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.NetworkDisplays.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Network Displays" \
        Name[ro] "Monitoare în Rețea"
done

### RGB Settings
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/openrgb.desktop" \
    Categories "Qt;${SETTINGS_APP_CATEGORIES}"

#############
### STEAM ###
#############
if does_bin_exist "steam" "com.valvesoftware.Steam"; then
    remove "${GLOBAL_LAUNCHERS_DIR}/steam-native.desktop"

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/steam-runtime.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/valve-URI-steamvr.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/valve-URI-vrmonitor"; do
        set_launcher_entry "${LAUNCHER}" NoDisplay true
    done

    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/steam.desktop" \
                    "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.valvesoftware.Steam.desktop" \
                    "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.valvesoftware.Steam.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "Steam" \
            Name[ro] "Steam" \
            Categories "Game;Steam;" \
            StartupWMClass "steamwebhelper"
    done

    if does_bin_exist "steam-start"; then
        set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/steam.desktop" Exec "steam-start"
    fi

    [ ! -f "${GLOBAL_LAUNCHERS_DIR}/steam-streaming-client.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/steam-streaming-client.desktop"
    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/steam-streaming-client.desktop" \
        Name "Steam Remote Play" \
        Comment "Steam Streaming Client" \
        Exec "steam" \
        Icon "steam" \
        Categories "Game;Steam;" \
        StartupWMClass "streaming_client" \
        NoDisplay true

    set_launcher_entries "${LOCAL_LAUNCHERS_DIR}/valve-vrmonitor.desktop" \
        Name "SteamVR Monitor" \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/steam-streaming-client.desktop"
fi

#####################
### TASK MANAGERS ###
#####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gnome-system-monitor.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-system-monitor.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "System Monitor" \
        Name[ro] "Monitor de Sistem"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/lxtask.desktop" Name[ro] "Manager de Activități"

###################
### TEAM VIEWER ###
###################
if does_bin_exist teamviewer; then
    for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/com.teamviewer.TeamViewer.desktop" \
                    "${GLOBAL_LAUNCHERS_DIR}/teamviewer.desktop"; do
        set_launcher_entries "${LAUNCHER}" \
            Name "TeamViewer" \
            Name[ro] "TeamViewer" \
            Icon "teamviewer" \
            Categories "Network;RemoteAccess;FileTransfer;" \
            StartupWMClass "TeamViewer"
    done
fi

#################
### TERMINALS ###
#################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gnome-terminal.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/lxterminal.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/mate-terminal.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.kde.konsole.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Terminal" \
        Name[ro] "Terminal"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/xterm.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/uxterm.desktop"; do
    set_launcher_entry "${LAUNCHER}" NoDisplay true
done

####################
### TEXT EDITORS ###
####################
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/gedit.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/io.elementary.code.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/leafpad.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.gnome.gedit.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/org.pantheon.scratch.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/medit.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/pluma.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.gedit.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.TextEditor.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.gedit.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.TextEditor.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Text Editor" \
        Name[ro] "Editor Text" \
        Icon "accessories-text-editor"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/micro.desktop" NoDisplay true

###########################
### TORRENT DOWNLOADERS ###
###########################
TORRENT_APP_CATEGORIES="Network;FileTransfer;P2P;"
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/transmission-gtk.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Torrents" \
        Name[ro] "Torente"
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/de.haeckerfelix.Fragments.desktop"; do
    set_launcher_entry "${LAUNCHER}" Categories "GNOME;GTK;${TORRENT_APP_CATEGORIES}"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/transmission-gtk.desktop" Categories "GTK;${TORRENT_APP_CATEGORIES}"

#################
### TODO Apps ###
#################
TODO_APP_KEYWORDS="Task;Productivity;TODO;Reminder;"
TODO_APP_KEYWORDS_RO="${TODO_APP_KEYWORDS}Sarcină;Sarcini;Productivitate;DeFăcut;De făcut;Memento;"

set_launcher_entries "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Todo.desktop" \
    Name "Reminders" \
    Name[ro] "Mementouri" \
    Keywords "${TODO_APP_KEYWORDS}" \
    Keywords[ro] "${TODO_APP_KEYWORDS_RO}"

########################
### TRANSLATION APPS ###
########################
set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/com.github.gi_lom.dialect.desktop" \
    Name "Translate" \
    Name[ro] "Traduceri" \
    Categories "GNOME;GTK;Utility;"

#####################
### Video Players ###
#####################

### MPV
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/mpv.desktop" NoDisplay true

### Plex
for LAUNCHER in "${LOCAL_LAUNCHERS_DIR}/chrome-aghlkjcflkcaanjmefomlcfgflfdhkkg-Default.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/plexmediaplayer.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Plex" \
        Name[ro] "Plex" \
        Icon "plexhometheater" \
        Categories "AudioVideo;Audio;Video;Player;"
done
set_launcher_entry "${LOCAL_LAUNCHERS_DIR}/chrome-aghlkjcflkcaanjmefomlcfgflfdhkkg-Default.desktop" StartupWMClass "crx_aghlkjcflkcaanjmefomlcfgflfdhkkg"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/plexmediaplayer.desktop" StartupWMClass "plexmediaplayer"

### VLC
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/vlc.desktop" Name "VLC"

###############
### Weather ###
###############
for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/org.gnome.Weather.Application.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Weather.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.gnome.Weather.desktop"; do
    set_launcher_entries "${LAUNCHER}" Categories "GNOME;GTK;Utility;Navigation;"
done

####################
### WEB BROWSERS ###
####################
WEB_BROWSER_CATEGORIES="Network;WebBrowser;"

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/chromium.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/firefox-developer.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/google-chrome-unstable.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/google-chrome.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/tor-browser-en.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.brave.Browser.desktop" \
                "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.mozilla.firefox.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.brave.Broser.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.mozilla.firefox.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        GenericName "Web Browser" \
        Categories "${WEB_BROWSER_CATEGORIES}"
done

for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/com.brave.Browser.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/com.brave.Broser.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Brave" \
        StartupNotify false
done

for LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}/org.mozilla.firefox.desktop" \
                "${LOCAL_FLATPAK_LAUNCHERS_DIR}/org.mozilla.firefox.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Firefox" \
        Name[ro] "Firefox" \
        StartupWMClass "firefox" \
        StartupNotify false
done

for LAUNCHER in "${GLOBAL_LAUNCHERS_DIR}/google-chrome-unstable.desktop" \
                "${GLOBAL_LAUNCHERS_DIR}/google-chrome.desktop"; do
    set_launcher_entries "${LAUNCHER}" \
        Name "Chrome" \
        Name[ro] "Chrome" \
        Icon "google-chrome"
done

set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/google-chrome-unstable.desktop" StartupWMClass "Google-chrome-unstable"
set_launcher_entry "${GLOBAL_LAUNCHERS_DIR}/google-chrome.desktop" StartupWMClass "Google-chrome-stable"

set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/tor-browser-en.desktop" \
    Name "Tor" \
    Icon "tor-browser-en" \
    StartupWMClass "Tor Browser"

############
### WINE ###
############
if does_bin_exist "wine"; then
    [ ! -f "${GLOBAL_LAUNCHERS_DIR}/winecfg.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/winecfg.desktop"
    [ ! -f "${GLOBAL_LAUNCHERS_DIR}/winetricks.desktop" ] && create_launcher "${GLOBAL_LAUNCHERS_DIR}/winetricks.desktop"

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/winecfg.desktop" \
        Name "Wine Configuration" \
        Categories "Wine;Emulator;System;Settings;" \
        StartupWMClass "winecfg.exe"

    set_launcher_entries "${GLOBAL_LAUNCHERS_DIR}/winetricks.desktop" \
        Name "Winetricks" \
        Icon "winetricks" \
        Categories "Wine;Emulator;" \
        StartupWMClass "winetricks" \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/winecfg.desktop"
    remove "${GLOBAL_LAUNCHERS_DIR}/winetricks.desktop"
fi

# ALL FLATPAKS
for FLATPAK_LAUNCHER in "${GLOBAL_FLATPAK_LAUNCHERS_DIR}"/*.desktop \
                        "${LOCAL_FLATPAK_LAUNCHERS_DIR}"/*.desktop; do
    APP_ID=$(basename "${FLATPAK_LAUNCHER}" | sed 's/\.desktop$//g')
    QUIT_ACTION_ID="quit"
    FLATPAK_LAUNCHER_CONTENT=$(cat "${FLATPAK_LAUNCHER}")
    FLATPAK_NAME=$(grep "^Name=" <<< "${FLATPAK_LAUNCHER_CONTENT}" | head -n 1 | awk -F= '{print $2}')
    FLATPAK_NAME_NOSPACES=$(echo "${FLATPAK_NAME}" | sed 's/\s*//g')

    if grep -q "^\[Desktop Action quit\]" <<< "${FLATPAK_LAUNCHER_CONTENT}"; then
        QUIT_ACTION_ID="quit"
    elif grep -q "^\[Desktop Action Quit\]" <<< "${FLATPAK_LAUNCHER_CONTENT}"; then
        QUIT_ACTION_ID="Quit"
    elif grep -q "^\[Desktop Action force-qui\]" <<< "${FLATPAK_LAUNCHER_CONTENT}"; then
        QUIT_ACTION_ID="force-quit"
    elif grep -q "^\[Desktop Action ForceQuit\]" <<< "${FLATPAK_LAUNCHER_CONTENT}"; then
        QUIT_ACTION_ID="ForceQuit"
    elif grep -q "^\[Desktop Action Quit${FLATPAK_NAME_NOSPACES}\]$" <<< "${FLATPAK_LAUNCHER_CONTENT}"; then
        QUIT_ACTION_ID="Quit${FLATPAK_NAME_NOSPACES}"
    fi

    ACTIONS=$(grep "^Actions=" "${FLATPAK_LAUNCHER}" | sed -e 's/^Actions=//g' -e 's/'"${QUIT_ACTION_ID}"';//g')

    set_launcher_entries "${FLATPAK_LAUNCHER}" \
        "Exec" "/usr/bin/flatpak run ${APP_ID} %U" \
        "Actions" "${ACTIONS}${QUIT_ACTION_ID};" \
        "Desktop Action ${QUIT_ACTION_ID}/Name" "Quit" \
        "Desktop Action ${QUIT_ACTION_ID}/Name[ro]" "Închide" \
        "Desktop Action ${QUIT_ACTION_ID}/GenericName" "Quit" \
        "Desktop Action ${QUIT_ACTION_ID}/GenericName[ro]" "Închide" \
        "Desktop Action ${QUIT_ACTION_ID}/Exec" "/usr/bin/flatpak kill ${APP_ID}" \
        "Desktop Action ${QUIT_ACTION_ID}/Icon" "application-exit"
done

# CREATE ICONS

if is_gnome_shell_extension_installed "gsconnect"; then
    LAUNCHER="${GLOBAL_LAUNCHERS_DIR}/io.github.andyholmes.gsconnect.desktop"

    [ ! -f "${LAUNCHER}" ] && create_launcher "${LAUNCHER}"

    set_launcher_entries "${LAUNCHER}" \
        Name "GSConnect" \
        Exec "${ROOT_USR_SHARE}/gnome-shell/extensions/gsconnect@andyholmes.github.io/gsconnect-preferences" \
        Comment "GSConnect" \
        Keywords "GSConnect;KDEConnect;" \
        Icon "org.gnome.Shell.Extensions.GSConnect" \
        StartupWMClass "gsconnect" \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/io.github.andyholmes.gsconnect.desktop"
fi

if [ -f "${ROOT_USR_BIN}/mono" ]; then
    NEWLAUNCHER="${GLOBAL_LAUNCHERS_DIR}/run-mono.desktop"

    [ ! -f "${NEWLAUNCHER}" ] && create_launcher "${NEWLAUNCHER}"

    set_launcher_entries "${NEWLAUNCHER}" \
        Name "Mono" \
        Icon "mono" \
        Exec "mono %U" \
        Terminal true \
        NoDisplay true
else
    remove "${GLOBAL_LAUNCHERS_DIR}/run-mono.desktop"
fi

# CREATE STEAM ICONS

function getSteamAppIconPath() {
    local APP_ID="${*}"
    local APPS_DIR_NAME="48x48/apps"

    [ ! -d "${ICON_THEME_PATH}/${APPS_DIR_NAME}" ] && APPS_DIR_NAME="48/apps"

    local APP_ICON_PATH="${ICON_THEME_PATH}/${APPS_DIR_NAME}/steam_icon_${APP_ID}.svg"

    if [ -f "${APP_ICON_PATH}" ]; then
        echo "${APP_ICON_PATH}"
    else
        for ICON_THEME_CANDIDATE in "${ROOT_USR_SHARE}/icons/"* ; do

            if [ -d "${ICON_THEME_CANDIDATE}/48/apps" ]; then
                APPS_DIR_NAME="48/apps"
            elif [ -d "${ICON_THEME_CANDIDATE}/48x48/apps" ]; then
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

if does_bin_exist "steam" "com.valvesoftware.Steam" \
&& [ "${DISTRO}" != "SteamOS" ]; then
    STEAM_ICON_THEME_PATH="${XDG_DATA_HOME}/icons/steam"
    STEAM_WMCLASSES_FILE="data/steam-wmclasses.txt"
    STEAM_NAMES_FILE="data/steam-names.txt"

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
        update_file_if_distinct "${STEAM_DIR}/appcache/librarycache/${APP_ID}_icon.jpg" "${STEAM_ICON_THEME_PATH}/48x48/apps/steam_icon_${APP_ID}.jpg"
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
                APP_NAME_ORIGINAL=$(grep -h "\"name\"" "${STEAM_LIBRARY_PATH}/appmanifest_${APP_ID}.acf" | sed 's/\"name\"//' | grep -o "\".*\"" | sed 's/\"//g')
                APP_NAME="${APP_NAME_ORIGINAL}"

                if grep -q "^${APP_ID}=" "${STEAM_NAMES_FILE}"; then
                    APP_NAME=$(grep "^${APP_ID}=" "${STEAM_NAMES_FILE}" | awk -F= '{print $2}')
                fi

                DO_CREATE_LAUNCHER=true

                if [[ "${APP_NAME}" == "Steamworks Common Redistributables" ]] || \
                   [[ "${APP_NAME}" =~ ^Proton\ [0-9]+\.[0-9]+$ ]] || \
                   [[ "${APP_NAME}" =~ ^Proton\ Experimental ]] || \
                   [[ "${APP_NAME}" == "Steam Linux Runtime"* ]]; then
                    DO_CREATE_LAUNCHER=false
                fi

                if ${DO_CREATE_LAUNCHER}; then
                    APP_WMCLASS=""

                    if grep -q "^${APP_ID}=" "${STEAM_WMCLASSES_FILE}"; then
                        APP_WMCLASS=$(grep "^${APP_ID}=" "${STEAM_WMCLASSES_FILE}" | awk -F= '{print $2}')
                    else
                        APP_WMCLASS="steam_app_${APP_ID}"
                        echo "CANNOT GET WMCLASS FOR STEAMAPP ${APP_ID} - ${APP_NAME}"
                    fi

                    STEAM_EXECUTABLE="steam"

                    if does_bin_exist "com.valvesoftware.Steam"; then
                        STEAM_EXECUTABLE="com.valvesoftware.Steam"
                        #STEAM_EXECUTABLE="/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam-wrapper com.valvesoftware.Steam"
                    elif does_bin_exist "steam-start"; then
                        STEAM_EXECUTABLE="steam-start"
                    fi

                    APP_KEYWORDS="${APP_ID}"

                    for APP_NAME_WORD in ${APP_NAME}; do
                        APP_NAME_WORD=$(echo "${APP_NAME_WORD}" | sed \
                            -e 's/'"\'"'s//g' \
                            -e 's/[\[\]]//g' \
                            -e 's/[\&\:\;\.\,\_\-]//g' \
                            -e 's/['"\'"']//g' \
                            -e 's/^[0-9]\+$//g' \
                            -e 's/^[IVX]\+$//g' \
                            -e 's/^\([Aa]nd\|[Aa]t\|[Ff]or\|[Ii][ns]\|[Oo][fn]\|[Tt]he\|[Tt]o\)$//g')
                        [ -n "${APP_NAME_WORD}" ] && APP_KEYWORDS="${APP_KEYWORDS};${APP_NAME_WORD}"
                    done

                    create_launcher "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop"
                    set_launcher_entries "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" \
                        Name "${APP_NAME}" \
                        FullName "${APP_NAME_ORIGINAL}" \
                        Comment "Play ${APP_NAME} on Steam" \
                        Comment[de] "Spiele ${APP_NAME} bei Steam" \
                        Comment[es] "Juega ${APP_NAME} en Steam" \
                        Comment[ro] "Joacă ${APP_NAME} pe Steam" \
                        Keywords "Game;Steam;${APP_KEYWORDS};" \
                        Keywords[de] "Spiel;Steam;${APP_KEYWORDS};" \
                        Keywords[es] "Juego;Steam;${APP_KEYWORDS};" \
                        Keywords[ro] "Joc;Steam;${APP_KEYWORDS};" \
                        Exec "${STEAM_EXECUTABLE} steam://rungameid/${APP_ID}" \
                        Icon "${APP_ICON_PATH}" \
                        Icon[de] "${APP_ICON_PATH}" \
                        Icon[es] "${APP_ICON_PATH}" \
                        Icon[ro] "${APP_ICON_PATH}" \
                        Categories "Game;Steam;" \
                        StartupWMClass "${APP_WMCLASS}" \
                        PrefersNonDefaultGPU true \
                        NoDisplay false

#                    does_bin_exist "com.valvesoftware.Steam" && set_launcher_entries "${STEAM_LAUNCHERS_PATH}/app_${APP_ID}.desktop" \
#                        "X-Flatpak-RenamedFrom" "steam.desktop" \
#                        "X-Flatpak-Tags" "proprietary" \
#                        "X-Flatpak" "com.valvesoftware.Steam"
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

run_as_su update-desktop-database
update-desktop-database "${LOCAL_LAUNCHERS_DIR}"
