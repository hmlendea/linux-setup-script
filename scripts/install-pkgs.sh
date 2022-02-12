#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/package-management.sh"

##############
### Basics ###
##############
install-pkg coreutils
install-pkg most
install-pkg wget

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg bash-completion
    install-pkg usbutils
    install-pkg lshw

    install-pkg man-pages
    install-pkg sudo

    install-pkg bat
elif [[ "${DISTROY_FAMILY}" == "Android" ]]; then
    install-pkg manpages

    [ -f "/sbin/su" ] && install-pkg tsu
fi

##################
### base-devel ###
##################
install-pkg autoconf
install-pkg binutils
install-pkg make
install-pkg fakeroot
install-pkg patch

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg gcc
    install-pkg pkgconf
fi

###################
### Development ###
###################
install-pkg git
install-pkg automake

###############
### Parsers ###
###############
install-pkg jq          # JSON parser
install-pkg xmlstarlet  # XML parser

##################
### Monitoring ###
##################
if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg fastfetch-git
else
    install-pkg neofetch
fi

##################
### Networking ###
##################
install-pkg net-tools

if [[ "${DISTRO_FAMILY}" == "Arch" ]] \
|| [[ "${DISTRO_FAMILY}" == "Android" ]]; then
    install-pkg openssh
    install-pkg wol
elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
    install-pkg openssh-server
    install-pkg wakeonlan
fi

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg wireless_tools
    install-pkg wpa_supplicant
fi

################
### Archives ###
################
install-pkg cabextract
install-pkg unzip

if [[ "${DISTRO_FAMILY}" == "Arch" ]] \
|| [[ "${DISTRO_FAMILY}" == "Android" ]]; then
    install-pkg unrar
elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
    install-pkg unrar-free
fi

if [ "${DISTRO_FAMILY}" != "Arch" ]; then
    exit
fi

install-pkg openssl-1.0 # Required to run ASP .NET Core apps

# Package manager
install-pkg-aur-manually package-query

if [[ "${ARCH}" != "armv7l" ]]; then
    install-pkg-aur-manually paru-bin
else
    # Special case, since we don't want to build paru from source (it takes a LOOONG time)
    install-pkg-aur-manually yay-bin
fi

install-pkg pacman-contrib
install-pkg pacutils
install-pkg pkgfile
install-pkg repo-synchroniser

# Partition editors
install-pkg parted

# Filesystems
install-pkg ntfs-3g
install-pkg exfat-utils
install-pkg xfsprogs

# Archives
install-pkg unp # A script for unpacking a wide variety of archive formats
install-pkg p7zip
install-pkg lrzip
install-dep unace

install-pkg realtime-privileges

# CLI
install-pkg nano-syntax-highlighting

# Monitoring
install-pkg lm_sensors

# Boot loader
if [[ "${ARCH_FAMILY}" == "x86" ]]; then
    install-pkg grub
    install-dep os-prober
    install-pkg update-grub
    install-dep linux-headers

    # Customisations
    install-pkg grub2-theme-nuci
fi

