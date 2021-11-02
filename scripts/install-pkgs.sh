#!/bin/bash
source "scripts/common/common.sh"

TEMP_DIR_PATH=".temp-sysinstall"
mkdir -p "$TEMP_DIR_PATH"
cd "$TEMP_DIR_PATH"

function is-package-installed() {
	PKG=$1

    if [ "${DISTRO_FAMILY}" == "arch" ]; then
    	if (pacman -Q "${PKG}" > /dev/null); then
	    	echo 1
	    else
		    echo 0
	    fi
    elif [ "${DISTRO_FAMILY}" == "android" ]; then
        if (pkg list-installed | grep "^${PKG}/" > /dev/null); then
            echo 1
        else
            echo 0
        fi
    fi
}

function call-package-manager() {
	ARGS=${@:1:$#-1}
    PKG="${@: -1}"

	if [ $(is-package-installed "${PKG}") -eq 0 ]; then
		echo " >>> Installing package '${PKG}'"
        if [ "${DISTRO_FAMILY}" == "arch" ]; then
            ARCH_COMMON_ARGS="${PM_ARGS} --noconfirm --needed"

    		if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME="" paru ${ARGS} ${PKG} ${ARCH_COMMON_ARGS} --noprovides --noredownload --norebuild --sudoloop
		    elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME="" yay ${ARGS} ${PKG} ${ARCH_COMMON_ARGS}
    		elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME="" yaourt ${ARGS} ${PKG} ${ARCH_COMMON_ARGS}
		    else
			    LANG=C LC_TIME="" run-as-su pacman ${ARGS} ${PKG} ${ARCH_COMMON_ARGS}
		    fi
        elif [ "${DISTRO_FAMILY}" == "android" ]; then
            yes | pkg ${ARGS} ${PKG}
        fi
#	else
#		echo " >>> Skipping package '$PKG' (already installed)"
	fi
}

function install-pkg() {
	PKG="${1}"

    if [ "${DISTRO_FAMILY}" == "arch" ]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [ "${DISTRO_FAMILY}" == "android" ]; then
        call-package-manager install "${PKG}"
    fi
}

function install-dep() {
	PKG="${1}"

    if [ "${DISTRO_FAMILY}" == "arch" ]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [ "${DISTRO_FAMILY}" == "android" ]; then
        call-package-manager install "${PKG}" # TODO: See if there is a way to mark them as dep
    fi
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

##############
### Basics ###
##############
install-pkg coreutils
install-pkg man
install-pkg most
install-pkg wget

if [ "${DISTRO_FAMILY}" == "arch" ]; then
    install-pkg bash-completion
    install-pkg usbutils
    install-pkg lshw

    install-pkg man-pages
    install-pkg sudo
elif [ "${DISTROY_FAMILY}" == "android" ]; then
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

if [ "${DISTRO_FAMILY}" == "arch" ]; then
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
install-pkg neofetch

##################
### Networking ###
##################
install-pkg dnsutils
install-pkg net-tools
install-pkg openssh
install-pkg wol

if [ "${DISTRO_FAMILY}" == "arch" ]; then
    install-pkg wireless_tools
    install-pkg wpa_supplicant
elif [ "${DISTRO_FAMILY}" == "Android" ]; then
    install-pkg wireless-tools
fi

################
### Archives ###
################
install-pkg cabextract
install-pkg unzip
install-pkg unrar

if [ "${DISTRO_FAMILY}" != "arch" ]; then
    exit
fi

install-pkg openssl-1.0 # Required to run ASP .NET Core apps

# Package manager
install-pkg-aur-manually package-query

[ "${ARCH}" == "armv7l" ] && install-pkg-aur-manually yay-bin \
                          || install-pkg-aur-manually paru-bin

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
install-pkg unace
install-pkg p7zip
install-pkg lrzip

install-pkg realtime-privileges

# CLI
install-pkg nano-syntax-highlighting

# Monitoring
install-pkg lm_sensors

if ${HAS_GUI}; then
    if [ "${ARCH_FAMILY}" == "x86" ]; then
        install-pkg grub
        install-dep os-prober
        install-pkg update-grub
        install-dep linux-headers
    fi

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
        install-pkg gnome-font-viewer

        install-pkg dialect
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

    ${POWERFUL_PC} && install-pkg gnome-bluetooth \
                   || install-pkg blueman

    ${POWERFUL_PC} && install-pkg gnome-system-monitor \
                   || install-pkg lxtask

    ${POWERFUL_PC} && install-pkg gnome-terminal \
                   || install-pkg lxterminal

    ${POWERFUL_PC} && install-pkg gnome-calculator \
                   || install-pkg mate-calc

    install-pkg gnome-disk-utility

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

    ${POWERFUL_PC} && install-pkg gedit \
                   || install-pkg pluma

    ${POWERFUL_PC} && install-pkg evince \
                   || install-pkg epdfview

    if ${POWERFUL_PC}; then
        install-pkg baobab
        install-pkg gnome-screenshot
    else
        install-pkg mate-utils
    fi

    ${POWERFUL_PC} && install-pkg eog \
                   || install-pkg gpicview

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
        install-pkg gnome-shell-extension-gsconnect
        install-pkg gnome-shell-extension-hide-activities-git
        install-pkg gnome-shell-extension-multi-monitors-add-on-git
        install-pkg gnome-shell-extension-openweather-git
        install-pkg gnome-shell-extension-wintile
    fi

    # Themes
    install-pkg zorin-desktop-themes
    install-pkg vimix-cursors
    install-pkg papirus-icon-theme
    install-pkg papirus-folders
    install-pkg grub-theme-vimix

    # Themes - Fallbacks
    install-pkg numix-circle-icon-theme-git
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
    install-pkg firefox
    install-pkg chrome-gnome-shell # Also used for Firefox

    ${POWERFUL_PC} && install-pkg fragments \
                   || install-pkg transmission-gtk

    # Communication
    install-pkg whatsapp-nativefier
    install-pkg telegram-desktop

    # Multimedia
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg spotify
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

    if [ "${ARCH_FAMILY}" == "x86" ]; then
        install-pkg electron
        install-pkg chromedriver
    fi

    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg visual-studio-code-bin
    [ "${ARCH_FAMILY}" == "arm" ] && install-pkg code-headmelted-bin

    # Tools
    [ "${ARCH_FAMILY}" == "x86" ] && install-pkg simplenote-electron-bin
    [ "${ARCH_FAMILY}" == "arm" ] && install-pkg simplenote-electron-arm-bin

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

if [ "${CHASSIS_TYPE}" == "Laptop" ]; then
    install-pkg acpi
fi

########### END
cd ~
rm -rf "$TEMP_DIR_PATH"
