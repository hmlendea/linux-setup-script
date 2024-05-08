#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"
source "scripts/common/system-info.sh"

# Remove unused dependencies
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    UNUSED_DEPS=$(pacman -Qdtq)
    UNUSED_DEPS_COUNT=$(echo "${UNUSED_DEPS}" | wc -w)

    if [ "${UNUSED_DEPS_COUNT}" -gt 0 ]; then
        echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
        uninstall_native_package "${UNUSED_DEPS[@]}"
    fi
elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
    yes | apt autoremove
elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
    yes | run_as_su apt autoremove
fi

if does_bin_exist "flatpak"; then
    call_flatpak uninstall --unused
fi

function keep_first_package() {
    local PACKAGE_TO_KEEP_NAME="${1}" && shift
    local PACKAGE_TO_UNINSTALL_NAME="${1}"

    for PACKAGE_TO_UNINSTALL_NAME in "${@}"; do
        if is_android_package_installed "${PACKAGE_TO_KEEP_NAME}" \
        || is_flatpak_installed "${PACKAGE_TO_KEEP_NAME}" \
        || is_android_package_installed "${PACKAGE_TO_KEEP_NAME}"; then
            uninstall_android_package "${PACKAGE_TO_UNINSTALL_NAME}"
            uninstall_flatpak "${PACKAGE_TO_UNINSTALL_NAME}"
            uninstall_native_package "${PACKAGE_TO_UNINSTALL_NAME}"
        fi
    done
}

function keep_only_one_package() {
    local FIRST_INSTALLED_PACKAGE=''

    for PACKAGE in "${@}"; do
        if is_android_package_installed "${PACKAGE}" \
        || is_flatpak_installed "${PACKAGE}" \
        || is_android_package_installed "${PACKAGE}"; then
            FIRST_INSTALLED_PACKAGE="${PACKAGE}"
            break
        fi
    done

    [ -z "${FIRST_INSTALLED_PACKAGE}" ] && return

    for PACKAGE in "${@}"; do
        [ "${PACKAGE}" = "${FIRST_INSTALLED_PACKAGE}" ] && continue
        
        uninstall_android_package "${PACKAGE}"
        uninstall_flatpak "${PACKAGE}"
        uninstall_native_package "${PACKAGE}"
    done
}

# Chat Apps
keep_first_package 'com.telegram.desktop' 'telegram-desktop'
keep_only_one_package 'de.schmidhuberj.Flare' 'org.signal.Signal'

# Image Viewers
[ "${DESKTOP_ENVIRONMENT}" != 'Phosh' ] && uninstall_flatpak "org.gnome.eog" && uninstall_native_package "eog-plugins" "eog"
[ "${DESKTOP_ENVIRONMENT}" != "LXDE" ] && uninstall_native_package "gwenview"

# Internet Browsers
keep_only_one_package \
    'io.gitlab.librewolf-community' \
    'firefox-esr' 'org.mozilla.fenix' 'org.mozilla.firefox' 'firefox' \
    'foundation.e.browser' 'org.lineageos.jelly'

if ! is_native_package_installed 'firefox' \
&& ! is_native_package_installed 'firefox-esr'; then
    uninstall_native_package 'mobile-config-firefox'
fi

# Music players
keep_only_one_package "dev.alextren.Spot" "com.spotify.Client"
uninstall_android_package "org.lineageos.eleven"
uninstall_android_package "com.xiaomi.mimusic2"

# Note Taking apps
keep_first_package "com.automattic.simplenote" "foundation.e.notes"

# System Monitors
keep_first_package "net.nokyan.Resources" "gnome-system-monitor"

# Task Management apps
keep_first_package "io.github.alainm23.planify" "org.gnome.Todo"

# Video players
uninstall_android_package "com.mitv.mivideoplayer"
uninstall_android_package "com.mitv.videoplayer"
keep_first_package "com.github.rafostar.Clapper" "org.gnome.Totem"

# zzz OTHERS
keep_first_package 'chrony' 'ntp'


