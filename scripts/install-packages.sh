#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/common.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

INSTALL_PARTITION_EDITORS=false

function get_latest_github_release_assets() {
    curl -Ls "https://api.github.com/repos/${1}/releases/latest" | \
        grep "browser_download_url" | \
        cut -d "\"" -f 4
}

##############
### Basics ###
##############
install_native_package 'coreutils'
install_native_package 'wget'

if ! [[ ${DEVICE_MODEL} =~ 'iPhone' ]]; then
    install_native_package 'most'
fi

if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'bash-completion'
    install_native_package 'usbutils'

    install_native_package 'man-db'
    install_native_package 'man-pages'
    install_native_package 'realtime-privileges'
    install_native_package 'sudo'

    install_native_package 'bat'
elif [ "${DISTROY_FAMILY}" = 'Android' ]; then
    install_native_package 'manpages'

    [ -f '/sbin/su' ] && install_native_package 'tsu'
fi

install_native_package 'findutils'

##################
### base-devel ###
##################
install_native_package 'autoconf'
install_native_package 'binutils'
install_native_package 'make'
install_native_package 'fakeroot'
install_native_package 'patch'

if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'debugedit'
    install_native_package 'gcc'
    install_native_package 'pkgconf'
fi

# Extra devel for parallelising the build processes
if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'pbzip2' # Drop-in replacement for bzip2, with multithreading
    install_native_package 'pigz'   # Drop-in replacement for gzip, with multithreading
fi

########################
### Package Managers ###
########################
if [ "${OS}" = 'Linux' ]; then
    if [ "${DISTRO_FAMILY}" = 'Arch' ] \
    && [ "${DISTRO}" != 'SteamOS' ]; then
        #install_native_package openssl-1.1 # Required for package management

        if [ "${ARCH}" != 'armv7l' ]; then
            install_aur_package_manually 'paru-bin'
        else
            # Special case, since we don't want to build paru from source (it takes a LOOONG time)
            install_aur_package_manually 'yay-bin'
        fi

        #install_native_package pacman-contrib
        #install_native_package pacutils
        #install_native_package pkgfile
    fi

    ${HAS_GUI} && install_native_package 'flatpak'
fi    

###################
### Development ###
###################
install_native_package 'git'
install_native_package 'automake'

#####################################
### Development - Runtimes & SDKs ###
#####################################
if ${IS_DEVELOPMENT_DEVICE}; then
    install_native_package 'dotnet-sdk'
    install_native_package 'python'
    #install_native_package 'python2'
    #install_native_package 'mono'
    #install_native_package 'jre-openjdk-headless'

    if [ "${ARCH_FAMILY}" = 'x86' ]; then
        install_native_package 'dotnet-runtime'
        install_native_package 'aspnet-runtime'
    elif [ "${ARCH_FAMILY}" = 'arm' ]; then
        install_native_package 'dotnet-runtime-bin'
        install_native_package 'aspnet-runtime-bin'
    fi
fi

###############
### Parsers ###
###############
install_native_package 'jq'         # JSON parser
install_native_package 'xmlstarlet' # XML parser

if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'dmidecode'  # Read device manufacturer information
fi

##################
### Monitoring ###
##################
if [ "${DISTRO_FAMILY}" = 'Arch' ] \
&& [ "${DISTRO}" != 'SteamOS' ] \
&& ${HAS_GUI}; then
    install_native_package 'fastfetch'
else
    install_native_package 'neofetch'
fi

if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'lm_sensors'
fi

if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
    install_native_package 'gnome-system-monitor'
elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
    install_native_package 'lxtask'
fi

########################
### Power Management ###
########################
if [ "${CHASSIS_TYPE}" = 'Laptop' ] \
&& ! [[ "${DISTRO}" =~ 'WSL' ]]; then
    install_native_package 'acpi'
    install_native_package 'tlp'

    install_native_package 'powertop'

    # TODO: Extract this check into system-info.sh DEVICE_MODEL
    if get_dmi_string 'system-sku-number' | grep -q 'ThinkPad'; then
        install_native_package 'acpi_call'
        install_native_package 'tp_smapi'
    fi
fi

##################
### Networking ###
##################
install_native_package 'net-tools'

