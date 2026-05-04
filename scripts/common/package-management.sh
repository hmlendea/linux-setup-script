#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

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
    elif [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
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

function call_gnome_extensions() {
    local EXTENSION="${1}" && shift
    local EXTENSION_ID="${EXTENSION%%/*}"
    local UUID=""

    if ! [[ ${EXTENSION_ID} =~ ^[0-9]+$ ]]; then
        echo " !!! Invalid extension ID format: ${EXTENSION}"
        return 1
    fi

    # Fetch extension page (follow redirects)
    local EXTENSION_PAGE
    EXTENSION_PAGE=$(curl -Ls -w "\n%{http_code}" \
        "https://extensions.gnome.org/extension/${EXTENSION_ID}/")

    local HTTP_CODE
    HTTP_CODE=$(echo "${EXTENSION_PAGE}" | tail -n1)
    EXTENSION_PAGE=$(echo "${EXTENSION_PAGE}" | sed '$d')

    if [ "${HTTP_CODE}" != "200" ]; then
        echo " !!! Extension page not reachable for ID: ${EXTENSION_ID}"
        return 1
    fi

    # Extract UUID
    UUID=$(echo "${EXTENSION_PAGE}" | \
        grep -o 'data-uuid="[^"]*"' | \
        head -n1 | \
        cut -d '"' -f2)

    if [ -z "${UUID}" ]; then
        echo " !!! Failed to extract UUID for extension ID: ${EXTENSION_ID}"
        return 1
    fi

    # Detect GNOME Shell major version
    local SHELL_VERSION
    SHELL_VERSION=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)

    # Fetch extension info JSON
    local INFO_JSON
    INFO_JSON=$(curl -s -w "\n%{http_code}" \
        "https://extensions.gnome.org/extension-info/?uuid=${UUID}&shell_version=${SHELL_VERSION}")

    local INFO_HTTP
    INFO_HTTP=$(echo "${INFO_JSON}" | tail -n1)
    INFO_JSON=$(echo "${INFO_JSON}" | sed '$d')

    if [ "${INFO_HTTP}" != "200" ]; then
        echo " !!! Failed to fetch extension info for UUID: ${UUID}"
        return 1
    fi

    # Extract download URL
    local DOWNLOAD_URL
    DOWNLOAD_URL=$(echo "${INFO_JSON}" | \
        grep -o '"download_url":[[:space:]]*"[^"]*"' | \
        cut -d '"' -f4)

    if [ -z "${DOWNLOAD_URL}" ]; then
        echo " !!! Failed to get download URL for ${UUID} (GNOME ${SHELL_VERSION} compatibility issue?)"
        return 1
    fi

    local TMP_FILE
    TMP_FILE=$(mktemp --suffix=.zip)

    curl -L -o "${TMP_FILE}" "https://extensions.gnome.org${DOWNLOAD_URL}"

    if [ ! -s "${TMP_FILE}" ]; then
        echo " !!! Download failed for ${UUID}"
        return 1
    fi

    gnome-extensions install --force "${TMP_FILE}" || {
        echo " !!! Installation failed for ${UUID}"
        remove "${TMP_FILE}"
        return 1
    }

    remove "${TMP_FILE}"

    gnome-extensions list > /dev/null 2>&1
    gnome-extensions enable "${UUID}" 2>/dev/null || {
        echo " !!! Installed but failed to enable ${UUID}"
        return 1
    }
}

function is_package_installed() {
    local PACKAGE="${1}"

    if [ "${OS}" = 'Android' ]; then
        is_android_pacakge_installed "${PACKAGE}" && return 0
    elif [ "${OS}" = 'Linux' ]; then
        is_native_package_installed "${PACKAGE}" && return 0
        is_flatpak_installed "${PACKAGE}" && return 0
        is_github_package_installed "${PACKAGE}" && return 0
        is_webapp_installed "${PACKAGE}" && return 0
    fi
    
    return 1
}

