#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/config.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"
source "${REPO_SCRIPTS_DIR}/common/permissions.sh"
source "${REPO_SCRIPTS_DIR}/common/system-info.sh"

if does_bin_exist 'flatpak'; then
    for AUDIO_PLAYER_APP in 'io.bassi.Amberol' 'org.gnome.Rhythmbox3'; do
        set_linux_permission "${AUDIO_PLAYER_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' true \
            'notification_lockscreen' true \
            'location' false
    done
    for BROWSER_APP in 'com.brave.browser' 'io.gitlab.librewolf-community' 'org.chromium.Chromium' 'org.mozilla.firefox' 'chromium' 'firefox-esr'; do
        set_linux_permission "${BROWSER_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' true
    done
    for CALCULATOR_APP in 'org.gnome.Calculator' 'mate-calc'; do
        set_linux_permission "${CALCULATOR_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for CAMERA_APP in 'org.gnome.Cheese' 'org.gnome.Snapshot'; do
        set_linux_permission "${CAMERA_APP}" \
            'background' false \
            'camera' true \
            'network' false \
            'notification' false \
            'location' true
    done
    for CHAT_APP in 'app.drey.PaperPlane' 'com.discordapp.Discord' 'de.schmidhuberj.Flare' 'io.github.mimbrero.WhatsAppDesktop' 'org.signal.Signal' 'org.telegram.desktop'; do
        set_linux_permission "${CHAT_APP}" \
            'background' true \
            'camera' true \
            'network' true \
            'notification' true \
            'notification_lockscreen' true \
            'location' false
    done
    for DOCUMENT_VIEWER in 'epdfview' 'org.gnome.Evince'; do
        set_linux_permission "${DOCUMENT_VIEWER_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for IDE_APP in 'com.visualstudio.code' 'visual-studio-code'; do
        set_linux_permission "${IDE_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for IMAGE_EDITOR_APP in 'org.gimp.GIMP' 'org.upscayl.Upscayl'; do
        set_linux_permission "${IMAGE_EDITOR_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for IMAGE_VIEWER_APP in 'org.gnome.eog' 'org.gnome.Loupe'; do
        set_linux_permission "${IMAGE_VIEWER_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for MINECRAFT_APP in 'com.mojang.Minecraft' 'org.prismlauncher.PrismLauncher'; do
        set_linux_permission "${MINECRAFT_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for OFFICE_SUITE_APP in 'org.libreoffice.LibreOffice' 'org.onlyoffice.desktopeditors'; do
        set_linux_permission "${OFFICE_SUITE_APP}"  \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for SPOTIFY_APP in 'dev.alextren.Spot' 'com.spotify.Client'; do
        set_linux_permission "${SPOTIFY_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' true \
            'notification_lockscreen' true \
            'location' false
    done
    for STEAM_APP in 'com.valvesoftware.Steam' 'steam'; do
        set_linux_permission "${STEAM_APP}" \
            'background' true \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for SYSTEM_MONITOR_APP in 'net.nokyan.Resources'; do
        set_linux_permission "${SYSTEM_MONITOR_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for TODO_APP in 'io.github.alainm23.planify' 'org.gnome.Todo'; do
        set_linux_permission "${TODO_APP}" \
            'background' true \
            'camera' false \
            'network' true \
            'notification' true \
            'location' false
    done
    for TERMINAL_APP in 'org.gnome.Console' 'org.gnome.Terminal'; do
        set_linux_permission "${TERMINAL_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for TEXT_EDITOR_APP in 'org.gnome.gedit' 'org.gnome.TextEditor'; do
        set_linux_permission "${TEXT_EDITOR_APP}" \
            'background' false \
            'camera' false \
            'network' false \
            'notification' false \
            'location' false
    done
    for TEAMS_APP in 'com.github.IsmaelMartinez.teams_for_linux' 'com.microsoft.teams'; do
        set_linux_permission "${TEAMS_APP}" \
            'background' false \
            'camera' true \
            'network' true \
            'notification' true \
            'notification_lockscreen' true \
            'location' false
    done
    for TORRENT_DOWNLOADER_APP in 'de.haeckerfelix.Fragments' 'com.transmissionbt.Transmission'; do
        set_linux_permission "${TORRENT_DOWNLOADER_APP}" \
            'background' true \
            'camera' false \
            'network' true \
            'notification' true \
            'notification_lockscreen' false \
            'location' false
    fi
    for VIDEO_PLAYER_APP in 'com.github.rafostar.Clapper' 'org.gnome.Totem'; do
        set_linux_permission "${VIDEO_PLAYER_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done
    for VIDEO_STRAMING_APP in 'tv.plex.PlexDesktop' 'tv.plex.PlexHTPC'; do 
        set_linux_permission "${VIDEO_STREAMING_APP}" \
            'background' false \
            'camera' false \
            'network' true \
            'notification' false \
            'location' false
    done

    set_linux_permission 'ca.desrt.dconf-editor' \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission 'com.getpostman.Postman' \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' false
    set_linux_permission "com.github.tchx84.Flatseal" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission "com.simplenote.Simplenote" \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' false
    set_linux_permission "com.github.vladimiry.ElectronMail" \
        'background' true \
        'camera' false \
        'network' true \
        'notification' true \
        'notification_lockscreen' true \
        'location' false
    set_linux_permission "com.obsproject.Studio" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission "fr.romainvigier.MetadataCleaner" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission "io.github.hmlendea.geforcenow-electron" \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' false
    set_linux_permission "net.lutris.Lutris" \
        'background' false \
        'camera' false \
        'network' true \
        'notification' true \
        'notification_lockscreen' true \
        'location' false
    set_linux_permission "nl.hjdskes.gcolor3" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission "org.gnome.baobab" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' true \
        'notification_lockscreen' false \
        'location' false
    set_linux_permission "org.gnome.Calendar" \
        'background' false \
        'camera' false \
        'network' true \
        'notification' true \
        'notification_lockscreen' true \
        'location' true
    set_linux_permission "org.gnome.clocks" \
        'background' true \
        'camera' false \
        'network' false \
        'notification' true \
        'notification_lockscreen' true \
        'location' false
    set_linux_permission "org.gnome.Contacts" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission "org.gnome.FileRoller" \
        'background' true \
        'camera' false \
        'network' false \
        'notification' true \
        'notification_lockscreen' false \
        'location' false
    set_linux_permission "org.gnome.font-viewer" \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission 'org.gnome.Maps' \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' true
    set_linux_permission 'org.gnome.NetworkDisplays' \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' false
    set_linux_permission 'org.gnome.seahorse.Application' \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission 'org.gnome.Settings' \
        'camera' false \
        'notification' false
    set_linux_permission 'org.gnome.Weather' \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' true
    set_linux_permission 'org.inkscape.Inkscape' \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
    set_linux_permission 'ro.go.hmlendea.DL-Desktop' \
        'background' false \
        'camera' false \
        'network' true \
        'notification' false \
        'location' false
    set_linux_permission 'ro.go.hmlendea.Sokogrump' \
        'background' false \
        'camera' false \
        'network' false \
        'notification' false \
        'location' false
