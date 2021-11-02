#!/bin/bash

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

	if [ $(is-package-installed "${PKG}") -eq 0 ]; then
		echo " >>> Installing package '$PKG'"

		if [ -f "/usr/bin/paru" ]; then
			paru --noconfirm $ARGS
		else
			run-as-su pacman --noconfirm $ARGS
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

function download-file {
	URL=$1
	FILE=$2

	if [ ! -f "$FILE" ]; then
		wget "$URL" -O "$FILE"
	fi
}

function install-pkg-aur-manually() {
	PKG=$1

	if [ $(is-package-installed ${PKG}) -eq 0 ]; then
		download-file "https://aur.archlinux.org/cgit/aur.git/snapshot/$PKG.tar.gz" "$PKG.tar.gz"
		tar xvf "${PKG}.tar.gz"

		cd "${PKG}"
		makepkg -sri --noconfirm
		cd ..
	fi
}
