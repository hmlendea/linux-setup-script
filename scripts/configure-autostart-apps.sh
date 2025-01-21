#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/system-info.sh"

[ "${OS}" != 'Linux' ] && exit
(! ${HAS_GUI}) && exit

AUTOSTART_DIR="${XDG_CONFIG_HOME}/autostart"

function get_launcher_path_for_app() {
    local BINARY_NAME="${1}"
    local LAUNCHER_LABEL=$(basename "${BINARY_NAME}")

    echo "${AUTOSTART_DIR}/${LAUNCHER_LABEL}.desktop"
}

function configure_autostart_for_app() {
    local BINARY_NAME="${1}" && shift

    ! does_bin_exist "${BINARY_NAME}" && return

    local LAUNCHER_PATH=$(get_launcher_path_for_app "${BINARY_NAME}")
    [ ! -f "${LAUNCHER_PATH}" ] && create_launcher "${LAUNCHER_PATH}"
    set_launcher_entries "${LAUNCHER_PATH}" "$@"
}

# Discord
AUTOSTART_DISCORD=false
if ${AUTOSTART_DISCORD}; then
    configure_autostart_for_app 'discord' \
        Exec '/usr/bin/discord --start-minimized' \
        Icon 'discord'
    configure_autostart_for_app 'com.discordapp.Discord' \
        Name 'Discord' \
        Icon 'discord' \
        Exec 'com.discordapp.Discord --start-minimized'
else
    for DISCORD_BINARY in 'com.discordapp.Discord' 'discord'; do
        DISCORD_LAUNCHER_PATH=$(get_launcher_path_for_app "${DISCORD_BINARY}")
        remove "${DISCORD_LAUNCHER_PATH}"
    done
fi

# ElectronMail
configure_autostart_for_app "/opt/ElectronMail/electron-mail" \
    Name 'Mail' \
    Icon 'electron-mail' \
    Exec "/opt/ElectronMail/electron-mail --js-flags=\"--max-old-space-size=6144\" %U"
configure_autostart_for_app "com.github.vladimiry.ElectronMail" \
    Name 'Mail' \
    Icon 'electron-mail' \
    Exec "com.github.vladimiry.ElectronMail --js-flags=--max-old-space-size=12288 %U"

# Planify
configure_autostart_for_app "io.github.alainm23.planify" \
    Name 'Reminders' \
    Name[ro] 'Mementouri' \
    Icon 'gnome-todo' \
    Exec 'io.github.alainm23.planify --background'

# Plank
configure_autostart_for_app 'plank' \
    Icon 'plank' \
    Exec 'plank'

# Signal
configure_autostart_for_app 'signal-desktop' \
    Name "Signal" \
    Exec "signal-desktop --start-in-tray --no-sandbox -- %u"
configure_autostart_for_app 'org.signal.Signal' \
    Name "Signal" \
    Icon "signal" \
    Exec "org.signal.Signal --start-in-tray --no-sandbox -- %u"
configure_autostart_for_app 'de.schmidhuberj.Flare' \
    Name "Signal" \
    Icon "signal" \
    Exec "de.schmidhuberj.Flare"

# Telegram
configure_autostart_for_app "telegram-desktop" \
    Name "Telegram" \
    Icon "telegram" \
    Exec "/usr/bin/telegram-desktop -workdir ${XDG_DATA_HOME}/TelegramDesktop/ -startintray -autostart"
configure_autostart_for_app "org.telegram.desktop" \
    Name "Telegram" \
    Icon "telegram" \
    Exec "org.telegram.desktop -workdir ${HOME_VAR_APP}/org.telegram.desktop/data/TelegramDesktop/ -startintray -autostart"
configure_autostart_for_app "app.drey.PaperPlane.desktop" \
    Name "Telegram" \
    Icon "telegram" \
    Exec "app.drey.PaperPlane"

# WhatsApp
configure_autostart_for_app "io.github.mimbrero.WhatsAppDesktop" \
    Name "WhatsApp" \
    Icon "whatsapp" \
    Exec "io.github.mimbrero.WhatsAppDesktop --start-hidden"
configure_autostart_for_app "whatsapp-nativefier" \
    Name "WhatsApp" \
    Icon "whatsapp" \
    Exec "whatsapp-nativefier"
