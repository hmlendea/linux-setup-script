#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"

function update_mimetype_association() {
    local MIMETYPE="${1}"
    local LAUNCHER="${2}"

    local MIMEAPPS_FILE="${XDG_CONFIG_HOME}/mimeapps.list"

    grep -q "^${MIMETYPE}=${LAUNCHER}$" "${MIMEAPPS_FILE}" && return

    echo -e "Associating the \e[0;33m${MIMETYPE}\e[0m mimetype with \e[0;33m${LAUNCHER}\e[0m..."
    local MIMETYPE_ESC=$(echo "${MIMETYPE}" | sed \
                            -e 's/\//\\\//g')
    sed -i '/^'"${MIMETYPE_ESC}"'=/d' "${MIMEAPPS_FILE}"
    echo "${MIMETYPE}=${LAUNCHER}" >> "${MIMEAPPS_FILE}"
}

# Determine which apps to use
BROWSER_LAUNCHER=""
FILE_MANAGER_LAUNCHER=""
GIMP_LAUNCHER=""
IMAGE_VIEWER_LAUNCHER=""
STEAM_LAUNCHER=""
TEXT_EDITOR_LAUNCHER=""

is_flatpak_installed "org.mozilla.firefox" && BROWSER_LAUNCHER="org.mozilla.firefox.desktop"
is_native_package_installed "nautilus" && FILE_MANAGER_LAUNCHER="org.gnome.Nautilus.desktop"

# GIMP
if is_flatpak_installed "org.gimp.GIMP"; then
    GIMP_LAUNCHER="org.gimp.GIMP.desktop"
elif is_native_package_installed "gimp"; then
    GIMP_LAUNCHER="gimp.desktop"
fi

# Image viewers
if is_flatpak_installed "org.gnome.eog"; then
    IMAGE_VIEWER_LAUNCHER="org.gnome.eog.desktop"
elif is_native_package_installed "steam"; then
    IMAGE_VIEWER_LAUNCHER="steam.desktop"
fi

# Steam
if is_flatpak_installed "com.valvesoftware.Steam"; then
    STEAM_LAUNCHER="com.valvesoftware.Steam.desktop"
elif is_native_package_installed "steam"; then
    STEAM_LAUNCHER="steam.desktop"
fi

# Steam
if is_flatpak_installed "org.gnome.gedit"; then
    TEXT_EDITOR_LAUNCHER="org.gnome.gedit.desktop"
elif is_native_package_installed "gedit"; then
    TEXT_EDITOR_LAUNCHER="gedit.desktop"
fi

# Update the associations

for IMAGE_TYPE in "bmp" "jpeg" "png" "webp"; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${IMAGE_VIEWER_LAUNCHER}"
done

for IMAGE_TYPE in "x-dds"; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${GIMP_LAUNCHER}"
done

is_flatpak_installed "com.microsoft.Teams" && update_mimetype_association "x-scheme-handler/msteams" "com.microsoft.Teams.desktop"

is_native_package_installed "icaclient" && update_mimetype_association "application/x-extension-ica" "citrix-wfica.desktop"

if [ -n "${BROWSER_LAUNCHER}" ]; then
    for SCHEME_TYPE in "http" "https" "chrome"; do
        update_mimetype_association "x-scheme-handler/${SCHEME_TYPE}" "${BROWSER_LAUNCHER}"
    done
    for EXTENSION_TYPE in "htm" "html" "shtml" "xht" "xhtml"; do
        update_mimetype_association "application/x-extension-${EXTENSION_TYPE}" "${BROWSER_LAUNCHER}"
    done

    update_mimetype_association "application/xhtml+xml" "${BROWSER_LAUNCHER}"
    update_mimetype_association "text/html" "${BROWSER_LAUNCHER}"
fi

if [ -n "${FILE_MANAGER_LAUNCHER}" ]; then
    update_mimetype_association "x-scheme-handler/file" "${FILE_MANAGER_LAUNCHER}"
fi

if [ -n "${STEAM_LAUNCHER}" ]; then
    update_mimetype_association "x-scheme-handler/steam" "${STEAM_LAUNCHER}"
fi

if [ -n "${TEXT_EDITOR_LAUNCHER}" ]; then
    for APPLICATION_TYPE in "json" "x-wine-extension-ini"; do
        update_mimetype_association "application/${APPLICATION_TYPE}" "${TEXT_EDITOR_LAUNCHER}"
    done

    update_mimetype_association "audio/x-mod" "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association "text/plain" "${TEXT_EDITOR_LAUNCHER}"
fi
