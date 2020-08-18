#!/bin/bash
ARCH=${1}
IS_EFI=0

if [ -d "/sys/firmware/efi/efivars" ]; then
	IS_EFI=1
fi

TEMP_DIR_PATH=".temp-sysinstall"
mkdir -p "$TEMP_DIR_PATH"
cd "$TEMP_DIR_PATH"

CHASSIS_TYPE="Desktop"

if [ -d "/sys/module/battery" ]; then
    CHASSIS_TYPE="Laptop"
fi

function is-package-installed() {
	PKG=$1

	if (pacman -Q "${PKG}" > /dev/null); then
		echo 1
	else
		echo 0
	fi
}

function call-package-manager() {
	ARGS=$*
    PKG="${@: -1}"

	if [ $(is-package-installed "${PKG}") -eq 0 ]; then
		echo " >>> Installing package '${PKG}'"
		if [ -f "/usr/bin/yaourt" ]; then
			yaourt --noconfirm ${ARGS}
		else
			sudo pacman --noconfirm ${ARGS}
		fi
#	else
#		echo " >>> Skipping package '$PKG' (already installed)"
	fi
}

function install-pkg() {
	PKG="$1"

	call-package-manager -S --needed "${PKG}"
}

function install-dep() {
	PKG="$1"

	call-package-manager -S --needed --asdeps "${PKG}"
}

function install-pkg-aur-manually() {
	PKG=$1

	if [ $(is-package-installed "${PKG}") -eq 0 ]; then
       PKG_SNAPSHOT_URL="https://aur.archlinux.org/cgit/aur.git/snapshot/${PKG}.tar.gz"

        wget ${PKG_SNAPSHOT_URL}
	    tar xvf ${PKG}.tar.gz

    	cd ${PKG}
	    makepkg -sri --noconfirm
	    cd ..
    fi
}

# base-devel
install-pkg binutils
install-pkg gcc
install-pkg pkgconf
install-pkg make
install-pkg fakeroot
install-pkg patch

# Basics
install-pkg bash-completion
install-pkg sudo
install-pkg man
install-pkg sl
install-pkg most
install-pkg wget
install-pkg usbutils
install-pkg lshw

install-dep dialog
install-dep wpa_supplicant
install-pkg net-tools
install-pkg wireless_tools
install-pkg wol
install-pkg dnsutils

install-pkg openssl-1.0 # Required to run ASP .NET Core apps

# Package manager
install-pkg-aur-manually package-query
install-pkg-aur-manually yaourt
install-pkg pacman-contrib
install-pkg pacutils

# Partition editors
install-pkg parted

# Filesystems
install-pkg ntfs-3g
install-pkg exfat-utils
install-pkg xfsprogs

# Archives
install-pkg unzip
install-pkg unrar
install-pkg unace
install-pkg p7zip
install-pkg lrzip

install-pkg cron

# CLI
install-pkg nano-syntax-highlighting

# Development
install-pkg git
install-pkg automake

# Monitoring
install-pkg alsi

if [ "${ARCH}" == "x86_64" ]; then
    install-pkg grub
    install-pkg update-grub

    # First things first
    install-pkg dkms
    install-dep linux-headers

    install-pkg gksu

    # System management
    install-pkg thermald

    # Runtimes
    install-pkg python
    install-pkg python2
    install-pkg mono
    install-pkg dotnet-runtime
    install-pkg aspnet-runtime
    install-pkg jre-openjdk-headless

    # Display Server, Drivers, FileSystems, etc
    install-pkg xorg-server
    install-pkg xf86-video-vesa
    install-pkg xclip

    # Desktop Environment & Base applications
    install-pkg gnome-shell
    install-pkg gdm

    install-pkg networkmanager
    install-pkg networkmanager-openvpn
    install-pkg networkmanager-pptp
    install-pkg networkmanager-vpnc
    install-dep modemmanager
    install-dep dnsmasq
    install-dep system-config-printer

    install-pkg gnome-keyring
    install-dep gnome-control-center
    install-pkg gnome-system-monitor
    install-pkg gnome-terminal
    install-pkg gnome-disk-utility
    install-pkg gnome-calculator
    install-pkg gnome-contacts
    install-pkg gnome-weather

    install-pkg gnome-dds-thumbnailer

    install-pkg gnome-tweaks
    install-pkg dconf-editor

    install-pkg seahorse
    install-pkg gedit
    install-pkg evince
    install-pkg baobab

    install-pkg eog
    install-dep eog-plugins

    install-pkg file-roller
    install-dep gnome-menus

    install-dep gvfs-afc
    install-dep gvfs-smb
    install-dep gvfs-gphoto2
    install-dep gvfs-mtp
    install-dep gvfs-goa
    install-dep gvfs-nfs
    install-dep gvfs-google

    install-pkg gnome-shell-extensions
    install-pkg gnome-shell-extension-installer
    install-pkg gnome-shell-extension-dash-to-dock
    install-pkg gnome-shell-extension-mpris-indicator-button-git
    install-pkg gnome-shell-extension-sound-output-device-chooser
    install-pkg gnome-shell-extension-gsconnect-git
    install-pkg gnome-shell-extension-multi-monitors-add-on-git
    install-pkg gnome-shell-extension-remove-dropdown-arrows
    install-pkg gnome-shell-extension-activities-config
    install-pkg gnome-shell-extension-openweather-git

    # Themes
    install-pkg adapta-gtk-theme
    install-dep gtk-engine-murrine

    install-pkg numix-circle-icon-theme-git
    install-pkg papirus-icon-theme
    install-pkg paper-icon-theme

    install-pkg gnome-backgrounds

    install-pkg folder-color-nautilus-bzr

    # Fonts
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
    install-pkg ttf-freefont
    install-pkg ttf-hannom # Vietnamese
    install-pkg ttf-ubraille # Braille

    # Internet
    install-pkg google-chrome
    install-pkg transmission-gtk

    install-pkg chrome-gnome-shell

    # Communication
    install-pkg whatsapp-nativefier-dark

    # Multimedia
    install-pkg spotify
    install-pkg lollypop
    install-pkg totem

    install-dep gst-plugins-ugly
    install-dep gst-libav

    # Graphics
    install-pkg gimp
    install-pkg gimp-dds
    install-pkg inkscape

    # Gaming
    install-pkg steam
    install-dep steam-native-runtime
    install-pkg proton-ge-custom-stable-bin

    # Development
    install-pkg dotnet-sdk
    #install-pkg jdk
    install-pkg electron

    install-pkg monogame-bin
    install-pkg visual-studio-code-bin

    install-pkg chromedriver

    # Tools
    install-pkg google-keep-nativefier

    # Automation
    install-pkg xdotool
    install-pkg wmctrl

    # Filesystem / Partitioning
    install-pkg gparted
    install-dep nilfs-utils
    install-dep gpart
    install-dep mtools
    install-dep udftools
    install-dep f2fs-tools

    install-pkg xorg-xkill
    install-pkg start-wmclass

    # Libraries
    install-pkg libc++
fi

if [ "${CHASSIS_TYPE}" == "Laptop" ]; then
    install-pkg acpi
fi

########### END
cd ~
rm -rf "$TEMP_DIR_PATH"
