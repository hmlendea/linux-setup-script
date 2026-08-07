#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"

function update_mimetype_association() {
    local MIMETYPE="${1}"
    local LAUNCHER="${2}"

    [ -z "${LAUNCHER}" ] && return

    local MIMEAPPS_FILE="${XDG_CONFIG_HOME}/mimeapps.list"

    grep -q "^${MIMETYPE}=${LAUNCHER}$" "${MIMEAPPS_FILE}" && return

    echo -e "Associating the \e[0;33m${MIMETYPE}\e[0m mimetype with \e[0;33m${LAUNCHER}\e[0m..."
    local MIMETYPE_ESC=$(echo "${MIMETYPE}" | sed \
                            -e 's/\//\\\//g')
    sed -i '/^'"${MIMETYPE_ESC}"'=/d' "${MIMEAPPS_FILE}"
    echo "${MIMETYPE}=${LAUNCHER}" >> "${MIMEAPPS_FILE}"
}

function get_first_available_launcher() {
    while [ "${#}" -gt 1; do
        local BINARY_NAME="${1}"
        local LAUNCHER_NAME="${2}"
        shift 2

        if does_bin_exist "${BINARY_NAME}"; then
            echo "${LAUNCHER_NAME}"
            return
        fi
    done
}

# Browser
BROWSER_LAUNCHER="$(get_first_available_launcher \
    'io.gitlab.librewolf-community' 'io.gitlab.librewolf-community.desktop' \
    'org.mozilla.firefox' 'org.mozilla.firefox.desktop' \
    'firefox-esr' 'firefox-esr.desktop' \
    'firefox' 'firefox.desktop' \
    'com.brave.Browser' 'com.brave.Browser.desktop')"

# Disk Image Mounter
DISK_IMAGE_MOUNTER_LAUNCHER=''
if does_bin_exist 'gnome-disk-image-mounter'; then
    DISK_IMAGE_MOUNTER_LAUNCHER='gnome-disk-image-mounter.desktop'
fi

# Document Viewer
DOCUMENT_VIEWER_LAUNCHER="$(get_first_available_launcher \
    'org.gnome.Papers' 'org.gnome.Papers.desktop' \
    'org.gnome.Evince' 'org.gnome.Evince.desktop' \
    'evince' 'evince.desktop')"

# Email Client
EMAIL_CLIENT_LAUNCHER="$(get_first_available_launcher \
    'com.github.vladimiry.ElectronMail' 'com.github.vladimiry.ElectronMail.desktop' \
    'electronmail-bin' 'electronmail-bin.desktop')"

# Facebook Messenger
FBMESSENGER_LAUNCHER=''
if does_bin_exist 'com.sindresorhus.Caprine'; then
    FBMESSENGER_LAUNCHER='com.sindresorhus.Caprine.desktop'
fi

# File Manager
FILE_MANAGER_LAUNCHER=''
if does_bin_exist 'nautilus'; then
    FILE_MANAGER_LAUNCHER='org.gnome.Nautilus.desktop'
fi

# GIMP
GIMP_LAUNCHER="$(get_first_available_launcher \
    'org.gimp.GIMP' 'org.gimp.GIMP.desktop' \
    'gimp' 'gimp.desktop')"

# Image viewers
IMAGE_VIEWER_LAUNCHER="$(get_first_available_launcher \
    'org.gnome.Loupe' 'org.gnome.Loupe.desktop' \
    'org.gnome.eog' 'org.gnome.eog.desktop' \
    'gpicview' 'gpicview.desktop')"

# Notes
NOTES_LAUNCHER=''
if does_bin_exist 'com.simplenote.Simplenote'; then
    NOTES_LAUNCHER='com.simplenote.Simplenote.desktop'
elif does_bin_exist 'simplenote'; then
    NOTES_LAUNCHER='simplenote.desktop'
elif is_webapp_installed 'simplenote-webapp'; then
    NOTES_LAUNCHER='simplenote-webapp.desktop'
fi

# Password Manager
PASSWORD_MANAGER_LAUNCHER=''
if does_bin_exist 'com.bitwarden.desktop'; then
    PASSWORD_MANAGER_LAUNCHER='com.bitwarden.desktop.desktop'
fi

# Signal
SIGNAL_LAUNCHER="$(get_first_available_launcher \
    'org.signal.Signal' 'org.signal.Signal.desktop' \
    'de.schmidhuberj.Flare' 'de.schmidhuberj.Flare.desktop' \
    'signal-desktop' 'signal-desktop.desktop')"

# Steam
STEAM_LAUNCHER="$(get_first_available_launcher \
    'com.valvesoftware.Steam' 'com.valvesoftware.Steam.desktop' \
    'steam' 'steam.desktop')"

# Tasks
TASKS_LAUNCHER="$(get_first_available_launcher \
    'io.github.alainm23.planify' 'io.github.alainm23.planify.desktop' \
    'org.gnome.Todo' 'org.gnome.Todo.desktop')"

# Teams
TEAMS_LAUNCHER="$(get_first_available_launcher \
    'com.microsoft.Teams' 'com.microsoft.Teams.desktop' \
    'com.github.IsmaelMartinez.teams_for_linux' 'com.github.IsmaelMartinez.teams_for_linux.desktop')"

# Telegram
TELEGRAM_LAUNCHER="$(get_first_available_launcher \
    'app.drey.PaperPlane' 'app.drey.PaperPlane.desktop' \
    'org.telegram.desktop' 'org.telegram.desktop.desktop' \
    'telegram-desktop' 'telegramdesktop.desktop')"

# Terminal
TERMINAL_LAUNCHER="$(get_first_available_launcher \
    'kgx' 'org.gnome.Console.desktop' \
    'gnome-terminal' 'org.gnome.Terminal.desktop' \
    'lxterminal' 'lxterminal.desktop')"

# Text Editor
TEXT_EDITOR_LAUNCHER="$(get_first_available_launcher \
    'org.gnome.gedit' 'org.gnome.gedit.desktop' \
    'org.gnome.TextEditor' 'org.gnome.TextEditor.desktop' \
    'gedit' 'gedit.desktop' \
    'pluma' 'pluma.desktop')"

# WhatsApp
WHATSAPP_LAUNCHER="$(get_first_available_launcher \
    'io.github.mimbrero.WhatsAppDesktop' 'io.github.mimbrero.WhatsAppDesktop.desktop' \
    'wasistlos' 'com.github.xeco23.WasIstLos.desktop' \
    'whatsapp-nativefier' 'whatsapp-nativefier.desktop')"

# Update the favourites

FAVOURITE_APPS=''

[ -n "${BROWSER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${BROWSER_LAUNCHER}'"
[ -n "${TERMINAL_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TERMINAL_LAUNCHER}'"
[ -n "${PASSWORD_MANAGER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${PASSWORD_MANAGER_LAUNCHER}'"
[ -n "${FILE_MANAGER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${FILE_MANAGER_LAUNCHER}'"
#[ -n "${STEAM_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${STEAM_LAUNCHER}'"
[ -n "${SIGNAL_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${SIGNAL_LAUNCHER}'"
[ -n "${TELEGRAM_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TELEGRAM_LAUNCHER}'"
[ -n "${WHATSAPP_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${WHATSAPP_LAUNCHER}'"
[ -n "${FBMESSENGER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${FBMESSENGER_LAUNCHER}'"
[ -n "${EMAIL_CLIENT_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${EMAIL_CLIENT_LAUNCHER}'"
[ -n "${NOTES_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${NOTES_LAUNCHER}'"
[ -n "${TASKS_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TASKS_LAUNCHER}'"

FAVOURITE_APPS=$(echo "${FAVOURITE_APPS}" | sed 's/^\s*,*\s*//g')

if [ -n "${FAVOURITE_APPS}" ]; then
    set_gsetting 'org.gnome.shell' 'favorite-apps' "[${FAVOURITE_APPS}]"
else
    set_gsetting 'org.gnome.shell' 'favorite-apps' '@as []'
fi

# Update the associations

for DOCUMENT_TYPE in 'pdf'; do
    update_mimetype_association "application/${DOCUMENT_TYPE}" "${DOCUMENT_VIEWER_LAUNCHER}"
done

for IMAGE_TYPE in 'bmp' 'jpeg' 'png' 'webp'; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${IMAGE_VIEWER_LAUNCHER}"
done

for IMAGE_TYPE in 'x-dds'; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${GIMP_LAUNCHER}"
done

update_mimetype_association 'x-scheme-handler/msteams' "${TEAMS_LAUNCHER}"

does_bin_exist 'icaclient' && update_mimetype_association 'application/x-extension-ica' 'citrix-wfica.desktop'

if [ -n "${BROWSER_LAUNCHER}" ]; then
    for SCHEME_TYPE in 'http' 'https' 'chrome'; do
        update_mimetype_association "x-scheme-handler/${SCHEME_TYPE}" "${BROWSER_LAUNCHER}"
    done
    for EXTENSION_TYPE in 'htm' 'html' 'shtml' 'xht' 'xhtml'; do
        update_mimetype_association "application/x-extension-${EXTENSION_TYPE}" "${BROWSER_LAUNCHER}"
    done

    update_mimetype_association 'application/xhtml+xml' "${BROWSER_LAUNCHER}"
    update_mimetype_association 'text/html' "${BROWSER_LAUNCHER}"
fi

if [ -n "${FILE_MANAGER_LAUNCHER}" ]; then
    update_mimetype_association 'x-scheme-handler/file' "${FILE_MANAGER_LAUNCHER}"
fi

if [ -n "${STEAM_LAUNCHER}" ]; then
    update_mimetype_association 'x-scheme-handler/steam' "${STEAM_LAUNCHER}"
fi

if [ -n "${TEXT_EDITOR_LAUNCHER}" ]; then
    for APPLICATION_TYPE in 'json' 'x-wine-extension-ini'; do
        update_mimetype_association "application/${APPLICATION_TYPE}" "${TEXT_EDITOR_LAUNCHER}"
    done

    update_mimetype_association 'application/xml' "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association 'audio/x-mod' "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association 'text/x-python' "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association 'text/plain' "${TEXT_EDITOR_LAUNCHER}"
fi

update_mimetype_association 'application/vnd.efi.iso' "${DISK_IMAGE_MOUNTER_LAUNCHER}"
