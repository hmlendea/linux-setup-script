#!/bin/bash
ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g')
IS_EFI=0

if [ -z "${ARCH}" ]; then
    echo "You must provide the system architecture!"
    exit 1
fi

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"

if [ -d "/sys/firmware/efi/efivars" ]; then
	IS_EFI=1
fi

TEMP_DIR_PATH=".temp-sysinstall"
mkdir -p "$TEMP_DIR_PATH"
cd "$TEMP_DIR_PATH"

CPU_MODEL=$(cat /proc/cpuinfo | \
    grep "^model name" | \
    awk -F: '{print $2}' | \
    sed 's/^ *//g' | \
    head -n 1 | \
    sed 's/(TM)//g' | \
    sed 's/(R)//g' | \
    sed 's/ CPU//g' | \
    sed 's/@ .*//g')

CHASSIS_TYPE="Desktop"
POWERFUL_PC=true
HAS_GUI=false

if [ $(echo ${CPU_MODEL} | grep -c "Atom") -ge 1 ]; then
    POWERFUL_PC=false
fi

if [ -d "/sys/module/battery" ]; then
    CHASSIS_TYPE="Laptop"
fi

if [ -f "/etc/systemd/system/display-manager.service" ] || \
   [[ $(cat /etc/hostname) = *PC ]] || \
   [[ $(cat /etc/hostname) = *Top ]]; then
    HAS_GUI=true

    if [ "${ARCH_FAMILY}" == "arm" ]; then
        POWERFUL_PC=false
    fi
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
            LANG=C LC_TIME="" yaourt ${ARGS} --noconfirm
		else
			LANG=C LC_TIME="" sudo pacman ${ARGS} --noconfirm
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
install-pkg sudo
install-pkg man
install-pkg man-pages
install-pkg bash-completion
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
install-pkg yaourt-auto-sync

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
install-pkg lm_sensors

if ${HAS_GUI}; then
    if [ "${ARCH_FAMILY}" == "x86" ]; then
        install-pkg grub
        install-pkg update-grub
        install-dep linux-headers
    fi

    install-pkg openssh
    install-pkg dkms
    install-pkg rsync

    # System management
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg thermald

    # Runtimes
    install-pkg python
    install-pkg python2
    install-pkg mono
    install-pkg jre-openjdk-headless

    if [ "${ARCH_FAMILY}" == "x86" ]; then
        install-pkg dotnet-runtime
        install-pkg aspnet-runtime
    elif [ "${ARCH_FAMILY}" == "arm" ]; then
        install-pkg dotnet-runtime-bin
        install-pkg aspnet-runtime-bin
    fi

    # Display Server, Drivers, FileSystems, etc
    install-pkg xorg-server
    #install-pkg xf86-video-vesa

    # Desktop Environment & Base applications
    if ${POWERFUL_PC}; then
        install-pkg gnome-shell
        install-pkg gdm
        install-pkg xdg-user-dirs-gtk
        install-dep gnome-control-center
        install-pkg gnome-tweaks
        install-pkg gnome-backgrounds

        install-dep system-config-printer # Dep for gnome-control-center
    else
        install-pkg openbox
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

    if ${POWERFUL_PC}; then
        install-pkg gnome-bluetooth
    else
        install-pkg blueman
    fi

    ${POWERFUL_PC} && install-pkg gnome-system-monitor || install-pkg lxtask
    ${POWERFUL_PC} && install-pkg gnome-terminal || install-pkg lxterminal
    ${POWERFUL_PC} && install-pkg gnome-calculator || install-pkg mate-calc
    install-pkg gnome-disk-utility

    if ${POWERFUL_PC}; then
        install-pkg gnome-clocks
        install-pkg gnome-contacts
        install-pkg gnome-weather
    fi

    # File management
    if ${POWERFUL_PC}; then
        install-pkg nautilus
        install-pkg folder-color-nautilus-bzr
        install-pkg gnome-dds-thumbnailer
        install-pkg file-roller

        install-pkg code-nautilus-git
    else
        install-pkg pcmanfm
        install-pkg xarchiver
    fi

    install-pkg dconf-editor

    ${POWERFUL_PC} && install-pkg gedit || install-pkg pluma
    ${POWERFUL_PC} && install-pkg evince || install-pkg epdfview

    if ${POWERFUL_PC}; then
        install-pkg baobab
        install-pkg gnome-screenshot
    else
        install-pkg mate-utils
    fi

    if ${POWERFUL_PC}; then
        install-pkg eog
        install-dep eog-plugins
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

    if ${POWERFUL_PC}; then
        install-pkg gnome-shell-extensions
        install-pkg gnome-shell-extension-installer
        install-pkg gnome-shell-extension-dash-to-dock
        install-pkg gnome-shell-extension-sound-output-device-chooser
        install-pkg gnome-shell-extension-gsconnect-git
        install-pkg gnome-shell-extension-multi-monitors-add-on-git
        install-pkg gnome-shell-extension-openweather-git
    fi

    # Themes
    install-pkg adapta-gtk-theme
    install-dep gtk-engine-murrine

    install-pkg numix-circle-icon-theme-git
    install-pkg papirus-icon-theme
    install-pkg paper-icon-theme

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
    #[ "${ARCH_FAMILY}" == "x86" ] && install-pkg google-chrome
    #[ "${ARCH_FAMILY}" == "arm" ] && install-pkg chromium
    #${POWERFUL_PC} && install-pkg chrome-gnome-shell

    install-pkg firefox
    install-pkg firefox-h264ify

    install-pkg transmission-gtk

    # Communication
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg whatsapp-nativefier-dark
    install-pkg telegram-desktop

    # Multimedia
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg spotify
    if ${POWERFUL_PC}; then
        install-pkg rhythmbox
        install-pkg totem

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
        if [ "${ARCH_FAMILY}" == "x86" ]; then
            install-pkg steam
            install-dep steam-native-runtime
            install-pkg proton-ge-custom-bin
        fi
    fi

    # Development
    install-pkg dotnet-sdk
    #install-pkg jdk

    if [ "${ARCH_FAMILY}" == "x86" ]; then
        install-pkg electron
        install-pkg monogame-bin
        install-pkg chromedriver
    fi

    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg visual-studio-code-bin
    [ "${ARCH_FAMILY}" == "arm" ] && install-pkg code-headmelted-bin

    # Tools
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg google-keep-nativefier

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
    #install-pkg libc++
fi

if [ "${CHASSIS_TYPE}" == "Laptop" ]; then
    install-pkg acpi
fi

########### END
cd ~
rm -rf "$TEMP_DIR_PATH"