if ${HAS_GUI}; then
    install-pkg dkms
    install-pkg rsync

    # System management
    [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg thermald

    # Runtimes
    install-pkg python
    install-pkg python2
    install-pkg mono
    install-pkg jre-openjdk-headless

    if [[ "${ARCH_FAMILY}" == "x86" ]]; then
        install-pkg dotnet-runtime
        install-pkg aspnet-runtime
    elif [[ "${ARCH_FAMILY}" == "arm" ]]; then
        install-pkg dotnet-runtime-bin
        install-pkg aspnet-runtime-bin
    fi

    # Display Server, Drivers, FileSystems, etc
    install-pkg xorg-server
    #install-pkg xf86-video-vesa

    # Graphics drivers
    if [[ "${GPU_FAMILY}" == "Nvidia" ]]; then
        NVIDIA_DRIVER="nvidia"

        [[ "${GPU_MODEL}" == "GeForce 610M" ]] && NVIDIA_DRIVER="nvidia-390xx"


        if ${HAS_OPTIMUS_SUPPORT}; then
            install-pkg bumblebee
            install-dep bbswitch
            install-dep primus

            install-pkg optiprime

            install-pkg mesa
            install-pkg xf86-video-intel

            install-pkg "${NVIDIA_DRIVER}-dkms"
            install-pkg "${NVIDIA_DRIVER}-settings"
            install-dep "lib32-${NVIDIA_DRIVER}-utils"

            install-dep lib32-virtualgl
        else
            install-pkg "${NVIDIA_DRIVER}"
        fi
    fi

    # Desktop Environment & Base applications
    if ${POWERFUL_PC}; then
        install-pkg gnome-shell
        install-pkg gdm
        install-pkg xdg-user-dirs-gtk
        install-dep gnome-control-center
        install-pkg gnome-tweaks
        install-pkg gnome-backgrounds
        install-pkg gnome-font-viewer
    else
        install-pkg mutter # openbox
        install-pkg lxde-common
        install-pkg lxdm
        install-pkg lxpanel
        install-pkg lxsession
        install-pkg lxappearance
        install-pkg lxappearance-obconf
        install-pkg plank
    fi

    install-pkg gnome-keyring
    install-pkg seahorse

    install-pkg networkmanager
    install-pkg networkmanager-openvpn
    ! ${POWERFUL_PC} && install-pkg network-manager-applet

    install-dep dnsmasq

    # Audio drivers
    install-pkg sennheiser-gsp670-pulseaudio-profile

    # Bluetooth Manager
    ${POWERFUL_PC} && install-pkg gnome-bluetooth
    ${POWERFUL_PC} || install-pkg blueman

    # System Monitor / Task Manager
    ${POWERFUL_PC} && install-pkg gnome-system-monitor
    ${POWERFUL_PC} || install-pkg lxtask

    # Terminal
    ${POWERFUL_PC} && install-pkg gnome-terminal
    ${POWERFUL_PC} || install-pkg lxterminal

    # Calculator
    ${POWERFUL_PC} && install-pkg gnome-calculator
    ${POWERFUL_PC} || install-pkg mate-calc

    install-pkg gnome-disk-utility
    install-pkg gnome-network-displays

    if ${POWERFUL_PC}; then
        install-pkg gnome-calendar
        install-pkg gnome-clocks
        install-pkg gnome-contacts
        install-pkg gnome-maps
        install-pkg gnome-weather
    fi

    # File management
    if ${POWERFUL_PC}; then
        install-pkg nautilus
        install-pkg folder-color-nautilus
        install-pkg gnome-dds-thumbnailer
        install-pkg file-roller

        install-pkg code-nautilus-git
    else
        install-pkg pcmanfm
        install-pkg xarchiver
    fi

    install-pkg dconf-editor

    # Text Editor
    ${POWERFUL_PC} && install-pkg gedit
    ${POWERFUL_PC} || install-pkg pluma

    # Document Viewer
    ${POWERFUL_PC} && install-pkg evince
    ${POWERFUL_PC} || install-pkg epdfview

    if ${POWERFUL_PC}; then
        install-pkg baobab
        install-pkg gnome-screenshot
    else
        install-pkg mate-utils
    fi

    # Image Viewer
    ${POWERFUL_PC} && install-pkg eog
    ${POWERFUL_PC} || install-pkg gpicview

    if ${POWERFUL_PC}; then
        install-dep gnome-menus

        install-dep gvfs-afc
        install-dep gvfs-smb
        install-dep gvfs-gphoto2
        install-dep gvfs-mtp
        install-dep gvfs-goa
        install-dep gvfs-nfs
        install-dep gvfs-google
    fi

    # GNOME Shell Extensions
    if ${POWERFUL_PC}; then
        # Base
        install-pkg gnome-shell-extensions
        install-pkg gnome-shell-extension-installer

        # Enhancements
        install-pkg gnome-shell-extension-dash-to-dock
        install-pkg gnome-shell-extension-sound-output-device-chooser
        install-pkg gnome-shell-extension-multi-monitors-add-on-git
        install-pkg gnome-shell-extension-windowisready_remover
        install-pkg gnome-shell-extension-wintile

        # New features
        install-pkg gnome-shell-extension-gsconnect
        install-pkg gnome-shell-extension-openweather-git

        # Appearance
        install-pkg gnome-shell-extension-blur-my-shell
        install-pkg gnome-shell-extension-hide-activities-git
    fi

    # Themes
    install-pkg zorin-desktop-themes
    install-pkg vimix-cursors
    install-pkg papirus-icon-theme
    install-pkg papirus-folders

    # Themes - Fallbacks
    install-pkg numix-circle-icon-theme-git
    install-pkg paper-icon-theme

    # Fonts
    install-pkg gnu-free-fonts
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg ttf-ms-win10
    install-pkg noto-fonts
    install-pkg noto-fonts-emoji
    install-pkg ttf-droid
    install-dep ttf-croscore
    install-dep ttf-liberation
    install-pkg hori-fonts

    # Fonts - International
    install-pkg noto-fonts-cjk # Chinese, Japanese, Korean
    install-pkg ttf-amiri # Classical Arabic in Naskh style
    install-pkg ttf-ancient-fonts # Aegean, Egyptian, Cuneiform, Anatolian, Maya, Analecta
    install-pkg ttf-baekmuk # Korean
    install-pkg ttf-hannom # Vietnamese
    install-pkg ttf-ubraille # Braille

    # Internet Browser
    install-pkg firefox
    does-bin-exist "gnome-shell" && install-pkg chrome-gnome-shell # Also used for Firefox

    # Torrent Downloader
    ${POWERFUL_PC} && install-pkg fragments
    ${POWERFUL_PC} || install-pkg transmission-gtk

    # Communication
    install-pkg whatsapp-nativefier
    install-pkg telegram-desktop
    install-pkg signal-desktop

    # Multimedia
    [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg spotify
    if ${POWERFUL_PC}; then
        install-pkg rhythmbox
        install-pkg totem
        install-pkg spotify

        install-dep gst-plugins-ugly
        install-dep gst-libav
    fi

    if ${POWERFUL_PC}; then
        # Graphics
        install-pkg gimp
        install-pkg gimp-extras
        install-pkg gimp-plugin-pixel-art-scalers
        install-pkg inkscape

        # Gaming
        if ${GAMING_PC}; then
            install-pkg steam
            #install-dep steam-native-runtime
            install-pkg proton-ge-custom-bin
            install-pkg luxtorpeda-git
        fi
    fi

    # Development
    install-pkg dotnet-sdk
#    install-pkg dotnet-sdk-3.1
    #install-pkg jdk

    if [[ "${ARCH_FAMILY}" == "x86" ]]; then
        install-pkg electron
        ! is-package-installed "chromium" && install-pkg chromedriver
    fi

    [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg visual-studio-code-bin
    [[ "${ARCH_FAMILY}" == "arm" ]] && install-pkg code-headmelted-bin

    # Tools
    [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg simplenote-electron-bin
    [[ "${ARCH_FAMILY}" == "arm" ]] && install-pkg simplenote-electron-arm-bin

    # Filesystem / Partitioning
    install-pkg gparted
    install-dep nilfs-utils
    install-dep gpart
    install-dep mtools
    install-dep udftools
    install-dep f2fs-tools

    install-pkg xorg-xdpyinfo
    install-pkg xorg-xkill
    install-pkg start-wmclass
fi

if [[ "${CHASSIS_TYPE}" == "Laptop" ]]; then
    install-pkg acpi
fi
