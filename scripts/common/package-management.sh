#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "scripts/common/filesystem.sh"
    source "${REPO_DIR}/scripts/common/common.sh"
fi

GLOBAL_GS_EXTENSIONS_DIR="${ROOT_USR_SHARE}/gnome-shell/extensions"
LOCAL_GS_EXTENSIONS_DIR="${HOME_LOCAL_SHARE}/gnome-shell/extensions"

function call_package_manager() {
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        if [[ "${UID}" != "0" ]]; then
            if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME="" paru ${*} --noconfirm --noprovides --noredownload --norebuild --sudoloop
		    elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME="" yay ${*} --noconfirm
        	elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME="" yaourt ${*} --noconfirm
		    else
		        LANG=C LC_TIME="" run_as_su pacman ${*} --noconfirm
		    fi
        else
            LANG=C LC_TIME="" pacman ${*} --noconfirm
        fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        yes | pkg ${*}
    elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        yes | run_as_su apt ${*}
    fi
}

function call_flatpak() {
    flatpak ${*} --assumeyes
}

function call_vscode() {
    if does_bin_exist "codium"; then
        codium ${*}
    elif does_bin_exist "code-oss"; then
        code-oss ${*}
    elif does_bin_exist "code"; then
        code ${*}
    fi
}

function call_gnome_shell_extension_installer() {
    local EXTENSION="${1}" && shift
    local EXTENSION_ID="${EXTENSION}"

    if ! [[ ${EXTENSION} =~ ^[0-9]+$ ]]; then
        EXTENSION_ID=$(echo "q" | \
            gnome-shell-extension-installer -s "${EXTENSION}" | \
            grep "\"link\": \"/extension" | \
            head -n 1 | \
            sed 's/^.*\"link\": \"\/extension\/\([0-9]\+\).*/\1/g')
    fi

    #if ${HAS_SU_PRIVILEGES}; then
    #    run_as_su gnome-shell-extension-installer --yes ${*} "${EXTENSION_ID}"
    #else
        gnome-shell-extension-installer --yes ${*} "${EXTENSION_ID}"
    #fi
}

function is_native_package_installed() {
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

function is_flatpak_installed() {
    local PKG="${1}"

    if (flatpak list | grep -q "${PKG}" > /dev/null); then
        return 0 # True
    else
        return 1 # False
    fi
}

function is_vscode_extension_installed() {
    local EXTENSION="${1}"
    local INSTALLED_EXTENSIONS=$(call_vscode --list-extensions)

    if echo "${INSTALLED_EXTENSIONS}" | grep -q "${EXTENSION}"; then
        return 0 # True
    else
        return 1 # False
    fi
}

function is_gnome_shell_extension_installed() {
    local EXTENSION_NAME="${*}"

    if [ -d "${GLOBAL_GS_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${GLOBAL_GS_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")
        [ -n "${EXTENSION_PATH}" ] && return 0 # True
    fi

    if [ -d "${LOCAL_GS_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${LOCAL_GS_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")
        [ -n "${EXTENSION_PATH}" ] && return 0 # True
    fi

    return 1 # False
}

function is_steam_app_installed() {
    local STEAM_APP_ID="${1}"

    if [ -f "${HOME_LOCAL_SHARE}/Steam/steamapps/appmanifest_${STEAM_APP_ID}.acf" ]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function install_native_package() {
	local PKG="${1}"

    is_native_package_installed "${PKG}" && return

    echo -e " >>> Installing native package: \e[0;33m${PKG}\e[0m..."
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
    	call_package_manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        call_package_manager install "${PKG}"
    fi
}

function install_native_package_dependency() {
	local PKG="${1}"

    is_native_package_installed "${PKG}" && return

    echo -e " >>> Installing native package dependency: \e[0;33m${PKG}\e[0m..."
    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        call_package_manager -S --asexplicit "${PKG}"
    elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
      || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        call_package_manager install "${PKG}" # TODO: See if there is a way to mark them as dep
    fi
}

function install_flatpak() {
    local PACKAGE="${1}"
    local REMOTE="flathub"

    if [ $# -eq 2 ]; then
        local REMOTE="${1}"
        local PACKAGE="${2}"
    fi

    is_flatpak_installed "${PACKAGE}" && return

    echo -e " >>> Installing flatpak: \e[0;33m${PACKAGE}\e[0m (${REMOTE})..."
    if ${HAS_SU_PRIVILEGES}; then
        call_flatpak install --system "${REMOTE}" "${PACKAGE}"
    else
        call_flatpak install --user "${REMOTE}" "${PACKAGE}"
    fi
}

function install_vscode_package() {
    local EXTENSION="${*}"

    is_vscode_extension_installed "${EXTENSION}" && return

    echo -e " >>> Installing VS Code extension: \e[0;33m${EXTENSION}\e[0m..."
    call_vscode --install-extension "${EXTENSION}"
}

function install_gnome_shell_extension() {
    local EXTENSION="${1}"

    is_gnome_shell_extension_installed "${EXTENSION}" && return

    echo -e " >>> Installing GNOME Shell extension: \e[0;33m${EXTENSION}\e[0m..."
    call_gnome_shell_extension_installer "${EXTENSION}"
}

function uninstall_native_package() {
    for PKG in ${*// /\n}; do
        is_native_package_installed "${PKG}" || return

        echo " >>> Uninstalling package: ${PKG}"
        if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
            call_package_manager -Rns "${PKG}"
        elif [[ "${DISTRO_FAMILY}" == "Android" ]] \
          || [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
            call_package_manager remove "${PKG}"
        fi
    done
}

function uninstall_flatpak() {
    local PACKAGE="${1}"

    ! is_flatpak_installed "${PACKAGE}" && return

    echo -e " >>> Uninstalling flatpak: \e[0;33m${PACKAGE}\e[0m..."
    call_flatpak uninstall "${PACKAGE}"
}

function install_aur_package_manually() {
	local PKG="${1}"

    is_native_package_installed "${PKG}" && return

    local PKG_SNAPSHOT_URL="https://aur.archlinux.org/cgit/aur.git/snapshot/${PKG}.tar.gz"
    local OLD_PWD="$(pwd)"

    [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"

    cd "${LOCAL_INSTALL_TEMP_DIR}"
    echo -e " >>> Installing AUR package manually: \e[0;33m${PKG}\e[0m..."

    wget "${PKG_SNAPSHOT_URL}"
    tar xvf "${PKG}.tar.gz"

    cd "${PKG}"
    makepkg -sri --noconfirm
    cd "${OLD_PWD}"
}