# Uninstall the packages
if [ "${DISTRO_FAMILY}" = "Arch" ]; then
    if ${IS_POWERFUL_PC}; then
        uninstall_native_package "plank"
    fi

    uninstall_native_package "alsi"                         # Replaced by fastfetch
    uninstall_native_package "baobab"                       # Replaced by flatpak: org.gnome.baobab
    uninstall_native_package "dialect"                      # Depends on outdated libs
    uninstall_native_package "discord"                      # Replaced by flatpak: com.discordapp.Discord
    uninstall_native_package "electronmail-bin"             # Replaced by flatpak: com.github.vladimiry.ElectronMail
    uninstall_native_package "evince"                       # Replaced by flatpak: org.gnome.Evince
    uninstall_native_package "chrome-gnome-shell"           # Does not work with flatpak browsers
    uninstall_native_package "dconf-editor"                 # Replaced by flatpak: ca.desrt.dconf-editor
    uninstall_native_package "fastfetch-git"                # Replaced by fastfetch
    uninstall_native_package "fragments"                    # Replaced by flatpak: de.haeckerfelix.Fragments
    uninstall_native_package "gnome-calculator"             # Replaced by flatpak: org.gnome.Calculator
    uninstall_native_package "gnome-calendar"               # Replaced by flatpak: org.gnome.Calendar
    uninstall_native_package "gnome-contacts"               # Replaced by flatpak: org.gnome.Contacts
    uninstall_native_package "gnome-clocks"                 # Replaced by flatpak: org.gnome.Clocks
    uninstall_native_package "gnome-font-viewer"            # Replaced by flatpak: org.gnome.font-viewer
    uninstall_native_package "gnome-maps"                   # Replaced by flatpak: org.gnome.Maps
    uninstall_native_package "gnome-network-displays"       # Replaced by flatpak: org.gnome.NetworkDisplays
    uninstall_native_package "gnome-screenshot"             # Integrated in GNOME Shell itself since version 42
    uninstall_native_package "gnome-weather"                # Replaced by flatpak: org.gnome.Weather
    uninstall_native_package "grub2-theme-vimix"            # Replaced by grub2-theme-nuci
    uninstall_native_package "inkscape"                     # Replaced by flatpak: org.inkscape.Inkscape
    uninstall_native_package "nano-syntax-highlighting"     # nano is to be uninstalled next
    uninstall_native_package "nano"                         # Replaced by micro
    uninstall_native_package "ntp"                          # Replaced by chrony
    uninstall_native_package "paper-icon-theme-git"         # Replaced by paper-icon-theme
    uninstall_native_package "postman-bin"                  # Replaced by flatpak: com.getpostman.Postman
    uninstall_native_package "rhythmbox"                    # Replaced by flatpak: org.gnome.Rhythmbox3
    uninstall_native_package "seahorse"                     # Replaced by flatpak: org.gnome.seahorse.Application
    uninstall_native_package "signal-desktop"               # Replaced by flatpak: org.signal.Signal
    uninstall_native_package "simplenote-electron-bin"      # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_native_package "simplenote-electron-arm-bin"  # Replaced by flatpak: com.simplenote.Simplenote
    uninstall_native_package "spotify"                      # Replaced by flatpak: com.spotify.Client
    uninstall_native_package "teams"                        # Replaced by flatpak: com.microsoft.Teams
    uninstall_native_package "totem"                        # Replaced by flatpak: org.gnome.Totem
    uninstall_native_package "transmission-gtk"             # Replaced by flatpak: com.transmissionbt.Transmission
    uninstall_native_package "ttf-ms-fonts"                 # Replaced by ttf-ms-win10
    uninstall_native_package "vi"                           # Replaced by micro
    uninstall_native_package "whatsapp-nativefier"          # Replaced by flatpah: io.github.mimbrero.WhatsAppDesktop
    uninstall_native_package "yaourt-auto-sync"             # Replaced by repo-synchroniser

    uninstall_flatpak "org.gnome.Cheese"        # Replaced by org.gnome.Snapshot
    uninstall_flatpak "org.gnome.gedit"         # Replaced by org.gnome.TextEditor
    uninstall_flatpak "org.gnome.Rhythmbox3"    # Replaced by io.bassi.Amberol

    # App Stores
    if is_native_package_installed "gnome-software"; then
        uninstall_native_package "discover"
    fi

    # Archive Managers
    [ "${DESKTOP_ENVIRONMENT}" = "KDE" ] && uninstall_flatpak "org.gnome.FileRoller"

    if is_flatpak_installed "org.gnome.FileRoller"; then
        uninstall_native_package "ark"
        uninstall_native_package "file-roller"
    fi

    # Fetch Utilities. Replaced by: fastfetch-git
    if [ -f "${ROOT_USR_BIN}/fastfetch" ]; then
        uninstall_native_package "neofetch"
    fi

    # File Managers. Replaced by: nautilus
    [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ] && uninstall_native_package "dolphin"
    [ "${DESKTOP_ENVIRONMENT}" = "KDE" ] && uninstall_native_package "nautilus"

    # Terminals
    [ "${DESKTOP_ENVIRONMENT}" != "GNOME" ] && uninstall_native_package "gnome-terminal"
    [ "${DESKTOP_ENVIRONMENT}" != "KDE" ] && uninstall_native_package "konsole"

    # Text Editors
    [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ] && uninstall_native_package "kwrite"
    [ "${DESKTOP_ENVIRONMENT}" = "KDE" ] && uninstall_flatpak "org.gnome.gedit"

    if is_flatpak_installed "org.gnome.gedit"; then
        uninstall_native_package "gedit"
        uninstall_native_package "kwrite"
        uninstall_flatpak "org.gnome.TextEditor"
    fi

    # Desktop Managers
    if is_native_package_installed "gdm"; then
        uninstall_native_package "lightdm-gtk-greeter"
        uninstall_native_package "lightdm"
    fi

    if ! ${IS_GENERAL_PURPOSE_DEVICE}; then
        uninstall_native_package "gnome-disk-utility"

        uninstall_flatpak "org.gnome.baobab"
        uninstall_flatpak "org.gnome.Calculator"
        uninstall_flatpak "org.gnome.Calendar"
        uninstall_flatpak "org.gnome.Cheese"
        uninstall_flatpak "org.gnome.clocks"
        uninstall_flatpak "org.gnome.Contacts"
        #uninstall_flatpak "org.gnome.Evince"
        uninstall_flatpak "org.gnome.Maps"
        uninstall_flatpak "org.gnome.Weather"

        # Communication
        uninstall_flatpak "com.microsoft.Teams"
        uninstall_flatpak "com.github.vladimiry.ElectronMail"
        uninstall_flatpak "org.telegram.desktop"
        uninstall_flatpak "org.signal.Signal"
        uninstall_flatpak "io.github.mimbrero.WhatsAppDesktop"

        # Multimedia
        uninstall_flatpak "io.bassi.Amberol"
        uninstall_flatpak "org.gnome.Totem"
    fi

    # Obsolete
    uninstall_flatpak "com.microsoft.Teams" # Unsupported anymore, using com.github.IsmaelMartinez.teams_for_linux instead
    uninstall_native_package "code-nautilus-git" # Does not work in modern Nautilus nor is it strictly required anymore

    # Removed altogether
    uninstall_native_package "bc" # Mathematical calculator
    uninstall_native_package "bison"
    uninstall_native_package "busybox"
    uninstall_native_package "cronie"
    uninstall_native_package "chafa" # Image output for fastfetch
    uninstall_native_package "flex"
    uninstall_native_package "gd"
    uninstall_native_package "gnome-dds-thumbnailer"
    uninstall_native_package "haveged"
    uninstall_native_package "lshw"
    uninstall_native_package "ocl-icd" # OCL integration for fastfetch
    uninstall_native_package "pop-sound-theme-git"
    uninstall_native_package "python2"
    uninstall_native_package "subversion"
    uninstall_native_package "tk"
    uninstall_native_package "xfconf" # XFWM integration for fastfetch

    # Build deps
    uninstall_native_package "meson"

    # Archives
    uninstall_native_package "cabextract"
    uninstall_native_package "unace"

    # GIMP - Replaced by flatpak: org.gimp.GIMP
    uninstall_native_package "gimp-extras"
    uninstall_native_package "gimp-plugin-pixel-art-scalers"
    uninstall_native_package "gimp"

    # VS Code
    uninstall_flatpak "com.visualstudio.code" # A lot of trouble due to not being able to access the host (e.g. the terminal, SSH/GPG, dotnet (fixable), other SDKs)

    if ! is_flatpak_installed "com.visualstudio.code"; then
        uninstall_flatpak org.freedesktop.Sdk.Extension.dotnet6
        uninstall_flatpak org.freedesktop.Sdk.Extension.mono6
    fi

    if is_native_package_installed "visual-studio-code-bin"; then
        uninstall_native_package "code"
        uninstall_native_package "vscodium-bin"
    fi

    # Packages I don't need
    uninstall_native_package "dnsmasq" # For setting up NetworkManager WiFi hotspots
    uninstall_native_package "exempi"
    uninstall_native_package "exfat-utils" # Replaced by exfatprogs
    uninstall_native_package "gnome-menus" # For the GS Applications extension
    uninstall_native_package "gst-plugin-pipewire" # For GS screen recording
    uninstall_native_package "gvfs-afc" # Apple mobile devices
    uninstall_native_package "gvfs-google" # Google integration
    uninstall_native_package "gvfs-gphoto2" # Camera devices
    uninstall_native_package "gvfs-mtp" # Android mobile devices
    uninstall_native_package "gvfs-nfs"
    uninstall_native_package "gvfs-smb" # Samba
    uninstall_native_package "libappindicator-gtk3"
    uninstall_native_package "libcue"
    uninstall_native_package "libexif"
    uninstall_native_package "libgrss"
    uninstall_native_package "libgsf"
    uninstall_native_package "libgxps"
    uninstall_native_package "libiptcdata"
    uninstall_native_package "libosinfo"
    uninstall_native_package "malcontent" # Parental control. Sometimes comes as a deps and stays there
    uninstall_native_package "modemmanager"
    uninstall_native_package "nilfs-utils"
    uninstall_native_package "nodejs-nativefier"
    uninstall_native_package "osinfo-db"
    uninstall_native_package "perl-locale-gettext"
    uninstall_native_package "perl-term-readkey"
    uninstall_native_package "poppler-data"
    uninstall_native_package "poppler-glib"
    uninstall_native_package "poppler"
    uninstall_native_package "python-dnspython"
    uninstall_native_package "python2-setuptools"
    uninstall_native_package "ruby"
    uninstall_native_package "totem-pl-parser"
    uninstall_native_package "tracker3-miners"
    uninstall_native_package "qt5-base"
    uninstall_native_package "webkit2gtk"

    uninstall_flatpak "nl.hjdskes.gcolor3"

    # GNOME Shell Extensions
    # Replaced by installation directly from extensions.gnome.org
    #uninstall_native_package "gnome-shell-extension-dash-to-dock"  # Replaced by plank / installation from GSE
    uninstall_native_package "gnome-shell-extension-dash-to-plank"
    uninstall_native_package "gnome-shell-extension-sound-output-device-chooser"
    uninstall_native_package "gnome-shell-extension-multi-monitors-add-on-git"
    uninstall_native_package "gnome-shell-extension-wintile"
    uninstall_native_package "gnome-shell-extension-gsconnect"
    uninstall_native_package "gnome-shell-extension-openweather-git"
    uninstall_native_package "gnome-shell-extension-blur-my-shell"
    uninstall_native_package "gnome-shell-extension-windowisready_remover"
    uninstall_native_package "gnome-shell-extension-no-overview"
    uninstall_native_package "gnome-shell-extension-hide-activities-git"
    uninstall_gnome_shell_extension "sound-output-device-chooser" # Not needed anymore since GNOME 43
    
    # Not necessary with/without system packaeg
    ! does_bin_exist "plank" && uninstall_gnome_shell_extension "dash-to-plank"
    #is_native_package_installed "gnome-shell-extension-dash-to-dock" && uninstall_gnome_shell_extension "dash-to-dock"

    # Themes - Fonts
    uninstall_native_package "noto-fonts-emoji" # Replaced by ttf-apple-emoji
    #uninstall_android_package "com.android.theme.font.notoserifsource"
    uninstall_android_package "org.lineageos.overlay.font.lato"

    # Useless dependencies
    uninstall_native_package "aspell" "hunspell"
    uninstall_native_package "chafa"
    uninstall_native_package "dbus-broker"
    uninstall_native_package "ddcutil"
    uninstall_native_package "folks"
    uninstall_native_package "freeglut"
    uninstall_native_package "gst-libav"
    uninstall_native_package "libavif"
    uninstall_native_package "libdbusmenu-glib" # Needed for Global Menu
    uninstall_native_package "libde265"
    uninstall_native_package "libdecor"
    uninstall_native_package "libgee"
    uninstall_native_package "libheif"
    uninstall_native_package "libjxl"
    uninstall_native_package "libmicrohttpd"
    uninstall_native_package "libmtp"
    uninstall_native_package "libnet"
    uninstall_native_package "libwmf"
    uninstall_native_package "libxrandr"
    uninstall_native_package "libyuv"
    uninstall_native_package "lldb"
    uninstall_native_package "lttng-ust"
    uninstall_native_package "sdl12-compat"
    uninstall_native_package "xfconf"
elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
&& ${HAS_SU_PRIVILEGES}; then
    uninstall_android_package "com.android.stk"
    uninstall_android_package "com.generalmagic.magicearth"
    uninstall_android_package "org.documentfoundation.libreoffice"

    # App stores
    if is_android_package_installed "com.aurora.store" \
    || is_android_package_installed "foundation.e.apps"; then
        if ! sudo test -d "/system/priv-app/FakeStore"; then
            uninstall_android_package "com.android.vending"
        fi
    fi

    if is_android_package_installed "foundation.e.apps"; then
        uninstall_android_package "com.aurora.adroid"
    fi

    if is_android_package_installed "com.aurora.adroid" \
    || is_android_package_installed "foundation.e.apps"; then
        uninstall_android_package "org.fdroid.fdroid"
    fi

    # Backup
    uninstall_android_package "com.android.calllogbackup"
    uninstall_android_package "com.android.wallpaperbackup"

    # Email clients
    uninstall_android_package "com.android.exchange"

    if is_android_package_installed "ch.protonmail.android"; then
        uninstall_android_package "com.android.email"
        uninstall_android_package "foundation.e.mail"
    fi

    # Equaliser
    uninstall_android_package "org.lineageos.audiofx"

    # Feedback
    uninstall_android_package "com.google.android.feedback"

    # FM Radios
    uninstall_android_package "com.android.fmradio"

    # Messaging (SMS)
    if is_android_package_installed "org.thoughtcrime.securesms"; then
        uninstall_android_package "com.android.messaging"
        uninstall_android_package "foundation.e.message"
    fi

    # Recording apps
    uninstall_android_package "org.lineageos.recorder"

    # Setup
    uninstall_android_package "com.google.android.partnersetup"
    uninstall_android_package "com.google.android.setupwizard"

    # Screen recorders
    uninstall_android_package "com.xiaomi.screenrecorder"

    # Terminals
    if is_android_package_installed "com.termux"; then
        uninstall_android_package "com.android.terminal"
    fi

    # Themes - Accent colours
    uninstall_android_package "com.android.theme.color.cinnamon"
    uninstall_android_package "com.android.theme.color.green"
    uninstall_android_package "com.android.theme.color.orange"
    uninstall_android_package "com.android.theme.color.orchid"
    uninstall_android_package "com.android.theme.color.purple"
    uninstall_android_package "org.lineageos.overlay.accent.brown"
    uninstall_android_package "org.lineageos.overlay.accent.green"
    uninstall_android_package "org.lineageos.overlay.accent.orange"
    uninstall_android_package "org.lineageos.overlay.accent.pink"
    uninstall_android_package "org.lineageos.overlay.accent.purple"
    uninstall_android_package "org.lineageos.overlay.accent.red"

    # Themes - Icons
    uninstall_android_package "com.android.theme.icon.roundedrect"
    uninstall_android_package "com.android.theme.icon.roundrect"
    uninstall_android_package "com.android.theme.icon.teardrop"

    # Voice Assistants / Input / TTS / etc
    uninstall_android_package "com.google.android.tts"
    uninstall_android_package "com.android.hotwordenrollment.okgoogle"

    # zzz others
    uninstall_android_package "org.sufficientlysecure.keychain"
    uninstall_android_package "com.android.hotwordenrollment.tgoogle"
    uninstall_android_package "com.android.hotwordenrollment.xgoogle"
    uninstall_android_package "com.google.android.projection.gearhead"

    if is_android_package_installed "com.best.deskclock"; then
        uninstall_android_package "com.android.deskclock"
    fi

    if is_android_package_installed "org.dslul.openboard.inputmethod.latin"; then
        uninstall_android_package "com.android.inputmethod.latin"
        uninstall_android_package "com.sohu.inputmethod.sogou.tv"
    fi

    if is_android_package_installed "com.google.android.GoogleCamera" \
    || is_android_package_installed "com.google.android.GoogleCameraEng" \
    || is_android_package_installed "org.codeaurora.snapcam"; then
        uninstall_android_package "foundation.e.camera"
        uninstall_android_package "net.sourceforge.opencamera"
        uninstall_android_package "org.lineageos.snap"
    fi
fi