if [ "${DISTRO_FAMILY}" = 'Arch' ] \
|| [ "${DISTRO_FAMILY}" = 'Android' ]; then
    install_native_package 'openssh'
    install_native_package 'wol'
elif [ "${DISTRO_FAMILY}" = "Alpine" ] \
  || [ "${DISTRO_FAMILY}" = "Debian" ]; then
    install_native_package 'openssh-server'
fi

if [ "${DISTRO_FAMILY}" = 'Debian' ]; then
    install_native_package 'wakeonlan'
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install_native_package 'ethtool'
    install_native_package 'wireless_tools'
    install_native_package 'iw'
    install_native_package 'iwd'
fi

if [ "${CHASSIS_TYPE}" = 'Laptop' ] \
|| [ "${CHASSIS_TYPE}" = 'Phone' ]; then
    if ! [[ "${DISTRO}" =~ 'WSL' ]]; then
        install_native_package 'chrony'
    fi
fi

if ${HAS_GUI}; then
    if [ "${OS}" = 'Linux' ] \
    && ! [[ "${DISTRO}" =~ 'WSL' ]]; then
        install_native_package 'networkmanager'
        install_native_package 'networkmanager-openvpn'

        [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ] && install_native_package 'network-manager-applet'
    fi
else
    if [ "${OS}" = 'Linux' ]; then
        install_native_package 'netctl'
        install_native_package 'dhcpcd'

        if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
            install_native_package 'libmd' # Dependency of dhcpcd
        fi
    fi
fi

##########################
### Application Stores ###
##########################
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'com.aurora.store'
    install_android_remote_package 'org.fdroid.fdroid' 'https://f-droid.org/F-Droid.apk'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_native_package 'gnome-software'
    fi
fi

################
### Archives ###
################
install_native_package 'unp' # A script for unpacking a wide variety of archive formats
install_native_package 'unzip'
install_native_package 'zip'

if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    install_native_package 'p7zip'
    install_native_package 'lrzip'
fi

if [ "${DISTRO_FAMILY}" = 'Arch' ] \
|| [ "${DISTRO_FAMILY}" = 'Android' ]; then
    install_native_package 'unrar'
elif [ "${DISTRO_FAMILY}" = 'Debian' ]; then
    install_native_package 'unrar-free'
fi

#############
### Audio ###
#############
if ${HAS_GUI}; then
    install_native_package 'pipewire'
    install_native_package_dependency 'pipewire-alsa'
    install_native_package_dependency 'pipewire-pulse'
    install_native_package_dependency 'pipewire-jack'
fi