function is_native_package_installed() {
	local PACKAGE_NAME="${1}"

    if [ "${DISTRO_FAMILY}" = 'Alpine' ]; then
        call_package_manager info -e "${PACKAGE_NAME}" >/dev/null 2>&1
        return $?
    elif [ "${DISTRO_FAMILY}" = 'Arch' ]; then
    	if (pacman -Q | grep -q "^${PACKAGE_NAME}\s" > /dev/null); then
	    	return 0 # True
	    else
		    return 1 # False
	    fi
    elif [ "${DISTRO_FAMILY}" = 'Android' ] \
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
        if (apt-cache policy "${PACKAGE_NAME}" | grep -q '^\s*Installed:\s*[0-9]'); then
	    	return 0 # True
        else
		    return 1 # False
        fi
    fi

    return 1
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

    for INSTALLATION_METHOD in 'user' 'system'; do
        if (flatpak list --columns=application | grep -q "^${PACKAGE_NAME}$" > /dev/null); then
            if [ -z "${PACKAGE_BRANCH}" ]; then
                return 0 # True
            elif (flatpak list --columns=application,branch | grep "^${PACKAGE_NAME}" | grep -q "${PACKAGE_BRANCH}$" > /dev/null); then
                return 0 # True
            fi
        fi
    done

    return 1 # False
}

function is_github_package_installed() {
    local PACKAGE_NAME="${1}"

    local PACKAGE_METADATA_DIR="${LINUX_SETUP_SCRIPT_PACKAGES_DIR}/${PACKAGE_NAME}"

    [ -d "${PACKAGE_METADATA_DIR}" ] || return 1
    [ -f "${PACKAGE_METADATA_DIR}/version" ] || return 1
    [ -f "${PACKAGE_METADATA_DIR}/medium" ] || return 1

    if grep -q '^github$' "${PACKAGE_METADATA_DIR}/medium"; then
        return 0
    fi

    return 1
}

function is_gnome_shell_extension_installed() {
    local EXTENSION="${1}"
    local EXTENSION_ID="${EXTENSION%%/*}"

    # Fetch UUID (same as install logic)
    local EXTENSION_PAGE
    EXTENSION_PAGE=$(curl -Ls "https://extensions.gnome.org/extension/${EXTENSION_ID}/")

    local UUID
    UUID=$(echo "${EXTENSION_PAGE}" | \
        grep -o 'data-uuid="[^"]*"' | \
        head -n1 | \
        cut -d '"' -f2)

    [ -z "${UUID}" ] && return 1

    gnome-extensions list | grep -qx "${UUID}"
}