fi

if [ "${DISTRO_FAMILY}" = 'Android' ] \
&& ${HAS_SU_PRIVILEGES}; then
    set_android_permission 'ch.protonmail.android' \
        'accounts_get' false \
        'contacts_read' true \
        'storage' true
    set_android_permission 'com.aurora.store' 'storage' true
    set_android_permission 'com.beemdevelopment.aegis' 'camera' true
    set_android_permission 'com.bumble.app' \
        'accounts_get' false \
        'camera' false \
        'contacts' false \
        'location' true \
        'microphone' false \
        'phone' false \
        'storage' false
    set_android_permission "com.best.deskclock" "org.codeaurora.permission.POWER_OFF_ALARM" true
    set_android_permission "com.duolingo" \
        'accounts_get' false \
        'camera' false \
        'contacts' false \
        'microphone' true \
        'storage' false
    set_android_permission "com.spotify.music" \
        'accounts_get' false \
        'camera' false \
        'contacts' false \
        'microphone' false \
        'storage' false
    set_android_permission "com.revolut.revolut" \
        'accounts_get' false \
        'camera' false \
        'contacts' true \
        'location' false \
        'microphone' false \
        'phone' false \
        'storage' false
    set_android_permission "com.google.android.apps.photos" \
        'accounts_get' true \
        'contacts' false \
        'location' false \
        'microphone' false \
        'phone' false \
        'storage' true \
        'storage_media' true
    set_android_permission "com.odysee.app" 'storage' false
    set_android_permission "com.secuso.privacyFriendlyCodeScanner" 'camera' true
    set_android_permission "com.vanced.android.youtube" \
        'accounts_get' false \
        'camera' false \
        'contacts' false \
        'location' false \
        'microphone' false \
        'phone' false \
        'storage' false
    set_android_permission "com.whatsapp" \
        'accounts_get' false \
        'location' false \
        'camera' true \
        'contacts' true \
        'microphone' false \
        'phone_log' false \
        'phone' false \
        'sms' false \
        'storage' true
    set_android_permission "com.x8bit.bitwarden" \
        'camera' false \
        'storage' false
    set_android_permission "de.stocard.stocard" \
        'camera' false \
        'location' false \
        'location_background' false \
        'storage' false
    set_android_permission "foundation.e.apps" 'storage' true
    set_android_permission "foundation.e.calendar" \
        'calendar' true \
        'contacts_read' true \
        'storage' true
    set_android_permission "io.homeassistant.companion.android.minimal" \
        'camera' false \
        'location' false \
        'location_background' false \
        'microphone' false \
        'phone' false \
        'physical_activity' false \
        'storage' false
    set_android_permission "me.austinhuang.instagrabber" \
        'camera' false \
        'microphone' false \
        'storage' false
    set_android_permission "net.osmand" \
        'camera' false \
        'location' true \
        'microphone' false \
        'storage' false
    set_android_permission "org.codeaurora.snapcam" \
        'camera' true \
        'location' true \
        'microphone' true \
        'storage' true
    for APP in "io.gitlab.librewolf-community" "org.mozilla.fenix" "org.mozilla.firefox"; do
        set_android_permission "${APP}" \
            'camera' false \
            'location' false \
            'microphone' false \
            'storage' false
    done
    set_android_permission "org.thoughtcrime.securesms" \
        'accounts_get' false \
        'location' false \
        'calendar' false \
        'camera' true \
        'contacts' true \
        'microphone' true \
        'phone' false \
        'sms' true \
        'storage_read' true
    set_android_permission "wangdaye.com.geometricweather" \
        'location' true \
        'location_background' true \
        'phone' false \
        'storage' false
    set_android_permission "ro.profi.store" \
        'location' false \
        'camera' false
fi
