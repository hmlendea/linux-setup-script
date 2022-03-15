#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"

[ "${OS}" != "Linux" ] && exit
(! ${HAS_GUI}) && exit

AUTOSTART_DIR="${HOME_CONFIG}/autostart"

function configure-autostart-for-app() {
    local BINARY_NAME="${1}" && shift
    local LAUNCHER_LABEL=$(basename "${BINARY_NAME}")
    local LAUNCHER_PATH="${AUTOSTART_DIR}/${LAUNCHER_LABEL}.desktop"

    if does-bin-exist "${BINARY_NAME}"; then
        [ ! -f "${LAUNCHER_PATH}" ] && create_launcher "${LAUNCHER_PATH}"

        set_launcher_entries "${LAUNCHER_PATH}" "$@"
    fi
}

# Discord
configure-autostart-for-app "discord" \
    Exec "/usr/bin/discord --start-minimized" \
    Icon "discord"

# ElectronMail
configure-autostart-for-app "/opt/ElectronMail/electron-mail" \
    Name "Mail" \
    Exec "/opt/ElectronMail/electron-mail --js-flags=\"--max-old-space-size=6144\" %U"
configure-autostart-for-app "com.github.vladimiry.ElectronMail" \
    Name "Mail" \
    Exec "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/electron-mail --file-forwarding com.github.vladimiry.ElectronMail --js-flags=--max-old-space-size=12288 %U"

# Plank
configure-autostart-for-app "plank" \
    Name "Plank" \
    Icon "plank" \
    Exec "plank"

# Signal
configure-autostart-for-app "signal-desktop" \
    Name "Signal" \
    Exec "signal-desktop --start-in-tray --no-sandbox -- %u"
configure-autostart-for-app "org.signal.Signal" \
    Name "Signal" \
    Exec "/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=signal-desktop --file-forwarding org.signal.Signal --start-in-tray --no-sandbox -- %u"

# Telegram
configure-autostart-for-app "telegram-desktop" \
    Name "Telegram" \
    Icon "telegram" \
    Exec "/usr/bin/telegram-desktop -workdir ${HOME_LOCAL_SHARE}/TelegramDesktop/ -startintray -autostart"
configure-autostart-for-app "org.telegram.desktop" \
    Name "Telegram" \
    Icon "telegram" \
    Exec "flatpak run --command=telegram-desktop org.telegram.desktop -workdir ${HOME_VAR}/app/org.telegram.desktop/data/TelegramDesktop/ -startintray -autostart"

# WhatsApp
configure-autostart-for-app "whatsapp-nativefier" \
    Name "WhatsApp" \
    Icon "whatsapp" \
    Exec "whatsapp-nativefier"
