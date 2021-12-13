#!/bin/bash
source "scripts/common/common.sh"

function is-package-installed() {
	PKG="${1}"

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	if (pacman -Q | grep -q "^${PKG}\s" > /dev/null); then
	    	return 0 # True
	    else
		    return 1 # False
	    fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        if (apt-cache policy "${PKG}" | grep -q "^\s*Installed:"); then
	    	return 0 # True
        else
		    return 1 # False
        fi
    fi
}

function call-package-manager() {
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        if [[ "${UID}" != "0" ]]; then
            if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME="" paru ${*} --noconfirm --noprovides --noredownload --norebuild --sudoloop
		    elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME="" yay ${*} --noconfirm
        	elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME="" yaourt ${*} --noconfirm
		    else
		        LANG=C LC_TIME="" run-as-su pacman ${*} --noconfirm
		    fi
        else
            LANG=C LC_TIME="" pacman ${*} --noconfirm
        fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        yes | pkg ${*}
    fi
}

function install-pkg() {
	local PKG="${1}"

    is-package-installed "${PKG}" && return

    echo " >>> Installing package: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        call-package-manager install "${PKG}"
    fi
}

function install-dep() {
	local PKG="${1}"

    is-package-installed "${PKG}" && return

    echo " >>> Installing dependency: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        call-package-manager install "${PKG}" # TODO: See if there is a way to mark them as dep
    fi
}

function uninstall-pkg() {
	local PKG="${1}"

    is-package-installed "${PKG}" || return

    echo " >>> Uninstalling package: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        call-package-manager -Rns "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        call-package-manager remove "${PKG}"
    fi
}

function uninstall-pkgs() {
    for PKG in ${*// /\n}; do
        is-package-installed "${PKG}" || return

        echo " >>> Uninstalling package: ${PKG}"
        if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
            call-package-manager -Rns "${PKG}"
        elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
            call-package-manager remove "${PKG}"
        fi
    done
}

function install-pkg-aur-manually() {
	local PKG="${1}"
    local PKG_SNAPSHOT_URL="https://aur.archlinux.org/cgit/aur.git/snapshot/${PKG}.tar.gz"

	if (! is-package-installed "${PKG}"); then
        wget "${PKG_SNAPSHOT_URL}"
	    tar xvf "${PKG}.tar.gz"

    	cd "${PKG}"
	    makepkg -sri --noconfirm
	    cd ..
    fi
}