function is_steam_app_installed() {
    local STEAM_APP_ID="${1}"

    if [ -f "${XDG_DATA_HOME}/Steam/steamapps/appmanifest_${STEAM_APP_ID}.acf" ]; then
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

function is_webapp_installed() {
    local PACKAGE_NAME="${1}"
    local DESKTOP_FILE="${XDG_DATA_HOME}/applications/${PACKAGE_NAME}.desktop"

    [ -f "${DESKTOP_FILE}" ]
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
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
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
      || [ "${DISTRO_FAMILY}" = 'Debian' ] \
      || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
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
    [ "${DISTRO_FAMILY}" != 'Android' ] && return

    local PACKAGE_URL="${1}"
    local PACKAGE_NAME="${2}"

    [ -n "${PACKAGE_NAME}" ] && PACKAGE_NAME=$(sed 's/\.apk$//g' <<< "${PACKAGE_NAME}")
    [ -z "${PACKAGE_NAME}" ] && PACKAGE_NAME=$(echo "${PACKAGE_URL}" | sed 's/.*\/\([^\/]*\)\.apk.*/\1/g')

    is_android_package_installed "${PACKAGE_NAME}" && return

    create_directory "${LOCAL_INSTALL_TEMP_DIR}"
    wget "${PACKAGE_URL}" -c -O "${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}.apk"

    install_android_package "${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}.apk"
}

function install_android_fdroid_package {
    local PACKAGE_NAME="${1}"
    local PACKAGE_INFO_JSON=$(curl -s "https://f-droid.org/api/v1/packages/${PACKAGE_NAME}")
    local PACKAGE_LATEST_VERSIONCODE=$(jq '.packages | max_by(.versionCode).versionCode' <<< "${PACKAGE_INFO_JSON}")
    local APK_URL="https://f-droid.org/repo/${PACKAGE_NAME}_${PACKAGE_LATEST_VERSIONCODE}.apk"

    install_android_remote_package "${APK_URL}" "${PACKAGE_NAME}"
}

function install_android_github_package {
    local PACKAGE_NAME="${1}"
    local REPOSITORY="${2}"
    local FILTER="${3}"
    local APK_URL=''

    if [ -z "${FILTER}" ]; then
        APK_URL=$(get_github_latest_release_asset "${REPOSITORY}")
    else
        APK_URL=$(get_github_latest_release_asset "${REPOSITORY}" | grep "${FILTER}")
    fi

    install_android_remote_package "${APK_URL}" "${PACKAGE_NAME}"
}

function install_aur_package_manually() {
	local PKG="${1}"

	is_native_package_installed "${PKG}" && return

    local PKG_SNAPSHOT_URL="https://aur.archlinux.org/cgit/aur.git/snapshot/${PKG}.tar.gz"
    local OLD_PWD="$(pwd)"

    [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"

    cd "${LOCAL_INSTALL_TEMP_DIR}"
    echo -e '>>> Installing AUR package manually: \e[0;33m${PKG}\e[0m...'

    wget "${PKG_SNAPSHOT_URL}"
    tar xvf "${PKG}.tar.gz"

    cd "${PKG}"
    makepkg -sri --noconfirm
    cd "${OLD_PWD}"
}

function install_flatpak() {
    local PACKAGE="${1}"
    local REMOTE="flathub"

    if [ $# -eq 2 ]; then
        local REMOTE="${1}"
        local PACKAGE="${2}"
    fi

    is_flatpak_installed "${PACKAGE}" && return

    local INSTALLATION_METHOD="user"

    echo -e " >>> Installing ${INSTALLATION_METHOD} flatpak (${REMOTE}): \e[0;33m${PACKAGE}\e[0m (${REMOTE})..."
    call_flatpak install --${INSTALLATION_METHOD} "${REMOTE}" "${PACKAGE}"
}

function install_github_package() {
    local PACKAGE_NAME="${1}"
    local REPOSITORY="${2}"

    local PACKAGE_METADATA_DIR="${LINUX_SETUP_SCRIPT_PACKAGES_DIR}/${PACKAGE_NAME}"

    local RELEASE_JSON
    RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPOSITORY}/releases/latest")

    local VERSION
    VERSION=$(echo "${RELEASE_JSON}" | jq -r '.tag_name')

    # Detect architecture
    local ARCH
    ARCH=$(dpkg --print-architecture)

    local ARCH_REGEX="${ARCH}"
    if [ "${ARCH}" = 'amd64' ]; then
        ARCH_REGEX='(amd64|x86_64)'
    elif [ "${ARCH}" = 'arm64' ]; then
        ARCH_REGEX='(arm64|aarch64)'
    fi

    local DOWNLOAD_URL

    DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | jq -r '.assets[] | .browser_download_url' | grep -E '\.deb$')

    # First try arch-specific match
    ARCH_MATCH=$(echo "${DOWNLOAD_URL}" | grep -E "${ARCH_REGEX}" | head -n1)

    if [ -n "${ARCH_MATCH}" ]; then
        DOWNLOAD_URL="${ARCH_MATCH}"
    else
        # Fallback to any .deb (e.g. Architecture: all)
        DOWNLOAD_URL=$(echo "${DOWNLOAD_URL}" | head -n1)
    fi

    if [ -z "${DOWNLOAD_URL}" ]; then
        echo " !!! No matching .deb asset found for ${REPOSITORY} (${ARCH})"
        return 1
    fi

    if is_github_package_installed "${PACKAGE_NAME}"; then
        local INSTALLED_VERSION
        INSTALLED_VERSION=$(run_as_su cat "${PACKAGE_METADATA_DIR}/version")

        if [ "${INSTALLED_VERSION}" = "${VERSION}" ]; then
            return
        fi
    fi

    echo -e " >>> Installing GitHub package: \e[0;33m${PACKAGE_NAME}\e[0m (${VERSION})..."

    local TMP_FILE="${LOCAL_INSTALL_TEMP_DIR}/${PACKAGE_NAME}-${VERSION}.deb"

    create_directory "${LOCAL_INSTALL_TEMP_DIR}"
    remove "${TMP_FILE}"

    trap 'remove "${TMP_FILE}"' RETURN

    wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"

    if [ ! -s "${TMP_FILE}" ]; then
        echo " !!! Download failed for ${PACKAGE_NAME}"
        return 1
    fi

    run_as_su apt install -y "${TMP_FILE}" || {
        echo " !!! Installation failed for ${PACKAGE_NAME}"
        return 1
    }

    create_directory "${PACKAGE_METADATA_DIR}"
    run_as_su sh -c "echo '${VERSION}' > '${PACKAGE_METADATA_DIR}/version'"
    run_as_su sh -c "echo 'github' > '${PACKAGE_METADATA_DIR}/medium'"
}

function install_gnome_shell_extension() {
    local EXTENSION="${1}"

    is_gnome_shell_extension_installed "${EXTENSION}" && return

    echo -e " >>> Installing GNOME Shell extension: \e[0;33m${EXTENSION}\e[0m..."
    call_gnome_extensions "${EXTENSION}"
}

function install_vscode_package() {
    local EXTENSION="${*}"

    is_vscode_extension_installed "${EXTENSION}" && return

    echo -e " >>> Installing VS Code extension: \e[0;33m${EXTENSION}\e[0m..."
    call_vscode --install-extension "${EXTENSION}"
}

function install_webapp() {
    local URL="${1}"

    local DOMAIN
    DOMAIN=$(echo "${URL}" | sed -E 's|https?://([^/]+)/?.*|\1|')

    local BASE_DOMAIN
    BASE_DOMAIN=$(echo "${DOMAIN}" | sed -E 's/\.[^.]+$//')

    local PACKAGE_ID
    PACKAGE_ID=$(echo "${BASE_DOMAIN}" | sed 's/^app\.//' | awk -F'.' '{for(i=NF;i>=1;i--) printf "%s%s",$i,(i>1?"-":"")}')

    local PACKAGE_NAME
    PACKAGE_NAME="${PACKAGE_ID}-webapp"

    local DISPLAY_NAME
    DISPLAY_NAME=$(echo "${BASE_DOMAIN}" | sed 's/^app\.//g' | \
        awk -F'.' '{
            for(i=NF;i>=1;i--) {
                word=$i
                printf "%s%s", toupper(substr(word,1,1)) substr(word,2), (i>1?" ":"")
            }
        }')

    local WM_CLASS
    WM_CLASS="chrome-${DOMAIN}__-Default"

    is_webapp_installed "${PACKAGE_NAME}" && return

    local BROWSER=''
    if does_bin_exist 'chromium'; then
        BROWSER='chromium'
    elif does_bin_exist 'org.chromium.Chromium'; then
        BROWSER='org.chromium.Chromium'
    elif does_bin_exist 'brave'; then
        BROWSER='brave'
    elif does_bin_exist 'brave-browser'; then
        BROWSER='brave-browser'
    else
        echo ' !!! No supported browser found'
        return 1
    fi

    local DESKTOP_FILE="${XDG_DATA_HOME}/applications/${PACKAGE_NAME}.desktop"

    echo -e " >>> Installing webapp: \e[0;33m${PACKAGE_NAME}\e[0m..."

    local EXEC_COMMAND
    EXEC_COMMAND="env GTK_THEME=$(get_theme):$(get_theme_mode) ${BROWSER}"

    if [ "$(get_theme_mode)" = 'dark' ]; then
        EXEC_COMMAND="${EXEC_COMMAND} --force-dark-mode"
    fi

    if [ -n "${APPS_LOCALE}" ]; then
        EXEC_COMMAND="${EXEC_COMMAND} --lang=${APPS_LOCALE}"
    elif [ -n "${OS_LOCALE}" ]; then
        EXEC_COMMAND="${EXEC_COMMAND} --lang=${OS_LOCALE}"
    else
        EXEC_COMMAND="${EXEC_COMMAND} --lang=en_GB"
    fi

    EXEC_COMMAND="${EXEC_COMMAND} --app=\"${URL}\" --class=\"${PACKAGE_ID}\" --name=\"${DISPLAY_NAME}\" --user-data-dir=\"${XDG_CONFIG_HOME}/${BROWSER}-${PACKAGE_NAME}\""
    EXEC_COMMAND="${EXEC_COMMAND} --no-first-run --no-default-browser-check --disable-features=Translate,TranslateUI --disable-notifications"
    EXEC_COMMAND="${EXEC_COMMAND} --disable-sync --disable-background-networking --disable-component-update"
    EXEC_COMMAND="${EXEC_COMMAND} --app-auto-launched"

    create_file "${DESKTOP_FILE}"
    cat > "${DESKTOP_FILE}" << EOF
[Desktop Entry]
Type=Application
Name=${DISPLAY_NAME}
Comment=Standalone web application for ${URL}
Exec=${EXEC_COMMAND}
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
StartupWMClass=${WM_CLASS}
EOF

    chmod +x "${DESKTOP_FILE}"

    if does_bin_exist 'update-desktop-database'; then
        update-desktop-database "${XDG_DATA_HOME}/applications" >/dev/null 2>&1
    fi
}

function uninstall_package() {
    local PACKAGE="${1}"

    if [ "${OS}" = 'Android' ]; then
        uninstall_android_package "${PACKAGE}"
    elif [ "${OS}" = 'Linux' ]; then
        uninstall_native_package "${PACKAGE}"
        uninstall_flatpak "${PACKAGE}"
        uninstall_github_package "${PACKAGE}"
        uninstall_webapp "${PACKAGE}"
    fi
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
          || [ "${DISTRO_FAMILY}" = 'Debian' ] \
          || [ "${DISTRO_FAMILY}" = 'Ubuntu' ]; then
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

function uninstall_github_package() {
    local PACKAGE_NAME="${1}"
    local PACKAGE_METADATA_DIR="${LINUX_SETUP_SCRIPT_PACKAGES_DIR}/${PACKAGE_NAME}"

    is_github_package_installed "${PACKAGE_NAME}" || return

    echo -e " >>> Uninstalling GitHub package: \e[0;33m${PACKAGE_NAME}\e[0m..."

    run_as_su apt remove -y "${PACKAGE_NAME}" 2>/dev/null

    remove "${PACKAGE_METADATA_DIR}"
}

function uninstall_gnome_shell_extension() {
    local INPUT="${1}"
    local EXTENSION_NAME="${INPUT#*/}"

    ! is_gnome_shell_extension_installed "${INPUT}" && return

    echo -e " >>> Uninstalling GNOME Shell extension: \e[0;33m${EXTENSION_NAME}\e[0m..."

    local UUID=$(gnome-extensions list | grep "^${EXTENSION_NAME}@" | head -n 1)

    if [ -n "${UUID}" ]; then
        gnome-extensions disable "${UUID}" 2>/dev/null
        gnome-extensions uninstall "${UUID}"
    fi
}

function update_github_package() {
    local PACKAGE_NAME="${1}"
    local REPOSITORY="${2}"

    local PACKAGE_METADATA_DIR="${LINUX_SETUP_SCRIPT_PACKAGES_DIR}/${PACKAGE_NAME}"

    if ! is_github_package_installed "${PACKAGE_NAME}"; then
        echo " !!! GitHub package not installed: ${PACKAGE_NAME}"
        return 1
    fi

    local CURRENT_VERSION
    CURRENT_VERSION=$(run_as_su cat "${PACKAGE_METADATA_DIR}/version")

    local RELEASE_JSON
    RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPOSITORY}/releases/latest")

    local LATEST_VERSION
    LATEST_VERSION=$(echo "${RELEASE_JSON}" | jq -r '.tag_name')

    if [ -z "${LATEST_VERSION}" ] || [ "${LATEST_VERSION}" = "null" ]; then
        echo " !!! Failed to fetch latest version for ${REPOSITORY}"
        return 1
    fi

    if [ "${CURRENT_VERSION}" = "${LATEST_VERSION}" ]; then
        return 0
    fi

    echo -e " >>> Updating GitHub package: \e[0;33m${PACKAGE_NAME}\e[0m (${CURRENT_VERSION} -> ${LATEST_VERSION})..."

    install_github_package "${PACKAGE_NAME}" "${REPOSITORY}"
}

function uninstall_webapp() {
    local PACKAGE_NAME="${1}"
    local DESKTOP_FILE="${XDG_DATA_HOME}/applications/${PACKAGE_NAME}.desktop"

    [ -f "${DESKTOP_FILE}" ] || return

    echo -e " >>> Uninstalling webapp: \e[0;33m${PACKAGE_NAME}\e[0m..."

    remove "${DESKTOP_FILE}"

    if does_bin_exist 'update-desktop-database'; then
        update-desktop-database "${XDG_DATA_HOME}/applications" >/dev/null 2>&1
    fi

    local WEBAPP_PROFILE_DIR
    WEBAPP_PROFILE_DIR="${XDG_CONFIG_HOME}/${BROWSER}-${PACKAGE_NAME}"

    [ -d "${WEBAPP_PROFILE_DIR}" ] && remove "${WEBAPP_PROFILE_DIR}"
}
