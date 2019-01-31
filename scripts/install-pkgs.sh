#!/bin/bash

IS_EFI=0

if [ -d "/sys/firmware/efi/efivars" ]; then
	IS_EFI=1
fi

TEMP_DIR_PATH=".temp-sysinstall"
mkdir -p "$TEMP_DIR_PATH"
cd "$TEMP_DIR_PATH"

function is-package-installed() {
	PKG=$1

	if (pacman -Q $PKG > /dev/null); then
		echo 1
	else
		echo 0
	fi
}

function call-package-manager() {
	ARGS=$*

	if [ $(is-package-installed $PKG) -eq 0 ]; then
		echo " >>> Installing package '$PKG'"

		if [ -f "/usr/bin/yaourt" ]; then
			yaourt --noconfirm $ARGS
		else
			pacman $ARGS
		fi
#	else
#		echo " >>> Skipping package '$PKG' (already installed)"
	fi
}

function install-pkg() {
	PKG="$1"

	call-package-manager -S --needed $PKG
}

function install-dep() {
	PKG="$1"

	call-package-manager -S --needed --asdeps $PKG
}

function download-file {
	URL=$1
	FILE=$2

	if [ ! -f "$FILE" ]; then
		wget "$URL" -O "$FILE"
	fi
}

function install-pkg-aur-manually() {
	PKG=$1

	if [ $(is-package-installed yaourt) -eq 0 ]; then
		download-file "https://aur.archlinux.org/cgit/aur.git/snapshot/$PKG.tar.gz" "$PKG.tar.gz"
		tar xvf $PKG.tar.gz

		cd $PKG
		makepkg -sri --noconfirm
		cd ..
	fi
}

install-pkg grub
install-pkg update-grub

# First things first
install-pkg dkms
install-dep linux-headers

install-pkg bash-completion
install-pkg sudo
install-pkg gksu
install-pkg wget
install-pkg sl
install-pkg most

install-dep dialog
install-dep wpa_supplicant
install-pkg net-tools

install-pkg cron

# Runtimes
install-pkg python
install-pkg python2
install-pkg mono
install-pkg dotnet-runtime
install-pkg jre

# Yaourt
install-pkg-aur-manually package-query
install-pkg-aur-manually yaourt

# Display Server, Drivers, FileSystems, etc
install-pkg xorg-server
install-pkg xf86-video-vesa

install-pkg ntfs-3g
install-pkg exfat-utils
install-pkg xfsprogs

install-dep unzip
install-dep unrar
install-dep unace
install-dep p7zip
install-dep lrzip

# Desktop Environment & Base applications
install-pkg gnome-shell
install-pkg gdm

install-pkg networkmanager
install-pkg networkmanager-openconnect
install-pkg networkmanager-openvpn
install-pkg networkmanager-pptp
install-pkg networkmanager-vpnc
install-dep modemmanager
install-dep dnsmasq

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
install-pkg libreoffice-fresh
install-pkg libreoffice-fresh-ro

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
install-pkg gnome-shell-extension-dash-to-dock
install-pkg gnome-shell-extension-gsconnect-git
install-pkg gnome-shell-extension-multi-monitors-add-on-git
install-pkg gnome-shell-extension-remove-dropdown-arrows
install-pkg gnome-shell-extension-no-topleft-hot-corner
install-pkg panther-launcher-git

# Themes
install-pkg materia-gtk-theme
install-dep gtk-engine-murrine

install-pkg numix-circle-icon-theme-git
install-pkg papirus-icon-theme
install-pkg paper-icon-theme

install-pkg gnome-backgrounds

install-pkg folder-color-bzr

# Fonts
install-dep ttf-liberation
install-dep ttf-roboto
install-dep ttf-croscore
install-dep noto-fonts
install-dep noto-fonts-emoji

# Internet
install-pkg google-chrome
install-pkg transmission-gtk
install-pkg filezilla
install-pkg dropbox

install-pkg chrome-gnome-shell

# Communication
install-pkg skypeforlinux-stable-bin
install-pkg whatsie

# Multimedia
install-pkg spotify
install-pkg popcorntime
install-pkg lollypop
install-pkg totem

install-dep gst-plugins-ugly
install-dep gst-libav

# Graphics
install-pkg gimp
install-pkg inkscape

# CLI
install-pkg nano-syntax-highlighting-git

# Gaming
install-pkg steam
install-dep steam-native-runtime
install-pkg air-for-steam

# Development
install-pkg dotnet-sdk
install-pkg jdk
install-pkg electron

install-pkg git

install-pkg monodevelop-stable
install-pkg monogame-bin
install-pkg code

install-pkg chromedriver

# Tools
install-pkg gparted
install-dep nilfs-utils
install-dep gpart
install-dep mtools
install-dep udftools
install-dep f2fs-tools

install-pkg xorg-xkill
install-pkg start-wmclass

########### END
#cd ~
#rm -rf "$TEMP_DIR_PATH"
