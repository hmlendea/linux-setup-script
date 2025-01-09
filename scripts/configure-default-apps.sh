#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"

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

# Browser
BROWSER_LAUNCHER=''
if does_bin_exist 'io.gitlab.librewolf-community'; then
    BROWSER_LAUNCHER='io.gitlab.librewolf-community.desktop'
elif does_bin_exist 'org.mozilla.firefox'; then
    BROWSER_LAUNCHER='org.mozilla.firefox.desktop'
elif does_bin_exist 'firefox-esr'; then
    BROWSER_LAUNCHER='firefox-esr.desktop'
elif does_bin_exist 'firefox'; then
    BROWSER_LAUNCHER='firefox.desktop'
fi

# Disk Image Mounter
DISK_IMAGE_MOUNTER_LAUNCHER=''
if does_bin_exist 'gnome-disk-image-mounter'; then
    DISK_IMAGE_MOUNTER_LAUNCHER='gnome-disk-image-mounter.desktop'
fi

# Document Viewer
DOCUMENT_VIEWER_LAUNCHER=''
if does_bin_exist 'org.gnome.Papers'; then
    DOCUMENT_VIEWER_LAUNCHER='org.gnome.Papers.desktop'
elif does_bin_exist 'org.gnome.Evince'; then
    DOCUMENT_VIEWER_LAUNCHER='org.gnome.Evince.desktop'
elif does_bin_exist 'evince'; then
    DOCUMENT_VIEWER_LAUNCHER='evince.desktop'
fi

# Email Client
EMAIL_CLIENT_LAUNCHER=''
if does_bin_exist 'com.github.vladimiry.ElectronMail'; then
    EMAIL_CLIENT_LAUNCHER='com.github.vladimiry.ElectronMail.desktop'
elif does_bin_exist 'electronmail-bin'; then
    EMAIL_CLIENT_LAUNCHER='electronmail-bin.desktop'
fi

# File Manager
FILE_MANAGER_LAUNCHER=''
if does_bin_exist 'nautilus'; then
    FILE_MANAGER_LAUNCHER="org.gnome.Nautilus.desktop"
fi

# GIMP
GIMP_LAUNCHER=''
if does_bin_exist 'org.gimp.GIMP'; then
    GIMP_LAUNCHER='org.gimp.GIMP.desktop'
elif does_bin_exist 'gimp'; then
    GIMP_LAUNCHER='gimp.desktop'
fi

# Image viewers
IMAGE_VIEWER_LAUNCHER=''
if does_bin_exist 'org.gnome.Loupe'; then
    IMAGE_VIEWER_LAUNCHER='org.gnome.Loupe.desktop'
elif does_bin_exist 'org.gnome.eog'; then
    IMAGE_VIEWER_LAUNCHER='org.gnome.eog.desktop'
elif does_bin_exist 'gpicview'; then
    IMAGE_VIEWER_LAUNCHER='gpicview.desktop'
fi

# Notes
NOTES_LAUNCHER=''
if does_bin_exist 'com.simplenote.Simplenote'; then
    NOTES_LAUNCHER='com.simplenote.Simplenote.desktop'
elif does_bin_exist 'simplenote'; then
    NOTES_LAUNCHER='simplenote.desktop'
fi

# Signal
SIGNAL_LAUNCHER=''
if does_bin_exist 'org.signal.Signal'; then
    SIGNAL_LAUNCHER='org.signal.Signal.desktop'
elif does_bin_exist 'signal-desktop'; then
    SIGNAL_LAUNCHER='signal-desktop.desktop'
fi

# Steam
STEAM_LAUNCHER=''
if does_bin_exist 'com.valvesoftware.Steam'; then
    STEAM_LAUNCHER='com.valvesoftware.Steam.desktop'
elif does_bin_exist 'steam'; then
    STEAM_LAUNCHER='steam.desktop'
fi

# Tasks
TASKS_LAUNCHER=''
if does_bin_exist 'io.github.alainm23.planify'; then
    TASKS_LAUNCHER='io.github.alainm23.planify.desktop'
