#!/bin/bash
source "scripts/common/common.sh"

function is-package-installed() {
	PKG="${1}"

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	if (pacman -Q "${PKG}" > /dev/null); then
	    	return 0 # True
	    else
		    return 1 # False
	    fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        if (pkg list-installed | grep "^${PKG}/" > /dev/null); then
	    	return 0 # True
        else
		    return 1 # False
        fi
    fi
}

function call-package-manager() {
	local ARGS="${@:1:$#-1}"
    local PKG="${@: -1}"

	if (! is-package-installed "${PKG}"); then
		echo " >>> Installing package '${PKG}'"

        if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
            local ARCH_COMMON_ARGS="${PM_ARGS} --noconfirm --needed"

    		if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME="" paru ${ARGS} "${PKG}" ${ARCH_COMMON_ARGS} --noprovides --noredownload --norebuild --sudoloop
		    elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME="" yay ${ARGS} "${PKG}" ${ARCH_COMMON_ARGS}
    		elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME="" yaourt ${ARGS} "${PKG}" ${ARCH_COMMON_ARGS}
		    else
			    LANG=C LC_TIME="" run-as-su pacman ${ARGS} "${PKG}" ${ARCH_COMMON_ARGS}
		    fi
        elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
            yes | pkg ${ARGS} "${PKG}"
        fi
#	else
#		echo " >>> Skipping package '$PKG' (already installed)"
	fi
}

function install-pkg() {
	local PKG="${1}"

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        call-package-manager install "${PKG}"
    fi
}

function install-dep() {
	local PKG="${1}"

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        call-package-manager install "${PKG}" # TODO: See if there is a way to mark them as dep
    fi
}

function download-file {
	local URL="${1}"
	local FILE="${2}"

	[ ! -f "${FILE}" ] && wget "${URL}" -O "${FILE}"
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
