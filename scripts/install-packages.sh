#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

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

    install-pkg man-db
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

# Extra devel for parallelising the build processes
if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg pbzip2  # Drop-in replacement for bzip2, with multithreading
    install-pkg pigz    # Drop-in replacement for gzip, with multithreading
fi

install-pkg bc # Mathematical calculations, e.g. echo "2+2-1" | bc

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

if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg dmidecode   # Read device manufacturer information
fi

##################
### Monitoring ###
##################
if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    install-pkg fastfetch-git
else
    install-pkg neofetch
fi

########################
### Power Management ###
########################
if [[ "${CHASSIS_TYPE}" == "Laptop" ]]; then
    install-pkg acpi
    install-pkg tlp

    install-pkg powertop

    if get_dmi_string "system-sku-number" | grep -q "ThinkPad"; then
        install-pkg acpi_call
        install-pkg tp_smapi
    fi
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
    install-pkg ethtool
    install-pkg wireless_tools
    install-pkg iw
    install-pkg iwd
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
if ${HAS_GUI} && ${IS_GENERAL_PURPOSE_DEVICE}; then
    install-pkg gparted
    install-dep gpart
    install-dep mtools
fi

# Filesystems
install-pkg ntfs-3g
install-pkg exfat-utils

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
    install-pkg flatpak

    install-pkg dkms
    install-pkg rsync

    # System management
    [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg thermald

    # Display Server, Drivers, FileSystems, etc
    install-pkg xorg-server
    #install-pkg xf86-video-vesa

    # Graphics drivers
    GPU_FAMILY="$(get_gpu_family)"
    if [[ "${GPU_FAMILY}" == "Intel" ]]; then
        install-pkg intel-media-driver
    elif [[ "${GPU_FAMILY}" == "Nvidia" ]]; then
        NVIDIA_DRIVER="nvidia"

        [[ "$(get_gpu_model)" == "GeForce 610M" ]] && NVIDIA_DRIVER="nvidia-390xx"

        if gpu_has_optimus_support; then
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

        install-pkg libva-vdpau-driver
    fi

    # Desktop Environment & Base applications
    if ${POWERFUL_PC}; then
        install-pkg gnome-shell
        install-pkg gdm
        install-pkg xdg-user-dirs-gtk
        install-dep gnome-control-center
        install-pkg gnome-tweaks
        install-pkg gnome-backgrounds
        install_flatpak org.gnome.font-viewer
    else
        install-pkg mutter # openbox
        install-pkg lxde-common
        install-pkg lxdm
        install-pkg lxpanel
        install-pkg lxsession
        install-pkg lxappearance
        install-pkg lxappearance-obconf
    fi

    install-pkg gnome-keyring
    install_flatpak org.gnome.seahorse.Application

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

    install-pkg gnome-disk-utility

    if ${IS_GENERAL_PURPOSE_DEVICE}; then
        # Calculator
        if ${POWERFUL_PC}; then
            install_flatpak org.gnome.Calculator
        else
            install-pkg mate-calc
        fi

        install_flatpak org.gnome.Calendar
        install_flatpak org.gnome.clocks
        install_flatpak org.gnome.Contacts
        install_flatpak org.gnome.Maps
        install_flatpak org.gnome.NetworkDisplays
        install_flatpak org.gnome.Weather
    fi

    # File management
    if ${POWERFUL_PC}; then
        install-pkg nautilus
        install-pkg folder-color-nautilus
        install_flatpak org.gnome.FileRoller
    else
        install-pkg pcmanfm
        install-pkg xarchiver
    fi

    install-pkg dconf-editor

    # Text Editor
    if ${POWERFUL_PC}; then
        install_flatpak org.gnome.gedit
    else
        install-pkg pluma
    fi

    # Document Viewer
    if ${POWERFUL_PC}; then
        install_flatpak org.gnome.Evince
    else
        install-pkg epdfview
    fi

    if ${POWERFUL_PC}; then
        install_flatpak org.gnome.baobab
        install-pkg gnome-screenshot
    else
        install-pkg mate-utils
    fi

    # Image Viewer
    if ${POWERFUL_PC}; then
        install_flatpak org.gnome.eog
    else
        install-pkg gpicview
    fi

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

    install-pkg plank

    # GNOME Shell Extensions
    if ${POWERFUL_PC}; then
        # Base
        install-pkg gnome-shell-extensions
        install-pkg gnome-shell-extension-installer

        # Enhancements
        install-pkg gnome-shell-extension-dash-to-plank
        install-pkg gnome-shell-extension-sound-output-device-chooser
        install-pkg gnome-shell-extension-multi-monitors-add-on-git
        install-pkg gnome-shell-extension-wintile

        # New features
        install-pkg gnome-shell-extension-gsconnect
        install-pkg gnome-shell-extension-openweather-git

        # Appearance
        install-pkg gnome-shell-extension-blur-my-shell

        # Remove annoyances
        install-pkg gnome-shell-extension-windowisready_remover
        install-pkg gnome-shell-extension-no-overview
        install-pkg gnome-shell-extension-hide-activities-git
    fi

    # Themes
    install-pkg zorin-desktop-themes
    install_flatpak zorinos org.gtk.Gtk3theme.ZorinGrey-Dark
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
    install_flatpak org.mozilla.firefox
    #does-bin-exist "gnome-shell" && install-pkg chrome-gnome-shell # Also used for Firefox

    # Torrent Downloader
    if ${POWERFUL_PC}; then
        install_flatpak de.haeckerfelix.Fragments
    else
        install_flatpak com.transmissionbt.Transmission
    fi

    # Communication
    install_flatpak com.github.vladimiry.ElectronMail
    install_flatpak org.telegram.desktop
    install_flatpak org.signal.Signal
    install-pkg whatsapp-nativefier

    # Multimedia
    install_flatpak org.gnome.Rhythmbox3
    install_flatpak org.gnome.Totem
    install_flatpak com.spotify.Client

    install-dep gst-plugins-ugly
    install-dep gst-libav

    if ${POWERFUL_PC}; then
        # Graphics
        install-pkg gimp
        install-pkg gimp-extras
        install-pkg gimp-plugin-pixel-art-scalers
        install_flatpak org.inkscape.Inkscape

        # Gaming
        if ${IS_GAMING_DEVICE}; then
            # Launchers
            install-pkg steam # No flatpak yet because the games will share the same icon in GNOME (e.g. alt-tabbing), concerns about steam-start, per-game desktop launchers, udev rules for controllers
            install-pkg steam-start

            # Runtimes
            install-dep steam-native-runtime
            install-pkg proton-ge-custom-bin
            install-pkg luxtorpeda-git

            # Communication
            install_flatpak com.discordapp.Discord
        fi
    fi

    if ${IS_DEVELOPMENT_DEVICE}; then
        # Runtimes
        install-pkg python
        install-pkg python2
        install-pkg mono
        install-pkg jre-openjdk-headless

        if [[ "${ARCH_FAMILY}" == "x86" ]]; then
            install-pkg dotnet-runtime
#            install-pkg aspnet-runtime
        elif [[ "${ARCH_FAMILY}" == "arm" ]]; then
            install-pkg dotnet-runtime-bin
#            install-pkg aspnet-runtime-bin
        fi

        # Development
        install-pkg dotnet-sdk

        if [[ "${ARCH_FAMILY}" == "x86" ]]; then
            install-pkg electron
            ! is-package-installed "chromium" && install-pkg chromedriver
        fi

        [[ "${ARCH_FAMILY}" == "x86" ]] && install-pkg visual-studio-code-bin
        [[ "${ARCH_FAMILY}" == "arm" ]] && install-pkg code-headmelted-bin
        install-vscode-extension "dakara.transformer"
        install-vscode-extension "johnpapa.vscode-peacock"
        install-vscode-extension "mechatroner.rainbow-csv"
        install-vscode-extension "mgcb-vscode.mgcb-vscode"
        install-vscode-extension "ms-dotnettools.csharp"
        install-vscode-extension "nico-castell.linux-desktop-file"

        if does-bin-exist "code" "code-oss" "codium"; then
            does-bin-exist "nautilus" && install-pkg code-nautilus-git
        fi

        install_flatpak com.getpostman.Postman
    fi

    # Tools
    install_flatpak com.simplenote.Simplenote

    install-pkg xorg-xdpyinfo
    install-pkg xorg-xkill
    install-pkg start-wmclass
fi