elif does_bin_exist 'org.gnome.Todo'; then
    TASKS_LAUNCHER='org.gnome.Todo.desktop'
fi

# Teams
TEAMS_LAUNCHER=''
if does_bin_exist 'com.microsoft.Teams'; then
    TEAMS_LAUNCHER='com.microsoft.Teams.desktop'
elif does_bin_exist 'com.github.IsmaelMartinez.teams_for_linux'; then
    TEAMS_LAUNCHER='com.github.IsmaelMartinez.teams_for_linux.desktop'
fi

# Telegram
TELEGRAM_LAUNCHER=''
if does_bin_exist 'app.drey.PaperPlane'; then
    TELEGRAM_LAUNCHER='app.drey.PaperPlane.desktop'
elif does_bin_exist 'org.telegram.desktop'; then
    TELEGRAM_LAUNCHER='org.telegram.desktop.desktop'
elif does_bin_exist 'telegram-desktop'; then
    TELEGRAM_LAUNCHER='telegramdesktop.desktop'
fi

# Terminal
TERMINAL_LAUNCHER=''
if does_bin_exist 'gnome-terminal'; then
    TERMINAL_LAUNCHER='org.gnome.Terminal.desktop'
fi

# Text Editor
TEXT_EDITOR_LAUNCHER=''
if does_bin_exist 'org.gnome.gedit'; then
    TEXT_EDITOR_LAUNCHER='org.gnome.gedit.desktop'
elif does_bin_exist 'org.gnome.TextEditor'; then
    TEXT_EDITOR_LAUNCHER='org.gnome.TextEditor.desktop'
elif does_bin_exist 'gedit'; then
    TEXT_EDITOR_LAUNCHER='gedit.desktop'
elif does_bin_exist 'pluma'; then
    TEXT_EDITOR_LAUNCHER='pluma.desktop'
fi

# WhatsApp
WHATSAPP_LAUNCHER=''
if does_bin_exist 'whatsapp-nativefier'; then
    WHATSAPP_LAUNCHER='whatsapp-nativefier.desktop'
elif does_bin_exist 'io.github.mimbrero.WhatsAppDesktop'; then
    WHATSAPP_LAUNCHER='io.github.mimbrero.WhatsAppDesktop.desktop'
fi

# Update the favourites

FAVOURITE_APPS=''

[ -n "${BROWSER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${BROWSER_LAUNCHER}'"
[ -n "${TERMINAL_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TERMINAL_LAUNCHER}'"
[ -n "${FILE_MANAGER_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${FILE_MANAGER_LAUNCHER}'"
#[ -n "${STEAM_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${STEAM_LAUNCHER}'"
[ -n "${TERMINAL_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TERMINAL_LAUNCHER}'"
[ -n "${SIGNAL_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${SIGNAL_LAUNCHER}'"
[ -n "${TELEGRAM_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${TELEGRAM_LAUNCHER}'"
[ -n "${WHATSAPP_LAUNCHER}" ] && FAVOURITE_APPS="${FAVOURITE_APPS}, '${WHATSAPP_LAUNCHER}'"
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

for IMAGE_TYPE in "bmp" "jpeg" "png" "webp"; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${IMAGE_VIEWER_LAUNCHER}"
done

for IMAGE_TYPE in "x-dds"; do
    update_mimetype_association "image/${IMAGE_TYPE}" "${GIMP_LAUNCHER}"
done

update_mimetype_association 'x-scheme-handler/msteams' "${TEAMS_LAUNCHER}"

does_bin_exist "icaclient" && update_mimetype_association "application/x-extension-ica" "citrix-wfica.desktop"

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

    update_mimetype_association "application/xml" "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association "audio/x-mod" "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association "text/x-python" "${TEXT_EDITOR_LAUNCHER}"
    update_mimetype_association "text/plain" "${TEXT_EDITOR_LAUNCHER}"
fi

update_mimetype_association "application/vnd.efi.iso" "${DISK_IMAGE_MOUNTER_LAUNCHER}"