###################
### Filesystems ###
###################
if [ "${ARCH_FAMILY}" = 'x86' ]; then
    if [ "${CHASSIS_TYPE}" = 'Desktop' ] \
    || [ "${CHASSIS_TYPE}" = 'Laptop' ]; then
        # Partition editors
        if ${INSTALL_PARTITION_EDITORS}; then
            install_native_package 'parted'

            if ${HAS_GUI} && ${IS_GENERAL_PURPOSE_DEVICE}; then
                install_native_package 'gparted'
                install_native_package_dependency 'gpart'
                install_native_package_dependency 'mtools'
            fi

            if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
            || [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
                install_native_package 'gnome-disk-utility'
            fi

            # Disk Usage Analyzer
            install_native_package 'baobab'
        fi

        # Filesystems
        install_native_package_dependency 'dosfstools' # For FAT filesystem support
        install_native_package_dependency 'ntfs-3g'
        install_native_package_dependency 'exfatprogs'
    fi
fi

#############
### Fonts ###
#############
# Fonts
if ${IS_GENERAL_PURPOSE_DEVICE}; then
    # Fonts - General
    install_native_package 'gnu-free-fonts'
    [ "${ARCH_FAMILY}" = 'x86' ] && install_native_package 'ttf-ms-win10'
    install_native_package 'noto-fonts'
    install_native_package 'ttf-apple-emoji'
    install_native_package 'ttf-droid'
    install_native_package_dependency 'ttf-croscore'
    install_native_package_dependency 'ttf-liberation'
    install_native_package 'hori-fonts'

    # Fonts - International
    install_native_package 'noto-fonts-cjk' # Chinese, Japanese, Korean
    install_native_package 'ttf-amiri' # Classical Arabic in Naskh style
    install_native_package 'ttf-ancient-fonts' # Aegean, Egyptian, Cuneiform, Anatolian, Maya, Analecta
    install_native_package 'ttf-baekmuk' # Korean
    install_native_package 'ttf-hannom' # Vietnamese
    install_native_package 'ttf-ubraille' # Braille
fi

#################
### Bluetooth ###
#################
if ${HAS_GUI}; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_native_package 'gnome-bluetooth'
    elif ! [[ "${DEVICE_MODEL}" =~ 'iPhone' ]] \
      && ! [[ "${DISTRO}" =~ 'WSL' ]] \
      && [ "${DISTRO_FAMILY}" != 'Android' ]; then
        install_native_package 'blueman'
    fi
fi

####################
### Boot Loaders ###
####################
if [ "${ARCH_FAMILY}" = 'x86' ] \
&& ! [[ "${DISTRO}" =~ 'WSL' ]]; then
    if [ "${CHASSIS_TYPE}" = 'Desktop' ] \
    || [ "${CHASSIS_TYPE}" = 'Laptop' ]; then
        install_native_package 'grub'
        install_native_package_dependency 'os-prober'
        install_native_package 'update-grub'
        install_native_package_dependency 'linux-headers'

        # Customisations
        install_native_package 'grub2-theme-nuci'
    fi
fi

###################
### Calculators ###
###################
if ${IS_GENERAL_PURPOSE_DEVICE}; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Calculator'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
        install_native_package 'mate-calc'
    fi
fi

#################
### Calendars ###
#################
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'org.fossify.calendar'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Calendar'
    fi
fi

###############
### Cameras ###
###############
if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
    install_flatpak 'org.gnome.Snapshot'
elif [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_native_package 'megapixels'
elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
    install_native_package 'cheese'
fi

#################
### Chat Apps ###
#################
if ${HAS_GUI}; then
    if ${IS_GENERAL_PURPOSE_DEVICE}; then
        if [ "${OS}" = 'Android' ]; then
            install_android_fdroid_package 'org.telegram.messenger'
        elif [ "${OS}" = 'Linux' ]; then
            install_flatpak 'org.telegram.desktop'
        fi

        if [ "${OS}" = 'Android' ]; then
            install_android_remote_package 'https://updates.signal.org/android/Signal-Android-website-prod-universal-release-7.6.2.apk' 'org.thoughtcrime.securesms'
        else
            if [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
                install_flatpak 'de.schmidhuberj.Flare'
            else
                install_flatpak 'org.signal.Signal'
            fi
        fi

        if [ "${CHASSIS_TYPE}" != 'Phone' ]; then
            install_flatpak 'io.github.mimbrero.WhatsAppDesktop'
        fi
    fi

    if ${IS_DEVELOPMENT_DEVICE}; then
        install_flatpak 'com.github.IsmaelMartinez.teams_for_linux'
    fi

    if ${IS_GAMING_DEVICE}; then
        install_flatpak 'com.discordapp.Discord'
    fi
fi

#################
### Calendars ###
#################
if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
|| [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_flatpak 'org.gnome.Calendar'
fi

###############
### Drivers ###
###############
if [ "${ARCH_FAMILY}" = 'x86' ] \
&& ! [[ "${DISTRO}" =~ 'WSL' ]]; then
    if [ "${GPU_FAMILY}" = 'Intel' ]; then
        install_native_package 'intel-media-driver'

        install_native_package 'libva-intel-driver'
        install_native_package 'libva-utils'

        install_native_package 'libvdpau-va-gl'

        install_native_package 'vulkan-intel'
        install_native_package 'lib32-vulkan-intel'

        install_native_package 'intel-ucode'
    elif [ "${GPU_FAMILY}" = 'Nvidia' ]; then
        NVIDIA_DRIVER='nvidia'

        [ "${GPU_MODEL}" = 'GeForce 610M' ] && NVIDIA_DRIVER='nvidia-390xx'

        if gpu_has_optimus_support; then
            install_native_package 'bumblebee'
            install_native_package_dependency 'bbswitch'
            install_native_package_dependency 'primus'

            install_native_package 'optiprime'

            install_native_package 'mesa'
            install_native_package 'xf86-video-intel'

            install_native_package "${NVIDIA_DRIVER}-dkms"
            install_native_package "${NVIDIA_DRIVER}-settings"
            install_native_package_dependency "lib32-${NVIDIA_DRIVER}-utils"

            install_native_package_dependency 'lib32-virtualgl'
        else
            install_native_package "${NVIDIA_DRIVER}"
        fi

        install_native_package 'libva-vdpau-driver'
    fi
fi

##############
### Clocks ###
##############
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'org.fossify.clock'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.clocks'
    fi
fi

################
### Contacts ###
################
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'org.fossify.contacts'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Contacts'
    fi
fi

#####################
### Email Clients ###
#####################
if ${HAS_GUI} && ${IS_GENERAL_PURPOSE_DEVICE}; then
    if [ "${OS}" = 'Android' ]; then
        install_android_github_package 'ch.protonmail.android' 'ProtonMail/proton-mail-android'
    elif [ "${OS}" = 'Linux' ]; then
        install_flatpak 'com.github.vladimiry.ElectronMail'
    fi
fi

#####################
### File Managers ###
#####################
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'org.fossify.filemanager'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_native_package 'nautilus'
        install_flatpak 'org.gnome.FileRoller'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'KDE' ]; then
        install_native_package 'dolphin'
        install_native_package 'ark'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
        install_native_package 'pcmanfm'
        install_native_package 'xarchiver'
    fi

    if ${IS_POWERFUL_PC} && ${HAS_GUI}; then
        install_native_package_dependency 'webp-pixbuf-loader'
    fi
fi

######################
### Game Launchers ###
######################
if ${POWERFUL_PC} && ${IS_GAMING_DEVICE}; then
    if [ "${DISTRO}" != 'SteamOS' ]; then
        install_native_package 'steam' # No flatpak yet because the games will share the same icon in GNOME (e.g. alt-tabbing), concerns about steam-start, per-game desktop launchers, udev rules for controllers
        #install_native_package 'steam-start'
        #install_flatpak 'com.valvesoftware.Steam'
    fi
fi

#####################
### Game Runtimes ###
####################
#if ${POWERFUL_PC} && ${IS_GAMING_DEVICE}; then
#    if [ "${DISTRO}" != 'SteamOS' ]; then
#        install_native_package_dependency 'steam-native-runtime'
#        install_native_package 'proton-ge-custom-bin'
#        install_native_package 'luxtorpeda-git'
#    fi
#fi

############
### IDEs ###
############
if ${HAS_GUI} && ${IS_DEVELOPMENT_DEVICE}; then
    # Development
    [ "${ARCH_FAMILY}" = 'x86' ] && install_native_package 'visual-studio-code-bin'
    [ "${ARCH_FAMILY}" = 'arm' ] && install_native_package 'code-headmelted-bin'

    install_vscode_package 'dakara.transformer'
    install_vscode_package 'johnpapa.vscode-peacock'
    install_vscode_package 'mechatroner.rainbow-csv'
    install_vscode_package 'nico-castell.linux-desktop-file'
    install_vscode_package 'qinjia.seti-icons'

    if does_bin_exist 'dotnet'; then
        install_vscode_package 'mangrimen.mgcb-editor'
        install_vscode_package 'ms-dotnettools.csdevkit'
        install_vscode_package 'ms-dotnettools.csharp'
    fi

    does_bin_exist 'git' && install_vscode_package 'github.vscode-github-actions'
    does_bin_exist 'python' && install_vscode_package 'ms-python.python'
fi

#####################
### Image Editors ###
#####################
if ${HAS_GUI} && ${IS_GENERAL_PURPOSE_DEVICE} && [ "${DEVICE_TYPE}" = 'PC' ]; then
    install_flatpak 'org.gimp.GIMP' # Wait at least until it uses GTK3
    install_flatpak 'org.inkscape.Inkscape'
fi

#####################
### Image Viewers ###
#####################
if ${HAS_GUI}; then
    if [ "${OS}" = 'Android' ]; then
        install_android_fdroid_package 'org.fossify.gallery'
    elif [ "${OS}" = 'Linux' ]; then
        if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
            install_flatpak 'org.gnome.Loupe'
        elif [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
            install_flatpak 'org.gnome.eog'
        elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
            install_native_package 'gpicview'
        fi
    fi

    install_native_package 'libheif' # Support for diplaying HEIC
fi

#########################
### Internet Browsers ###
#########################
if ${HAS_GUI}; then
    if [ "${OS}" = 'Linux' ]; then
        install_flatpak 'io.gitlab.librewolf-community'
    fi
fi

##########################
### Internet of Things ###
##########################
if [ "${OS}" = 'Android' ]; then
    install_android_github_package 'io.homeassistant.companion.android.minimal' 'home-assistant/android'
fi

############
### Maps ###
############
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'net.osmand.plus'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Maps'
    fi
fi

#####################
### Music Players ###
#####################
if ${IS_GENERAL_PURPOSE_DEVICE}; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'io.bassi.Amberol'
    fi

    if [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'dev.alextren.Spot'
    else
        install_flatpak 'com.spotify.Client'
    fi
fi

#####################
### Notes & Tasks ###
#####################
if ${IS_GENERAL_PURPOSE_DEVICE}; then
    if [ "${OS}" = 'Android' ]; then
        install_android_remote_package 'com.automattic.simplenote' 'Automattic/simplenote'
    elif [ "${OS}" = 'Linux' ]; then
        if [ "${DESKTOP_ENVIRONMENT}" != 'Phosh' ]; then
            install_flatpak 'com.simplenote.Simplenote'
        fi
        
        if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
        || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
            install_flatpak 'io.github.alainm23.planify'
        fi
    fi
fi

####################
### Office Suite ###
####################
if ${IS_GENERAL_PURPOSE_DEVICE}; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Papers'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
        install_native_package 'epdfview'
    fi
fi

#########################
### Password Managers ###
#########################
if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
    install_native_package 'gnome-keyring'
    install_flatpak 'org.gnome.seahorse.Application'
fi

################
### Settings ###
################
if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
    install_native_package 'gnome-tweaks'
    install_flatpak 'ca.desrt.dconf-editor'
elif [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_native_package 'postmarketos-tweaks'
    install_native_package 'postmarketos-tweaks-phosh'
fi

#################
### Terminals ###
#################
if [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ]; then
        install_native_package 'gnome-terminal'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_native_package 'gnome-console'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'KDE' ]; then
        install_native_package 'konsole'
    elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
        install_native_package 'lxterminal'
    fi
elif [ "${OS}" = 'Android' ]; then
    install_android_fdroid_package 'com.termux'
fi

####################
### Text Editors ###
####################
install_native_package 'micro'

if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
|| [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_flatpak 'org.gnome.TextEditor'
elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
    install_native_package 'pluma'
fi

##############
### Themes ###
##############
if "${HAS_GUI}"; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        is_native_package_installed "gtk2" && install_native_package 'adwaita-dark' # GTK3's Adwaita Dark ported to GTK2
        is_native_package_installed "gtk3" && install_native_package 'adw-gtk3'
        install_flatpak 'org.gtk.Gtk3theme.adw-gtk3-dark'
        install_flatpak 'org.kde.KStyle.Adwaita'
    fi

    [ "${CHASSIS_TYPE}" != 'Phone' ] && install_native_package 'vimix-cursors'

    install_native_package 'papirus-icon-theme'
    install_native_package 'papirus-folders'
fi

###########################
### Torrent Downloaders ###
###########################
if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
|| [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_flatpak 'de.haeckerfelix.Fragments'
elif [ "${DESKTOP_ENVIRONMENT}" = 'LXDE' ]; then
    install_flatpak 'com.transmissionbt.Transmission'
fi

#####################
### Video Players ###
#####################
if [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
    install_flatpak 'org.gnome.Showtime'
elif [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
    install_flatpak 'io.github.celluloid_player.Celluloid'
fi

####################
### Weather Apps ###
####################
if [ "${OS}" = 'Android' ]; then
    install_android_fdroid_pacakge 'org.breezyweather'
elif [ "${OS}" = 'Linux' ]; then
    if [ "${DESKTOP_ENVIRONMENT}" = 'GNOME' ] \
    || [ "${DESKTOP_ENVIRONMENT}" = 'Phosh' ]; then
        install_flatpak 'org.gnome.Weather'
    fi
fi
#############################
### Window Manager Extras ###
#############################
if ${HAS_GUI}; then
    if is_native_package_installed 'wayland'; then
        install_native_package 'wayland-utils'
    fi

    if is_native_package_installed 'xorg-server'; then
        install_native_package 'xorg-xdpyinfo'
        #install_native_package 'xorg-xkill'
    fi
fi

if [ "${OS}" = 'Linux' ]; then

    if ${HAS_GUI}; then
        install_native_package 'dkms'
        #install_native_package rsync

        # System management
        [[ "${ARCH_FAMILY}" == "x86" ]] && install_native_package thermald

        # Display Server, Drivers, FileSystems, etc
        #install_native_package xorg-server
        #install_native_package xf86-video-vesa

        # Desktop Environment & Base applications
        install_native_package xdg-user-dirs

        if [[ "${DESKTOP_ENVIRONMENT}" == "GNOME" ]]; then
            install_native_package gnome-shell
            install_native_package gdm
            install_native_package_dependency gnome-control-center
            #install_native_package gnome-backgrounds
            install_flatpak org.gnome.font-viewer
            install_flatpak org.gnome.NetworkDisplays

            if is_native_package_installed flatpak; then
                install_native_package xdg-desktop-portal-gnome
            fi
        elif [[ "${DESKTOP_ENVIRONMENT}" == "LXDE" ]]; then
            install_native_package mutter # openbox
            install_native_package lxde-common
            install_native_package lxdm
            install_native_package lxpanel
            install_native_package lxsession
            install_native_package lxappearance
            install_native_package lxappearance-obconf
        fi

        if ${IS_GENERAL_PURPOSE_DEVICE}; then
            if is_native_package_installed "gnome-shell"; then
                install_native_package_dependency gvfs-goa
                install_native_package_dependency evolution-data-server # To make GOA contacts, tasks, etc. available in apps
            fi

            ! ${POWERFUL_PC} && install_native_package plank
        fi

        # GNOME Shell Extensions
        if ${POWERFUL_PC} && [ "${DESKTOP_ENVIRONMENT}" = "GNOME" ]; then
            # Base
            install_flatpak "com.mattjakeman.ExtensionManager"
            install_native_package gnome-shell-extensions
            install_native_package gnome-shell-extension-installer

            # Enhancements
            if does_bin_exist "plank"; then
                install_gnome_shell_extension "dash-to-plank"
            else
                install_native_package "gnome-shell-extension-dash-to-dock"
                #install_gnome_shell_extension "dash-to-dock"
            fi

            install_gnome_shell_extension "multi-monitors-add-on"
            #install_gnome_shell_extension "wintile"

            # New features
            install_native_package "gnome-shell-extension-bluetooth-battery-meter-git"
            #install_gnome_shell_extension "gsconnect"
            #install_gnome_shell_extension 5470 #"weatheroclock@CleoMenezesJr.github.io"

            # Appearance
            install_gnome_shell_extension "blur-my-shell"

            # Remove annoyances
            install_gnome_shell_extension "windowIsReady_Remover"
            install_gnome_shell_extension "no-overview"
            install_gnome_shell_extension "Hide_Activities"
        fi

        #if ${IS_GENERAL_PURPOSE_DEVICE}; then
        #    install_native_package_dependency gst-plugins-ugly
        #    install_native_package_dependency gst-libav
        #fi

        if ${IS_DEVELOPMENT_DEVICE}; then
            install_flatpak com.getpostman.Postman

            #does_bin_exist "flatpak" && install_native_package "flatpak-builder"

            # Tools
            install_flatpak "com.github.dynobo.normcap"
        fi
    fi
elif [ "${DISTRO_FAMILY}" = 'Android' ] \
&& ${HAS_SU_PRIVILEGES}; then
    # Security
    install_android_remote_package "$(get_latest_github_release_assets bitwarden/mobile | grep fdroid)" "com.x8bit.bitwarden" # Bitwarden
fi
