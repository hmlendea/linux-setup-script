#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/common.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

GLOBAL_GS_EXTENSIONS_DIR="${ROOT_USR_SHARE}/gnome-shell/extensions"
LOCAL_GS_EXTENSIONS_DIR="${XDG_DATA_HOME}/gnome-shell/extensions"

function call_package_manager() {
    if [ "${DISTRO_FAMILY}" = "Arch" ]; then
        if [ "${UID}" != '0' ]; then
            if [ -f "${ROOT_USR_BIN}/paru" ]; then
                LANG=C LC_TIME='' paru ${*} --noconfirm --noprovides --noredownload --norebuild --sudoloop
		    elif [ -f "${ROOT_USR_BIN}/yay" ]; then
                LANG=C LC_TIME='' yay ${*} --noconfirm
        	elif [ -f "${ROOT_USR_BIN}/yaourt" ]; then
                LANG=C LC_TIME='' yaourt ${*} --noconfirm
		    else
		        LANG=C LC_TIME='' run_as_su pacman ${*} --noconfirm
		    fi
        else
            LANG=C LC_TIME='' pacman ${*} --noconfirm
        fi
    elif [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        yes | run_as_su apk ${*}
    elif [ "${DISTRO_FAMILY}" = 'Android' ]; then
        yes | pkg ${*}
    elif [ "${DISTRO_FAMILY}" = 'Debian' ]; then
        yes | run_as_su apt ${*}
    fi
}

function call_android_package_manager() {
    run_as_su pm ${*}
}

function call_flatpak() {
    flatpak ${*} --assumeyes
}

function call_vscode() {
    if does_bin_exist 'com.visualstudio.code'; then
        com.visualstudio.code ${*}
    elif does_bin_exist 'codium'; then
        codium ${*}
    elif does_bin_exist 'code-oss'; then
        code-oss ${*}
    elif does_bin_exist 'code'; then
        code ${*}
    fi
}

function call_gnome_shell_extension_installer() {
    local EXTENSION="${1}" && shift
    local EXTENSION_ID="${EXTENSION}"

    if ! [[ ${EXTENSION} =~ ^[0-9]+$ ]]; then
        EXTENSION_ID=$(echo 'q' | \
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

function is_package_installed() {
    local PACKAGE="${1}"

    is_native_package_installed "${PACKAGE}" && return 0
    is_flatpak_installed "${PACKAGE}" && return 0
    is_android_package_installed "${PACKAGE}" && return 0

    return 1
}

function is_native_package_installed() {
	local PKG="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        if (call_package_manager info | grep -q "^${PKG}$"); then
            return 0 # True
        else
            return 1 # False
        fi
    elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    	if (pacman -Q | grep -q "^${PKG}\s" > /dev/null); then
	    	return 0 # True
	    else
		    return 1 # False
	    fi
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ]; then
        if (apt-cache policy "${PKG}" | grep -q '^\s*Installed:\s*[0-9]'); then
	    	return 0 # True
        else
		    return 1 # False
        fi
    fi
}

function is_android_package_installed() {
    [ "${DISTRO_FAMILY}" != 'Android' ] && return 1

    local PACKAGE="${1}"

    if call_android_package_manager list packages | grep -q "^package:${PACKAGE}$"; then
        return 0 # True
    else
        return 1 # False
    fi
}

function is_flatpak_installed() {
    local PKG="${1}"

    local PACKAGE_NAME=$(echo "${PKG}" | awk -F"/" '{print $1}')
    local PACKAGE_ARCH=$(echo "${PKG}" | awk -F"/" '{print $2}')
    local PACKAGE_BRANCH=$(echo "${PKG}" | awk -F"/" '{print $3}')

    ! does_bin_exist 'flatpak' && return 1 # False

    if (flatpak list | grep -q "${PACKAGE_NAME}" > /dev/null); then
        if [ -z "${PACKAGE_BRANCH}" ]; then
            return 0 # True
        elif (flatpak list | grep "${PACKAGE_NAME}" | grep -q "${PACKAGE_BRANCH}" > /dev/null); then
            return 0 # True
        fi
    fi

    return 1 # False
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

    if [ -f "${XDG_DATA_HOME}/Steam/steamapps/appmanifest_${STEAM_APP_ID}.acf" ]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function is_native_package_required() {
    local PACKAGE_NAME="${1}"

    if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        if pacman -Qi "${PACKAGE_NAME}" | grep -q '^Required By\s*:\s*None\s*$'; then
            return 1 # False, Not required
        else
            return 0 # True, Required
        fi
    else
        # TODO: Implement this
        return 1 # False, Not required
    fi
}

function install_native_package() {
	local PACKAGE="${1}"

    is_native_package_installed "${PACKAGE}" && return

    echo -e " >>> Installing native package: \e[0;33m${PACKAGE}\e[0m..."
    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        call_package_manager add "${PACKAGE}"
    elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        call_package_manager -S --asexplicit "${PACKAGE}"
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ]; then
        call_package_manager install "${PACKAGE}"
    fi
}

function install_native_package_dependency() {
	local PACKAGE="${1}"

    is_native_package_installed "${PACKAGE}" && return

    echo -e " >>> Installing native package dependency: \e[0;33m${PACKAGE}\e[0m..."
    if [ "${DISTRO_FAMILY}" = 'Arch' ]; then
        call_package_manager -S --asexplicit "${PACKAGE}"
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ]; then
        call_package_manager install "${PACKAGE}" # TODO: See if there is a way to mark them as dep
    fi
}

function install_android_package() {
    [ "${DISTRO_FAMILY}" != 'Android' ] && return

	local PACKAGE="${1}"
    local PACKAGE_NAME="${2}"

    [ -z "${PACKAGE_NAME}" ] && PACKAGE_NAME=$(echo "${PACKAGE}" | sed 's/.*\/\([^\/]*\)\.apk$/\1/g')

    is_android_package_installed "${PACKAGE_NAME}" && return

    echo -e " >>> Installing Android package: \e[0;33m${PACKAGE_NAME}\e[0m..."
    call_android_package_manager install --user 0 "${PACKAGE}"
}

function install_android_remote_package() {
    [[ "${DISTRO_FAMILY}" != "Android" ]] && return

    local PACKAGE_URL="${1}"
    local PACKAGE_NAME="${2}"

    [ -z "${PACKAGE_NAME}" ] && PACKAGE_NAME=$(echo "${PACKAGE_URL}" | sed 's/.*\/\([^\/]*\)\.apk.*/\1/g')

    is_android_package_installed "${PACKAGE_NAME}" && return

    [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"

    wget "${PACKAGE_URL}" -c -O "${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}.apk"
    install_android_package "${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}.apk"
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
    if ${HAS_SU_PRIVILEGES} && [ "${CHASSIS_TYPE}" != 'Phone' ]; then
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

function uninstall_package() {
    local PACKAGE="${1}"

    uninstall_native_package "${PACKAGE}"
    uninstall_flatpak "${PACKAGE}"
    uninstall_android_package "${PACKAGE}"
}

function uninstall_native_package() {
    for PACKAGE_NAME in ${*// /\n}; do
        is_native_package_installed "${PACKAGE_NAME}" || return
        is_native_package_required "${PACKAGE_NAME}" && return

        echo " >>> Uninstalling package: ${PACKAGE_NAME}"
        if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
            call_package_manager del "${PACKAGE_NAME}"
        elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
            call_package_manager -Rns "${PACKAGE_NAME}"
        elif [ "${DISTRO_FAMILY}" = 'Android' ] \
          || [ "${DISTRO_FAMILY}" = 'Debian' ]; then
            call_package_manager remove "${PACKAGE_NAME}"
        fi
    done
}

function uninstall_android_package() {
    [ "${DISTRO_FAMILY}" != 'Android' ] && return

    for PACKAGE in ${*// /\n}; do
        is_android_package_installed "${PACKAGE}" || return

        echo -e " >>> Uninstalling Android package: \e[0;33m${PACKAGE}\e[0m..."
        call_android_package_manager uninstall --user 0 "${PACKAGE}"
    done
}

function uninstall_flatpak() {
    local PACKAGE="${1}"

    ! is_flatpak_installed "${PACKAGE}" && return

    echo -e " >>> Uninstalling flatpak: \e[0;33m${PACKAGE}\e[0m..."
    call_flatpak uninstall "${PACKAGE}"
}

function uninstall_gnome_shell_extension() {
    local EXTENSION_NAME="${*}"

    ! is_gnome_shell_extension_installed "${EXTENSION_NAME}" && return

    echo -e " >>> Uninstalling GNOME Shell extension: \e[0;33m${EXTENSION_NAME}\e[0m..."

    if [ -d "${GLOBAL_GS_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${GLOBAL_GS_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")

        if [ -n "${EXTENSION_PATH}" ]; then
            run_as_su rm -rf "${EXTENSION_PATH}"
        fi
    fi

    if [ -d "${LOCAL_GS_EXTENSIONS_DIR}" ]; then
        local EXTENSION_PATH=$(find "${LOCAL_GS_EXTENSIONS_DIR}" -type d -name "${EXTENSION_NAME}@*")

        if [ -n "${EXTENSION_PATH}" ]; then
            rm -rf "${EXTENSION_PATH}"
        fi
    fi
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
