#!/bin/bash
source "scripts/common/common.sh"

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
    elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        yes | run-as-su apt ${*}
    fi
}

function call-vscode() {
    if does-bin-exist "codium"; then
        codium ${*}
    elif does-bin-exist "code-oss"; then
        code-oss ${*}
    elif does-bin-exist "code"; then
        code ${*}
    fi
}

function is-package-installed() {
	local PKG="${1}"

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	if (pacman -Q | grep -q "^${PKG}\s" > /dev/null); then
	    	return 0 # True
	    else
		    return 1 # False
	    fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        if (apt-cache policy "${PKG}" | grep -q "^\s*Installed:\s*[0-9]"); then
	    	return 0 # True
        else
		    return 1 # False
        fi
    fi
}

function is-vscode-extension-installed() {
    local EXTENSION="${1}"
    local INSTALLED_EXTENSIONS=$(call-vscode --list-extensions)

    if echo "${INSTALLED_EXTENSIONS}" | grep -q "${EXTENSION}"; then
        return 0 # True
    else
        return 1 # False
    fi
}

function install-pkg() {
	local PKG="${1}"

    is-package-installed "${PKG}" && return

    echo " >>> Installing package: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        call-package-manager install "${PKG}"
    fi
}

function install-dep() {
	local PKG="${1}"

    is-package-installed "${PKG}" && return

    echo " >>> Installing dependency: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        call-package-manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        call-package-manager install "${PKG}" # TODO: See if there is a way to mark them as dep
    fi
}

function install-vscode-extension() {
    local EXTENSION="${*}"

    is-vscode-extension-installed "${EXTENSION}" && return

    echo " >>> Installing VS Code extension: ${EXTENSION}"
    call-vscode --install-extension "${EXTENSION}"
}

function uninstall-pkg() {
	local PKG="${1}"

    is-package-installed "${PKG}" || return

    echo " >>> Uninstalling package: ${PKG}"
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        call-package-manager -Rns "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        call-package-manager remove "${PKG}"
    fi
}

function uninstall-pkgs() {
    for PKG in ${*// /\n}; do
        is-package-installed "${PKG}" || return

        echo " >>> Uninstalling package: ${PKG}"
        if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
            call-package-manager -Rns "${PKG}"
        elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
          || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
            call-package-manager remove "${PKG}"
        fi
    done
}

function install-pkg-aur-manually() {
	local PKG="${1}"
    local PKG_SNAPSHOT_URL="https://aur.archlinux.org/cgit/aur.git/snapshot/${PKG}.tar.gz"
    local OLD_PWD="$(pwd)"

    [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"
    cd "${LOCAL_INSTALL_TEMP_DIR}"

	if (! is-package-installed "${PKG}"); then
        wget "${PKG_SNAPSHOT_URL}"
	    tar xvf "${PKG}.tar.gz"

    	cd "${PKG}"
	    makepkg -sri --noconfirm
	    cd ..
    fi

    cd "${OLD_PWD}"
}
