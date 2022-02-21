#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"
source "scripts/common/system-info.sh"

function get_openbox_font_weight() {
    [[ "${*}" == "Bold" ]] && echo "Bold" || echo "Normal"
}

CHASSIS_TYPE="$(get_chassis_type)"
SCREEN_RESOLUTION_H=$(get_screen_width)
SCREEN_RESOLUTION_V=$(get_screen_height)
SCREEN_DPI=$(get_screen_dpi)
USING_NVIDIA_GPU=false; [ "$(get_gpu_family)" == "Nvidia" ] && USING_NVIDIA_GPU=true
IS_SERVER=false; [ -z "${SCREEN_RESOLUTION_H}" ] && IS_SERVER=true

DNS_CACHE_TTL=20 # Minutes
DNS_CACHE_SIZE=10000 # Entries

[ "${SCREEN_RESOLUTION_V}" -le 2160 ]   && ZOOM_LEVEL=1.15
[ "${SCREEN_RESOLUTION_V}" -le 1440 ]   && ZOOM_LEVEL=1.10
[ "${SCREEN_RESOLUTION_V}" -le 1080 ]   && ZOOM_LEVEL=1.00
[ "${SCREEN_RESOLUTION_V}" -eq 0 ]      && ZOOM_LEVEL=1.00

# Languages
OS_LANGUAGE=$(grep "^LANG=" "${ROOT_ETC}/locale.conf" | sed 's/^[^=]*=\([^.]*\).*/\1/g')
[ -z "${OS_LANGUAGE}" ] && OS_LANGUAGE="en_GB"
APPS_LANGUAGE="ro_RO"
GAMES_LANGUAGE="en_GB"

# THEMES
GTK_THEME="ZorinGrey-Dark"
GTK_THEME_VARIANT="dark"
GTK2_THEME="${GTK_THEME}"
GTK3_THEME="${GTK_THEME}"
GTK4_THEME="Adwaita-Dark" # Until the Zorin theme supports GTK4
ICON_THEME="Papirus-Dark"
ICON_THEME_FOLDER_COLOUR="grey"
CURSOR_THEME="Vimix-white-cursors"

if [[ "${GTK_THEME_VARIANT}" == "dark" ]]; then
    DESKTOP_THEME_IS_DARK=true
    DESKTOP_THEME_IS_DARK_BINARY=1
else
    DESKTOP_THEME_IS_DARK=false
    DESKTOP_THEME_IS_DARK_BINARY=0
fi

GTK_THEME_BG_COLOUR="#202020"

# FONT FACES
INTERFACE_FONT_NAME="Sans"
INTERFACE_FONT_STYLE="Regular"
INTERFACE_FONT_SIZE=11
[ "${SCREEN_DPI}" -ge 100 ] && INTERFACE_FONT_SIZE=10
[ "${SCREEN_DPI}" -ge 130 ] && INTERFACE_FONT_SIZE=12

DOCUMENT_FONT_NAME=${INTERFACE_FONT_NAME}
DOCUMENT_FONT_STYLE=${INTERFACE_FONT_STYLE}
DOCUMENT_FONT_SIZE=${INTERFACE_FONT_SIZE}

TITLEBAR_FONT_NAME=${INTERFACE_FONT_NAME}
TITLEBAR_FONT_STYLE="Bold"
TITLEBAR_FONT_SIZE=12
[ "${SCREEN_RESOLUTION_V}" -lt 1080 ] && TITLEBAR_FONT_SIZE=11

MENU_FONT_NAME="${TITLEBAR_FONT_NAME}"
MENU_FONT_STYLE="${INTERFACE_FONT_STYLE}"
MENU_FONT_SIZE=${TITLEBAR_FONT_SIZE}

MENUHEADER_FONT_NAME="${MENU_FONT_NAME}"
MENUHEADER_FONT_STYLE="${TITLEBAR_FONT_STYLE}"
MENUHEADER_FONT_SIZE=${MENU_FONT_SIZE}

MONOSPACE_FONT_NAME="Droid Sans"
MONOSPACE_FONT_STYLE="Mono"
MONOSPACE_FONT_SIZE=13
[ "${SCREEN_RESOLUTION_V}" -lt 1080 ] && MONOSPACE_FONT_SIZE=12

SUBTITLES_FONT_NAME="${INTERFACE_FONT_NAME}"
SUBTITLES_FONT_STYLE="Bold"
SUBTITLES_FONT_SIZE=20
[ "${SCREEN_RESOLUTION_V}" -lt 1080 ] && SUBTITLES_FONT_SIZE=17

TEXT_EDITOR_FONT_NAME="${MONOSPACE_FONT_NAME}"
TEXT_EDITOR_FONT_STYLE="${MONOSPACE_FONT_STYLE}"
TEXT_EDITOR_FONT_SIZE=12
[ "${SCREEN_RESOLUTION_V}" -lt 1080 ] && TEXT_EDITOR_FONT_SIZE=11

INTERFACE_FONT="${INTERFACE_FONT_NAME} ${INTERFACE_FONT_STYLE} ${INTERFACE_FONT_SIZE}"
DOCUMENT_FONT="${DOCUMENT_FONT_NAME} ${DOCUMENT_FONT_STYLE} ${DOCUMENT_FONT_SIZE}"
TITLEBAR_FONT="${TITLEBAR_FONT_NAME} ${TITLEBAR_FONT_STYLE} ${TITLEBAR_FONT_SIZE}"
MENU_FONT="${MENU_FONT_NAME} ${MENU_FONT_STYLE} ${MENU_FONT_SIZE}"
MENUHEADER_FONT="${MENUHEADER_FONT_NAME} ${MENUHEADER_FONT_STYLE} ${MENUHEADER_FONT_SIZE}"
MONOSPACE_FONT="${MONOSPACE_FONT_NAME} ${MONOSPACE_FONT_STYLE} ${MONOSPACE_FONT_SIZE}"
SUBTITLES_FONT="${SUBTITLES_FONT_NAME} ${SUBTITLES_FONT_STYLE} ${SUBTITLES_FONT_SIZE}"
TEXT_EDITOR_FONT="${TEXT_EDITOR_FONT_NAME} ${TEXT_EDITOR_FONT_STYLE} ${TEXT_EDITOR_FONT_SIZE}"

# FONT COLOURS
FONT_COLOUR="#FFFFFF" # "#CFD8DC"
TERMINAL_BG=${GTK_THEME_BG_COLOUR}
TERMINAL_FG=${FONT_COLOUR}
TERMINAL_BLACK_D="#3D4D51"
TERMINAL_BLACK_L="#555753"
TERMINAL_RED_D="#CC0000"
TERMINAL_RED_L="#EF2929"
TERMINAL_GREEN_D="#4E9A06"
TERMINAL_GREEN_L="#8AE234"
TERMINAL_YELLOW_D="#C4A000"
TERMINAL_YELLOW_L="#FCE94F"
TERMINAL_BLUE_D="#3465A4"
TERMINAL_BLUE_L="#729FCF"
TERMINAL_PURPLE_D="#75507B"
TERMINAL_PURPLE_L="#AD7FA8"
TERMINAL_CYAN_D="#06989A"
TERMINAL_CYAN_L="#34E2E2"
TERMINAL_WHITE_D="#D3D7CF"
TERMINAL_WHITE_L="#EEEEEC"

# TERMINAL
TERMINAL_SIZE_COLS=128
TERMINAL_SIZE_ROWS=32
TERMINAL_SCROLLBACK_SIZE=15000
TERMINAL_BOLD_TEXT_IS_BRIGHT=false
TERMINAL_CURSOR_SHAPE="ibeam"

if [ "${SCREEN_RESOLUTION_V}" -lt 1440 ]; then
    TERMINAL_SIZE_COLS=100
elif [ "${SCREEN_RESOLUTION_V}" -lt 1080 ]; then
    TERMINAL_SIZE_COLS=80
    TERMINAL_SIZE_ROWS=24
fi

if ${HAS_GUI}; then
    if [[ "${ICON_THEME}" == *"Papirus"* ]]; then
        CURRENT_PAPIRUS_FOLDER_COLOUR=$(papirus-folders -l -t "${ICON_THEME}" | grep ">" | sed 's/ *> *//g')

        if [[ "${CURRENT_PAPIRUS_FOLDER_COLOUR}" != "${ICON_THEME_FOLDER_COLOUR}" ]]; then
            papirus-folders -t "${ICON_THEME}" -C "${ICON_THEME_FOLDER_COLOUR}"
        fi
    fi
fi

if does-bin-exist "mkinitcpio"; then
    MKINITCPIO_CONFIG_FILE="${ROOT_ETC}/mkinitcpio.conf"

    set_config_value "${MKINITCPIO_CONFIG_FILE}" "COMPRESSION" "\"lz4\""
fi

if [ -d "${ROOT_ETC}/modprobe.d" ]; then
    set_gsetting org.gtk.Settings.FileChooser startup-mode 'cwd'

    if ${USING_NVIDIA_GPU}; then
        set_modprobe_option nvidia-drm modset 1
    fi

    set_modprobe_option bluetooth disable_ertm 1    # Xbox One Controller Pairing
    set_modprobe_option btusb enable_autosuspend n  # Xbox One Controller Connecting, possibly other devices as well


    if [ "${CHASSIS_TYPE}" == "Laptop" ]; then
        set_modprobe_option usbcore autosuspend 1
    fi

    AUDIO_DRIVER="$(get_audio_driver)"

    if [ "${AUDIO_DRIVER}" = "snd_hda_intel" ]; then
        set_modprobe_option "${AUDIO_DRIVER}" power_save_controller Y
        set_modprobe_option "${AUDIO_DRIVER}" power_save 1
    elif [ "$(get_audio_driver)" = "snd_ac97_codec" ]; then
        set_modprobe_option "${AUDIO_DRIVER}" power_save 1
    fi

    if [ "$(get_wifi_driver)" = "iwlwifi" ]; then
        set_modprobe_option iwlwifi power_save 1
        set_modprobe_option iwlwifi uapsd_disable 0

        IWL_MODULE=$(lsmod | grep '^iwl.vm' | awk '{print $1}')

        [ "${IWL_MODULE}" = "iwldvm" ] && set_modprobe_option iwlmvm force_cam 0
        [ "${IWL_MODULE}" = "iwlmvm" ] && set_modprobe_option iwlmvm power_scheme 3
    fi

    ### Disable unused features

    # Disable PCMCIA
    set_modprobe_option blacklist pcmcia
    set_modprobe_option blacklist yenta_socket

    # Disable USB 1.1
    set_modprobe_option blacklist uhci_hcd
fi

if [ -d "${ROOT_ETC}/sysctl.d" ]; then
    SYSCTL_CONFIG_FILE="${ROOT_ETC}/sysctl.d/00-system.conf"

    [ ! -f "${SYSCTL_CONFIG_FILE}" ] && run-as-su touch "${SYSCTL_CONFIG_FILE}"

    set_config_value "${SYSCTL_CONFIG_FILE}" "net.ipv6.conf.all.disable_ipv6" 1 # Disable IPv6
    set_config_value "${SYSCTL_CONFIG_FILE}" "kernel.nmi_watchdog" 0            # Disable NMI interrupts that can consume a lot of power

    if [ "${CHASSIS_TYPE}" = "Laptop" ]; then
        set_config_value "${SYSCTL_CONFIG_FILE}" "vm.dirty_writeback_centisecs" "12000" # 2 minutes. Increase the vitual memory dirty writeback time to aggregate disk I/O together and save power
        set_config_value "${SYSCTL_CONFIG_FILE}" "vm.laptop_mode" 5
    else
        set_config_value "${SYSCTL_CONFIG_FILE}" "vm.dirty_writeback_centisecs" "500" # Default value
        set_config_value "${SYSCTL_CONFIG_FILE}" "vm.laptop_mode" 0
    fi
fi

if [ -f "${ROOT_ETC}/default/grub" ]; then
    GRUB_CONFIG_FILE="${ROOT_ETC}/default/grub"

    GRUB_TIMEOUT=1
    GRUB_BOOT_ENTRIES_COUNT=$(grep "^menuentry" "/boot/grub/grub.cfg" | sed \
        -e '/UEFI Firmware Setting/d' \
        -e '/Reboot/d' \
        -e '/Power off/d' |
        wc -l)

    [ ${GRUB_BOOT_ENTRIES_COUNT} -eq 1 ] && GRUB_TIMEOUT=0

    BOOT_FLAGS_DEFAULT="loglevel=3 quiet" # Defaults
    BOOT_FLAGS_DEFAULT="${BOOT_FLAGS_DEFAULT} random.trust_cpu=on" # Trust the CPU's random number generator ratherthan software. Better boot time

    if [ "${CHASSIS_TYPE}" = "Laptop" ] && is_driver_loaded "i915"; then
        BOOT_FLAGS_DEFAULT="${BOOT_FLAGS_DEFAULT} i915.i915_enable_rc6=1"   # Allow the GPU to enter a low power state when it is idling
        #BOOT_FLAGS_DEFAULT="${BOOT_FLAGS_DEFAULT} i915.i915_enable_fbc=1"   # Enable framebuffer compression to consume less memory
        #BOOT_FLAGS_DEFAULT="${BOOT_FLAGS_DEFAULT} i915.lvds_downclock=1"    # !CAN CAUSE TEARING! Downclocks the LVDS refresh rate
    fi

    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_CMDLINE_LINUX_DEFAULT" "\"${BOOT_FLAGS_DEFAULT}\""

    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_DISABLE_RECOVERY" true
    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_TIMEOUT" "${GRUB_TIMEOUT}"

    if [ -f "${ROOT_USR}/share/grub/themes/Nuci/theme.txt" ]; then
        set_config_value "${GRUB_CONFIG_FILE}" "GRUB_THEME" "${ROOT_USR}/share/grub/themes/Nuci/theme.txt"
    fi

    # Set GRUB resolution to the highest supported one
    if [ "$(get_gpu_model)" == "GeForce GTX 1650" ]; then
        if [ "${SCREEN_RESOLUTION_H}" -ge 1280 ] \
        && [ "${SCREEN_RESOLUTION_V}" -ge 1024 ]; then
            set_config_value "${GRUB_CONFIG_FILE}" "GRUB_GFXMODE" "1280x1024x32"
        fi
    fi
fi

if does-bin-exist "gnome-shell"; then
    if ( ! ${POWERFUL_PC} ); then
        set_gsetting "org.gnome.settings-daemon.plugins.remote-display" active false
        set_gsetting "org.gnome.desktop.interface" enable-animations false
    fi

    set_gsetting "org.gnome.desktop.datetime" automatic-timezone true

    set_gsetting "org.gnome.desktop.interface" clock-show-weekday true
    set_gsetting "org.gnome.desktop.interface" enable-hot-corners false
    set_gsetting "org.gnome.desktop.interface" toolbar-icons-size 'small'
    set_gsetting "org.gnome.desktop.interface" toolbar-style 'icons'

    set_gsetting "org.gnome.desktop.privacy" old-files-age "uint32 14"
    set_gsetting "org.gnome.desktop.privacy" remove-old-temp-files true
    set_gsetting "org.gnome.desktop.privacy" remove-old-trash-files true

    set_gsetting "org.gnome.desktop.peripherals.touchpad" click-method "default"
    set_gsetting "org.gnome.desktop.peripherals.touchpad" tap-to-click true

    set_gsetting "org.gnome.desktop.interface" clock-show-date true
    set_gsetting "org.gnome.desktop.interface" cursor-theme "${CURSOR_THEME}"
    set_gsetting "org.gnome.desktop.interface" document-font-name "${DOCUMENT_FONT}"
    set_gsetting "org.gnome.desktop.interface" font-name "${INTERFACE_FONT}"
    set_gsetting "org.gnome.desktop.interface" gtk-theme "${GTK_THEME}"
    set_gsetting "org.gnome.desktop.interface" icon-theme "${ICON_THEME}"
    set_gsetting "org.gnome.desktop.interface" monospace-font-name "${MONOSPACE_FONT}"
    set_gsetting "org.gnome.desktop.interface" show-battery-percentage true

    set_gsetting "org.gnome.desktop.peripherals.touchpad" disable-while-typing false

    set_gsetting "org.gnome.mutter" attach-modal-dialogs false
    set_gsetting "org.gnome.mutter" center-new-windows true

    set_gsetting org.gnome.settings-daemon.plugins.housekeeping free-size-gb-no-notify 2
    set_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true

    set_gsetting org.gnome.SessionManager logout-prompt false

    set_gsetting "org.gnome.shell.overrides" attach-modal-dialogs false
fi

if does-gnome-shell-extension-exist "blur-my-shell"; then
    BMS_SCHEMA="org.gnome.shell.extensions.blur-my-shell"

    set_gsetting "${BMS_SCHEMA}" blur-panel false # Let it be handled by the theme itself
fi

if does-gnome-shell-extension-exist "user-theme"; then
    set_gsetting "org.gnome.shell.extensions.user-theme" name "${GTK_THEME}"
fi

if does-gnome-shell-extension-exist "multi-monitors-add-on"; then
    set_gsetting "org.gnome.shell.extensions.multi-monitors-add-on" show-indicator false
fi

if does-bin-exist "panther_launcher"; then
    set_gsetting "org.rastersoft.panther" icon-size 48
    set_gsetting "org.rastersoft.panther" use-category true
fi

if ${HAS_GUI}; then
    ENVIRONMENT_VARS_FILE="${ROOT_ETC}/environment"
    set_config_value "${ENVIRONMENT_VARS_FILE}" QT_QPA_PLATFORMTHEME "gtk3"

    if [ -d "${ROOT_USR_LIB}/gtk-2.0" ]; then
        GTK2_CONFIG_FILE="${HOME_REAL}/.gtkrc-2.0"
        GTK2_FILECHOOSER_CONFIG_FILE="${HOME_REAL}/.config/gtk-2.0/filechooser.ini"

        set_config_value "${GTK2_CONFIG_FILE}" gtk-theme-name "${GTK2_THEME}"
        set_config_value "${GTK2_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
        set_config_value "${GTK2_CONFIG_FILE}" gtk-cursor-theme-name "${CURSOR_THEME}"
        set_config_value "${GTK2_CONFIG_FILE}" gtk-button-images 0
        set_config_value "${GTK2_CONFIG_FILE}" gtk-menu-images 0
        set_config_value "${GTK2_CONFIG_FILE}" gtk-toolbar-style GTK_TOOLBAR_ICONS

        set_config_value "${GTK2_FILECHOOSER_CONFIG_FILE}" StartupMode cwd
    fi

    if [ -d "${ROOT_USR_LIB}/gtk-3.0" ]; then
        GTK3_CONFIG_FILE="${HOME_REAL}/.config/gtk-3.0/settings.ini"

        set_config_value "${GTK3_CONFIG_FILE}" gtk-application-prefer-dark-theme ${DESKTOP_THEME_IS_DARK_BINARY}
        set_config_value "${GTK3_CONFIG_FILE}" gtk-theme-name "${GTK3_THEME}"
        set_config_value "${GTK3_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
        set_config_value "${GTK3_CONFIG_FILE}" gtk-cursor-theme-name "${CURSOR_THEME}"
        set_config_value "${GTK3_CONFIG_FILE}" gtk-button-images 0
        set_config_value "${GTK3_CONFIG_FILE}" gtk-menu-images 0
        set_config_value "${GTK3_CONFIG_FILE}" gtk-toolbar-style GTK_TOOLBAR_ICONS
    fi

    if [ -d "${ROOT_USR_LIB}/gtk-4.0" ]; then
        GTK4_CONFIG_FILE="${HOME_REAL}/.config/gtk-4.0/settings.ini"

        set_config_value "${GTK4_CONFIG_FILE}" gtk-application-prefer-dark-theme ${DESKTOP_THEME_IS_DARK_BINARY}
        set_config_value "${GTK4_CONFIG_FILE}" gtk-theme-name "${GTK4_THEME}"
        set_config_value "${GTK4_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
        set_config_value "${GTK4_CONFIG_FILE}" gtk-cursor-theme-name "${CURSOR_THEME}"
        set_config_value "${GTK4_CONFIG_FILE}" gtk-button-images 0
        set_config_value "${GTK4_CONFIG_FILE}" gtk-menu-images 0
    fi
fi

if does-bin-exist "makepkg"; then
    MAKEPKG_CONFIG_FILE="${ROOT_ETC}/makepkg.conf"

    set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSXZ" "(xz -c -z --threads=0 -)"
    set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSZST" "(zstd -c -z -q --threads=0 -)"

    if does-bin-exist "pbzip2"; then
        set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSBZ2" "(pbzip2 -c -f)"
    else
        set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSBZ2" "(bzip2 -c -f)"
    fi

    if does-bin-exist "pigz"; then
        set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSGZ" "(pigz -c -f -n)"
    else
        set_config_value "${MAKEPKG_CONFIG_FILE}" "COMPRESSGZ" "(gzip -c -f -n)"
    fi
fi

if [ -f "${HOME_REAL}/.config/lxsession/LXDE/desktop.conf" ]; then
    LXSESSION_CONFIG_FILE="${HOME_REAL}/.config/lxsession/LXDE/desktop.conf"

    LXDE_WM=""

    if does-bin-exist "openbox"; then
        LXDE_WM="openbox-lxde"
    elif does-bin-exist "xfwm4"; then
        LXDE_WM="mutter"
    elif does-bin-exist "mutter"; then
        LXDE_WM="mutter"
    fi

    [ -n "${LXDE_WM}" ] && set_config_value "${LXSESSION_CONFIG_FILE}" window_manager "${LXDE_WM}"

    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/ThemeName "${GTK_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/IconThemeName "${ICON_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/CursorThemeName "${CURSOR_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/ButtonImages 0
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/MenuImages 0
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/ToolbarStyle 0
fi

###################
### Ad Blockers ###
###################

if does-bin-exist "pihole-FTL"; then
    PIHOLE_DNSMASQ_CONFIG_PATH="/etc/dnsmasq.d/01-pihole.conf"

    set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "cache-size" $((DNS_CACHE_SIZE))
    set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "local-ttl" $((DNS_CACHE_TTL*60*3))
    set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "min-cache-ttl" $((DNS_CACHE_TTL*60))
fi

########################
### ARCHIVE MANAGERS ###
########################
if does-bin-exist "file-roller"; then
    set_gsetting "org.gnome.FileRoller.General" compression-level "maximum"
fi

#############
### Audio ###
#############
if does-bin-exist "gnome-shell"; then
    set_gsetting org.gnome.desktop.sound allow-volume-above-100-percent true
    set_gsetting org.gnome.settings-daemon.plugins.media-keys volume-step 3
fi
if does-bin-exist "openal-info"; then
    set_config_value "${HOME_REAL}/.alsoftrc" hrtf true
fi
if does-bin-exist "pulseaudio"; then
    set_config_value "${ROOT_ETC}/pulse/daemon.conf" resample-method speex-float-10
    set_config_value --separator " " "${ROOT_ETC}/pulse/default.pa" load-module module-suspend-on-idle
fi

#if does-gnome-shell-extension-exist "sound-output-device-chooser"; then
#    SODC_SCHEMA="org.gnome.shell.extensions.sound-output-device-chooser"
#
#    set_gsetting "${SODC_SCHEMA}" hide-on-single-device true
#    set_gsetting "${SODC_SCHEMA}" show-profiles false
#fi

###################
### CALCULATORS ###
###################
if does-bin-exist "gnome-calculator"; then
    GNOME_CALCULATOR_SCHEMA="org.gnome.calculator"

    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" show-thousands true
    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" source-currency 'EUR'
    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" target-currency 'RON'
fi
if does-bin-exist "mate-calc"; then
    set_gsetting "org.mate.calc" show-thousands true
fi

#################
### CHAT APPS ###
#################
if does-bin-exist "discord"; then
    set_json_value "${HOME_REAL}/.config/discord/settings.json" '.BACKGROUND_COLOR' ${GTK_THEME_BG_COLOUR}
fi
if does-bin-exist "teams" || does-bin-exist "teams-insiders"; then
    TEAMS_DESKTOP_CONFIG_FILE="${HOME_CONFIG}/Microsoft/Microsoft Teams/desktop-config.json"

    does-bin-exist "teams-insiders" && TEAMS_DESKTOP_CONFIG_FILE="${HOME_CONFIG}/Microsoft/Microsoft Teams - Insiders/desktop-config.json"

    # Fixes
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.appPreferenceSettings.disableGpu' true

    # Appearance
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.currentWebLanguage' "$(echo ${APPS_LANGUAGE,,} | sed 's/_/-/g')"

    if ${DESKTOP_THEME_IS_DARK}; then
        set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.theme' "darkV2"
    else
        set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.theme' "defaultV2"
    fi

    # Window state
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.surfaceHubWindowState.isMaximized' true
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.surfaceHubWindowState.isFullScreen' false
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.windowState.isMaximized' true
    set_json_value "${TEAMS_DESKTOP_CONFIG_FILE}" '.windowState.isFullScreen' false

fi
if does-bin-exist "telegram-desktop"; then
    set_config_value "${ENVIRONMENT_VARS_FILE}" TDESKTOP_I_KNOW_ABOUT_GTK_INCOMPATIBILITY "1"
fi
if does-bin-exist "whatsapp-for-linux"; then
    WAPP_CONFIG_FILE="${HOME_REAL}/.config/whatsapp-for-linux/settings.conf"

    # Disable tray because tray icons don't work and the window becomes inaccessible
    set_config_value "${WAPP_CONFIG_FILE}" close_to_tray false
    set_config_value "${WAPP_CONFIG_FILE}" start_in_tray false
fi
if does-bin-exist "whatsapp-nativefier"; then
    WAPP_CONFIG_FILE="${ROOT_OPT}/whatsapp-nativefier/resources/app/nativefier.json"
    #WAPP_PREFERENCES_FILE="${HOME}/.config/whatsapp-nativefier-d40211/Preferences"

    #sudo bash -c "$(declare -f set_json_value); set_json_value \"${WAPP_CONFIG_FILE}\" '.tray' \"start-in-tray\""
    set_json_value_root "${WAPP_CONFIG_FILE}" '.tray' "start-in-tray"

    set_json_value_root "${WAPP_CONFIG_FILE}" '.zoom' "${ZOOM_LEVEL}"
    #set_json_value "${WAPP_PREFERENCES_FILE}" '.partition.per_host_zoom_levels[]."web.whatsapp.com"' "${ZOOM_LEVEL}"
fi

##############
### Citrix ###
##############
if [ -d "${ROOT_OPT}/Citrix" ]; then
    set_config_value "${HOME_REAL}/.ICAClient/wfclient.ini" SSLCiphers "ALL" # TODO: Make sure it's put under [WFClient]
fi

#############################
### CONFIGURATION EDITORS ###
#############################
if does-bin-exist "dconf-editor"; then
    set_gsetting ca.desrt.dconf-editor.Settings show-warning false
fi

################
### Contacts ###
################
if does-bin-exist "gnome-contacts"; then
    set_gsetting "org.gnome.Contacts" did-initial-setup true
    set_gsetting "org.gnome.Contacts" sort-on-surname true
fi

#############
### DOCKS ###
#############
if does-gnome-shell-extension-exist "dash-to-dock"; then
    DTD_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

    # Temp-fix for messed-up background
    set_gsetting "${DTD_SCHEMA}" apply-custom-theme true

    set_gsetting "${DTD_SCHEMA}" background-opacity 0.0
    set_gsetting "${DTD_SCHEMA}" click-action minimize
    set_gsetting "${DTD_SCHEMA}" custom-theme-customize-running-dots true
    set_gsetting "${DTD_SCHEMA}" custom-theme-running-dots-color "#01a299"
    set_gsetting "${DTD_SCHEMA}" custom-theme-shrink true
    set_gsetting "${DTD_SCHEMA}" dock-position BOTTOM
    set_gsetting "${DTD_SCHEMA}" intellihide-mode ALL_WINDOWS
    set_gsetting "${DTD_SCHEMA}" multi-monitor true
    set_gsetting "${DTD_SCHEMA}" running-indicator-style DOTS
    set_gsetting "${DTD_SCHEMA}" scroll-action cycle-windows
    set_gsetting "${DTD_SCHEMA}" show-show-apps-button false
    set_gsetting "${DTD_SCHEMA}" show-trash false
    set_gsetting "${DTD_SCHEMA}" transparency-mode FIXED

    if does-gnome-shell-extension-exist "blur-my-shell"; then
        BMS_SCHEMA="org.gnome.shell.extensions.blur-my-shell"

        set_gsetting "${BMS_SCHEMA}" blur-dash false # Breaks the dock if true
    fi
fi
if does-bin-exist "plank"; then
    PLANK_SCHEMA="net.launchpad.plank.docks.dock1"

    set_gsetting "${PLANK_SCHEMA}" theme "Transparent"
    set_gsetting "${PLANK_SCHEMA}" hide-mode "window-dodge"
fi

########################
### DOCUMENT VIEWERS ###
########################
if does-bin-exist "epdfview"; then
    EPDFVIEW_CONFIG_FILE="${HOME_REAL}/.config/epdfview/main.conf"

    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToFit false
    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToWidth true
    set_config_value "${EPDFVIEW_CONFIG_FILE}" browser "chromium %s"
fi

#####################
### FILE MANAGERS ###
#####################
if does-bin-exist "nautilus"; then
    NAUTILUS_SCHEMA="org.gnome.nautilus"

    set_gsetting "${NAUTILUS_SCHEMA}.icon-view" default-zoom-level "standard"
    set_gsetting "${NAUTILUS_SCHEMA}.list-view" default-zoom-level "small"
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" search-view 'list-view'
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-create-link true
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-delete-permanently true
    set_gsetting "${NAUTILUS_SCHEMA}.window-state" sidebar-width 240
fi
if does-bin-exist "pcmanfm"; then
    PCMANFM_CONFIG_FILE="${HOME_REAL}/.config/pcmanfm/LXDE/pcmanfm.conf"

    set_config_value "${PCMANFM_CONFIG_FILE}" always_show_tabs 0
    set_config_value "${PCMANFM_CONFIG_FILE}" max_tab_chars 48
    set_config_value "${PCMANFM_CONFIG_FILE}" pathbar_mode_buttons 1
    set_config_value "${PCMANFM_CONFIG_FILE}" show_statusbar 0
    set_config_value "${PCMANFM_CONFIG_FILE}" toolbar "navigation;"
    set_config_value "${PCMANFM_CONFIG_FILE}" side_pane_mode "hidden;places"
fi
if [ -f "${HOME_REAL}/.config/pcmanfm/LXDE/desktop-items-0.conf" ]; then
    PCMANFM_DESKTOP_CONFIG_FILE="${HOME_REAL}/.config/pcmanfm/LXDE/desktop-items-0.conf"

    set_config_value "${PCMANFM_DESKTOP_CONFIG_FILE}" folder ""
    set_config_value "${PCMANFM_DESKTOP_CONFIG_FILE}" show_documents 0
    set_config_value "${PCMANFM_DESKTOP_CONFIG_FILE}" show_trash 0
    set_config_value "${PCMANFM_DESKTOP_CONFIG_FILE}" show_mounts 0
fi

###############
### FIREFOX ###
###############
if does-bin-exist "firefox"; then
    FIREFOX_PROFILES_INI_FILE="${HOME_REAL}/.mozilla/firefox/profiles.ini"
    FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

    # First time prompts
    set_firefox_config "${FIREFOX_PROFILE_ID}" app.normandy.first_run false
    set_firefox_config "${FIREFOX_PROFILE_ID}" browser.aboutConfig.showWarning false
    set_firefox_config "${FIREFOX_PROFILE_ID}" browser.urlbar.quicksuggest.onboardingDialogChoice "settings"
    set_firefox_config "${FIREFOX_PROFILE_ID}" devtools.everOpened true
    set_firefox_config "${FIREFOX_PROFILE_ID}" doh-rollout.doneFirstRun true
    set_firefox_config "${FIREFOX_PROFILE_ID}" extensions.fxmonitor.firstAlertShown true

    set_firefox_config "${FIREFOX_PROFILE_ID}" "beacon.enabled" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.safebrowsing.downloads.remote.enabled" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.search.region" "RO"
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.send_pings" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.delayHidingAudioPlayingIconMS" 0
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.insertAfterCurrent" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.tabMinWidth" 0
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.warnOnClose" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.translation.detectLanguage" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.uidensity" 1
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.autoFill" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.speculativeConnect.enabled" false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "dom.event.clipboardevents.enabled" true # Fix for Google's office suite
    set_firefox_config "${FIREFOX_PROFILE_ID}" "extensions.screenshots.disabled" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "findbar.highlightAll" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "full-screen-api.warning.timeout" 0
    set_firefox_config "${FIREFOX_PROFILE_ID}" "media.autoplay.enabled" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "media.navigator.enabled" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.IDN_show_punycode" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "privacy.trackingprotection.enabled" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "security.insecure_connection_text.enabled" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "security.sandbox.content.level" 0 # iHD fix
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.tabbox.switchByScrolling" true

    # Appearance
    set_firefox_config "${FIREFOX_PROFILE_ID}" "devtools.theme" ${GTK_THEME_VARIANT}
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.gtk.alt-theme.dark" ${DESKTOP_THEME_IS_DARK}
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.in-content.dark-mode" ${DESKTOP_THEME_IS_DARK}
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.drawInTitlebar" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.uidensity" 1 # Compact mode
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.legacyUserProfileCustomizations.stylesheets" true
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "widget.non-native-theme.enabled" false # If true then some page elements (e.g. drop-down arrows in Bitwarden) look very ugly and out of place
    set_firefox_config "${FIREFOX_PROFILE_ID}" "widget.content.allow-gtk-dark-theme" ${DESKTOP_THEME_IS_DARK}

    # Appearance - Links
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.anchor_color" "${TERMINAL_CYAN_D}" # "#00BCD4"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.anchor_color.dark" "${TERMINAL_PURPLE_D}"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.underline_anchors" false

    # Useless features
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.section.highlights" false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.snippets" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.topsites" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "extensions.pocket.enabled" false

    # URL bar
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.groupLabels.enabled" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.quicksuggest.enabled" true
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.quicksuggest.scenario" 'offline'
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.suggest.calculator" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.suggest.quicksuggest" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.suggest.quicksuggest.sponsored" false

    # Performance
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dnsCacheEntries" $((DNS_CACHE_SIZE/10))
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dnsCacheExpiration" $((DNS_CACHE_TTL*60))
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dnsCacheExpirationGracePeriod" $((DNS_CACHE_TTL*60))

    # Security
    set_firefox_config "${FIREFOX_PROFILE_ID}" "dom.security.https_first" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "dom.security.https_only_mode" true

    # DNS Prefetching
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dns.disablePrefetch" true
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dns.disablePrefetchFromHTTPS" true
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.predictor.enabled" false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "network.predictor.enable-prefetch" false
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.prefetch-next" false

    # Privacy
    set_firefox_config "${FIREFOX_PROFILE_ID}" "privacy.firstparty.isolate" true
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "privacy.resistFingerprinting" true # If true: starts in a small window, cannot detect system dark theme
    #set_firefox_config "${FIREFOX_PROFILE_ID}" "privacy.trackingprotection.fingerprinting.enabled" true

    # Telemetry
    set_firefox_config "${FIREFOX_PROFILE_ID}" browser.newtabpage.activity-stream.telemetry false
    set_firefox_config "${FIREFOX_PROFILE_ID}" browser.newtabpage.activity-stream.feeds.telemetry false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" browser.newtabpage.activity-stream.telemetry.ut.events false
    set_firefox_config "${FIREFOX_PROFILE_ID}" browser.ping-centre.telemetry false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" browser.urlbar.eventTelemetry.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" datareporting.healthreport.uploadEnabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" dom.security.unexpected_system_load_telemetry_enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" network.trr.confirmation_telemetry_enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" security.app_menu.recordEventTelemetry false
    set_firefox_config "${FIREFOX_PROFILE_ID}" security.certerrors.recordEventTelemetry false
    set_firefox_config "${FIREFOX_PROFILE_ID}" security.identitypopup.recordEventTelemetry false
    set_firefox_config "${FIREFOX_PROFILE_ID}" security.protectionspopup.recordEventTelemetry false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.archive.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.bhrPing.enabled false
    #set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.firstShutdownPing.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.hybridContent.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.newProfilePing.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.pioneer-new-studies-available false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.reportingpolicy.firstRun false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.shutdownPingSender.enabled false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.unified false
    set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.updatePing.enabled false

    #set_firefox_config "${FIREFOX_PROFILE_ID}" browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint "http://localhost"
    #set_firefox_config "${FIREFOX_PROFILE_ID}" toolkit.telemetry.server "http://localhost"

    # Identity
    set_firefox_config "${FIREFOX_PROFILE_ID}" "identity.fxaccounts.account.device.name" "${HOSTNAME}"
fi

##############################
### Games & Game Launchers ###
##############################
MC_DIR="${HOME}/.minecraft"
MC_OPTIONS_FILE="${MC_DIR}/options.txt"
MC_LAUNCHER_PROFILES_FILE="${MC_DIR}/launcher_profiles.json"
MC_LAUNCHER_SETTINGS_FILE="${MC_DIR}/launcher_settings.json"

if [ -f "${MC_OPTIONS_FILE}" ]; then
    DEVICE_ID=$(shuf -i1000000000000000000-9999999999999999999 -n1)

    set_config_value --separator ":" "${MC_OPTIONS_FILE}" lang "${GAMES_LANGUAGE,,}"

    # Appearance
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" darkMojangStudiosBackground "${DESKTOP_THEME_IS_DARK}"

    # Input
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" pauseOnLostFocus true
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" rawMouseInput true

    # First time experiences
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" skipMultiplayerWarning true
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" joinedFirstServer true

    set_json_value "${MC_LAUNCHER_PROFILES_FILE}" '.settings.crashAssistance' false
    set_json_value "${MC_LAUNCHER_SETTINGS_FILE}" '.deviceId' "${DEVICE_ID}"
    set_json_value "${MC_LAUNCHER_SETTINGS_FILE}" '.locale' "${GAMES_LANGUAGE/_/-}"
fi

PDX_LAUNCHER_DATA_DIR="${HOME}/.local/share/Paradox Interactive/launcher-v2"
PDX_LAUNCHER_USER_SETTINGS_FILE="${PDX_LAUNCHER_DATA_DIR}/userSettings.json"

if [ -f "${PDX_LAUNCHER_USER_SETTINGS_FILE}" ]; then
    set_json_value "${PDX_LAUNCHER_USER_SETTINGS_FILE}" '.allowPersonalizedContent' false
fi

ASPYR_DIR="{HOME}/.local/share/Aspyr"
CIV5_DIR="${ASPYR_DIR}/Sid Meier's Civilization 5"
CIV5_USER_SETTINGS_FILE="${CIV5_DIR}/UserSettings.ini"

if [ -f "${CIV5_USER_SETTINGS_FILE}" ]; then
    set_config_value "${CIV5_USER_SETTINGS_FILE}" "AdvisorLevel" 0
    set_config_value "${CIV5_USER_SETTINGS_FILE}" "TutorialLevel" 0
    set_config_value "${CIV5_USER_SETTINGS_FILE}" "SkipIntroVideo" 1
fi

TERRARIA_DIR="${HOME}/.local/share/Terraria"
TERRARIA_CONFIG_FILE="${TERRARIA_DIR}/config.json"

if [ -f "${TERRARIA_CONFIG_FILE}" ]; then
    set_json_value "${TERRARIA_CONFIG_FILE}" ".QuickLaunch" true
fi

###########
### GPG ###
###########
if does-bin-exist "gpg"; then
    GNUPG_DIRMNGR_CONFIG="${HOME}/.gnupg/dirmngr.conf"

    if [ ! -d "${HOME}/.gnupg" ]; then
        mkdir "${HOME}/.gnupg"
        touch "${GNUPG_DIRMNGR_CONFIG}"
    fi

    set_config_value --separator " " "${GNUPG_DIRMNGR_CONFIG}" keyserver "hkp://keyserver.ubuntu.com"
fi

#################
### GSConnect ###
#################
if [ -d "${ROOT_USR}/share/gnome-shell/extensions/gsconnect@andyholmes.github.io" ] \
|| [ -d "${HOME}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io" ]; then
    GSCONNECT_SCHEMA="org.gnome.Shell.Extensions.GSConnect"

    set_gsetting "${GSCONNECT_SCHEMA}" name "${HOSTNAME}"
fi

############
### IDEs ###
############
if does-bin-exist "code" || does-bin-exist "code-oss" || does-bin-exist "codium"; then
    # The order is important, some might be present simultaoneously for a single package
    does-bin-exist "code" && VSCODE_CONFIG_FILE="${HOME}/.config/Code/User/settings.json"
    does-bin-exist "code-oss" && VSCODE_CONFIG_FILE="${HOME}/.config/Code - OSS/User/settings.json"
    does-bin-exist "codium" && VSCODE_CONFIG_FILE="${HOME}/.config/VSCodium/User/settings.json"

    if [ ! -f "${VSCODE_CONFIG_FILE}" ]; then
        create-file-if-not-exists "${VSCODE_CONFIG_FILE}"
        printf "{}" > "${VSCODE_CONFIG_FILE}"
    fi

    # Appearance
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectActivityBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectTabActiveBorder"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.showColorInStatusBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["update.mode"]' "none"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.autoDetectColorScheme"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.menuBarVisibility"]' "toggle"
    #set_json_value "${VSCODE_CONFIG_FILE}" '.["window.title"]' '${dirty}${activeEditorShort}${separator}${rootName}${separator}VS Code'
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.colorTheme"]' "Default Dark+"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.iconTheme"]' "seti"

    # Editor appearance
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.codeLens"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.fontFamily"]' "${MONOSPACE_FONT_NAME} ${MONOSPACE_FONT_STYLE}"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.fontSize"]' $((MONOSPACE_FONT_SIZE+3))
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.roundedSelection"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.maxColumn"]' 100
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.renderCharacters"]' false

    # Editor behaviour
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.autoClosingBrackets"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.find.autoFindInSelection"]' "never"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.find.seedSearchStringFromSelection"]' "selection"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.foldingMaximumRegions"]' 7500
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.unicodeHighlight.ambiguousCharacters"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.largeFileOptimizations"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDragAndDrop"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDelete"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autofetch"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autofetchPeriod"]' 300
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.scrollback"]' ${TERMINAL_SCROLLBACK_SIZE}

    # Disable unwanted features
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.startupEditor"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["security.workspace.trust.enabled"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.enablePersistentSessions"]' false

    # C#
    set_json_value "${VSCODE_CONFIG_FILE}" '.["omnisharp.enableDecompilationSupport"]' true

    # Terminal
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.allowChords"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.drawBoldTextInBrightColors"]' ${TERMINAL_BOLD_TEXT_IS_BRIGHT}
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.fontFamily"]' "${MONOSPACE_FONT_NAME} ${MONOSPACE_FONT_STYLE}"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.fontSize"]' $((MONOSPACE_FONT_SIZE+3))

    if [ "${TERMINAL_CURSOR_SHAPE}" == "ibeam" ]; then
        set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.cursorStyle"]' "line"
    else
        set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.cursorStyle"]' "${TERMINAL_CURSOR_SHAPE}"
    fi

    # Git
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autoStash"]' true

    # Telemetry
    set_json_value "${VSCODE_CONFIG_FILE}" '.["telemetry.enableCrashReporter"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["telemetry.enableTelemetry"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["telemetry.telemetryLevel"]' "off"
fi

################
### INKSCAPE ###
################
if does-bin-exist "inkscape"; then
    INKSCAPE_PREFERENCES_FILE="${HOME}/.config/inkscape/preferences.xml"

    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultPreferDarkTheme" "${DESKTOP_THEME_IS_DARK_BINARY}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultGtkTheme" "${GTK_THEME}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultIconTheme" "${ICON_THEME}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@darkTheme" "${DESKTOP_THEME_IS_DARK_BINARY}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@preferDarkTheme" "${DESKTOP_THEME_IS_DARK_BINARY}"
fi

########################
### KEYBOARD & MOUSE ###
########################
if does-bin-exist "gnome-shell"; then
    # Keyboard
    set_gsetting org.gnome.desktop.peripherals.keyboard numlock-state true
    set_gsetting org.gnome.desktop.input-sources sources "[('xkb', 'ro')]"
    set_gsetting org.gnome.desktop.input-sources xkb-options "['lv3:ralt_switch']"

    # Keybindings
    set_gsetting org.gnome.settings-daemon.plugins.media-keys logout "['<Alt>l']"

    # Mouse
    set_gsetting org.gnome.desktop.peripherals.mouse accel-profile "flat"
    set_gsetting org.gnome.desktop.peripherals.mouse speed 0.17999999999999999 # 0.18 can't be set
fi
if does-bin-exist "mutter"; then
    MUTTER_KEYBINDINGS_SCHEMA="org.gnome.desktop.wm.keybindings"

    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" panel-run-dialog "['<Super>r']"
    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" switch-applications "['<Alt>Tab']"
    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" switch-applications-backward "['<Shift><Alt>Tab']"
    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" switch-group "['<Super>Tab']"
    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" switch-group-backward "['<Shift><Super>Tab']"
    set_gsetting "${MUTTER_KEYBINDINGS_SCHEMA}" toggle-fullscreen "['<Super>f']"
fi

############
### MAPS ###
############
if does-bin-exist "gnome-maps"; then
    set_gsetting org.gnome.Maps night-mode true
fi

################
### NEOFETCH ###
################
if does-bin-exist "neofetch"; then
    NEOFETCH_CONFIG_DIR="${HOME_REAL}/.config/neofetch"
    NEOFETCH_CONFIG_FILE="${NEOFETCH_CONFIG_DIR}/config.conf"
    NEOFETCH_CUSTOM_ASCII_FILE="${NEOFETCH_CONFIG_DIR}/ascii"

    [ -f "${NEOFETCH_CUSTOM_ASCII_FILE}" ] && set_config_value "${NEOFETCH_CONFIG_FILE}" image_source "\"${NEOFETCH_CUSTOM_ASCII_FILE}\""
fi

###################
### NIGHT LIGHT ###
###################
if does-bin-exist "gnome-shell"; then
    set_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true
fi

#####################
### NOTIFICATIONS ###
#####################
if does-bin-exist "gnome-shell"; then
    GNOME_NOTIFICATIONS_SCHEMA="org.gnome.desktop.notifications.application:/org/gnome/desktop/notifications/application"

    # Disable
    does-bin-exist "simplenote" && set_gsetting "${GNOME_NOTIFICATIONS_SCHEMA}/simplenote/" enable false

    # Hide on lockscreen
    set_gsetting "${GNOME_NOTIFICATIONS_SCHEMA}/gnome-power-panel/" show-in-lock-screen false
fi

########################
### POWER MANAGEMENT ###
########################
if does-bin-exist "gnome-shell"; then
    GNOME_POWER_SCHEMA="org.gnome.settings-daemon.plugins.power"

    set_gsetting "${GNOME_POWER_SCHEMA}" idle-dim true
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-ac-timeout 1800
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-battery-timeout 900
fi

if does-bin-exist "tlp"; then
    TLP_CONFIG_FILE="${ROOT_ETC}/tlp.conf"

    RUNTIME_PM_DRIVER_DENYLIST=""

    gpu_has_optimus_support && RUNTIME_PM_DRIVER_DENYLIST="${RUNTIME_PM_DRIVER_DENYLIST} nouveau nvidia"

    RUNTIME_PM_DRIVER_DENYLIST="$(echo ${RUNTIME_PM_DRIVER_DENYLIST} | sed 's/^\s*//g')"

    set_config_value "${TLP_CONFIG_FILE}" "RUNTIME_PM_DRIVER_DENYLIST" "\"${RUNTIME_PM_DRIVER_DENYLIST}\""
fi

###################
### Screenshots ###
###################
if does-bin-exist "gnome-screenshot"; then
    set_gsetting "org.gnome.gnome-screenshot" last-save-directory "${HOME}/Pictures"
fi

############
### Sudo ###
############
if does-bin-exist "sudo"; then
    SUDO_CONFIG_FILE="/etc/sudoers"

    set_config_value "${SUDO_CONFIG_FILE}" "Defaults timestamp_timeout" 15
fi

################
### Terminal ###
################
if does-bin-exist "gnome-terminal"; then
    GNOME_TERMINAL_SCHEMA="org.gnome.Terminal.Legacy"
    GNOME_TERMINAL_PROFILE_ID=$(get_gsetting org.gnome.Terminal.ProfilesList default)
    GNOME_TERMINAL_PROFILE_SCHEMA="${GNOME_TERMINAL_SCHEMA}.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_TERMINAL_PROFILE_ID}/"

    set_gsetting "${GNOME_TERMINAL_SCHEMA}".Settings default-show-menubar false
    set_gsetting "${GNOME_TERMINAL_SCHEMA}".Settings new-tab-position "next"
    set_gsetting "${GNOME_TERMINAL_SCHEMA}".Settings theme-variant ${GTK_THEME_VARIANT}

    # Theme / colours
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" background-color ${TERMINAL_BG}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" foreground-color ${TERMINAL_FG}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" palette "['${TERMINAL_BLACK_D}', '${TERMINAL_RED_D}', '${TERMINAL_GREEN_D}', '${TERMINAL_YELLOW_D}', '${TERMINAL_BLUE_D}', '${TERMINAL_PURPLE_D}', '${TERMINAL_CYAN_D}', '${TERMINAL_WHITE_D}', '${TERMINAL_BLACK_L}', '${TERMINAL_RED_L}', '${TERMINAL_GREEN_L}', '${TERMINAL_YELLOW_L}', '${TERMINAL_BLUE_L}', '${TERMINAL_PURPLE_L}', '${TERMINAL_CYAN_L}', '${TERMINAL_WHITE_L}']"
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" bold-is-bright ${TERMINAL_BOLD_TEXT_IS_BRIGHT}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" use-theme-colors false
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" scrollbar-policy "never"

    # Size
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" default-size-columns ${TERMINAL_SIZE_COLS}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" default-size-rows ${TERMINAL_SIZE_ROWS}

    # Font
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" font "${MONOSPACE_FONT}"
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" use-system-font true

    # Others
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" audible-bell false
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" cursor-shape ${TERMINAL_CURSOR_SHAPE}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" scrollback-lines ${TERMINAL_SCROLLBACK_SIZE}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" visible-name "NuciTerm"
fi

if does-bin-exist "lxterminal"; then
    LXTERMINAL_CONFIG_FILE="${HOME_REAL}/.config/lxterminal/lxterminal.conf"

    # Theme / colours
    set_config_value "${LXTERMINAL_CONFIG_FILE}" bgcolor ${TERMINAL_BG}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" fgcolor ${TERMINAL_FG}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_0 ${TERMINAL_BLACK_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_1 ${TERMINAL_RED_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_2 ${TERMINAL_GREEN_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_3 ${TERMINAL_YELLOW_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_4 ${TERMINAL_BLUE_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_5 ${TERMINAL_PURPLE_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_6 ${TERMINAL_CYAN_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_7 ${TERMINAL_WHITE_D}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_8 ${TERMINAL_BLACK_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_9 ${TERMINAL_RED_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_10 ${TERMINAL_GREEN_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_11 ${TERMINAL_YELLOW_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_12 ${TERMINAL_BLUE_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_13 ${TERMINAL_PURPLE_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_14 ${TERMINAL_CYAN_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" palette_color_15 ${TERMINAL_WHITE_L}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" boldbright ${TERMINAL_BOLD_TEXT_IS_BRIGHT}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" hidemenubar true
    set_config_value "${LXTERMINAL_CONFIG_FILE}" hidescrollbar true

    # Size
    set_config_value "${LXTERMINAL_CONFIG_FILE}" geometry_columns ${TERMINAL_SIZE_COLS}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" geometry_rows ${TERMINAL_SIZE_ROWS}

    # Font
    set_config_value "${LXTERMINAL_CONFIG_FILE}" fontname "${MONOSPACE_FONT}"

    # Others
    set_config_value "${LXTERMINAL_CONFIG_FILE}" scrollback ${TERMINAL_SCROLLBACK_SIZE}
    set_config_value "${LXTERMINAL_CONFIG_FILE}" cursorblinks true
    set_config_value "${LXTERMINAL_CONFIG_FILE}" cursorunderline true
fi

####################
### TEXT EDITORS ###
####################
if does-bin-exist "gedit"; then
    GEDIT_EDITOR_SCHEMA="org.gnome.gedit.preferences.editor"

    if [ "${TEXT_EDITOR_FONT}" != "${MONOSPACE_FONT}" ]; then
        set_gsetting "${GEDIT_EDITOR_SCHEMA}" editor-font "${TEXT_EDITOR_FONT}"
        set_gsetting "${GEDIT_EDITOR_SCHEMA}" use-default-font false
    else
        set_gsetting "${GEDIT_EDITOR_SCHEMA}" use-default-font true
    fi

    set_gsetting "${GEDIT_EDITOR_SCHEMA}" highlight-current-line false
    set_gsetting "${GEDIT_EDITOR_SCHEMA}" insert-spaces true
    set_gsetting "${GEDIT_EDITOR_SCHEMA}" restore-cursor-position true
    set_gsetting "${GEDIT_EDITOR_SCHEMA}" tabs-size "uint32 4"
fi
if does-bin-exist "pluma"; then
    PLUMA_SCHEMA="org.mate.pluma"

    if [ "${TEXT_EDITOR_FONT}" != "${MONOSPACE_FONT}" ]; then
        set_gsetting "${PLUMA_SCHEMA}" editor-font "${TEXT_EDITOR_FONT}"
        set_gsetting "${PLUMA_SCHEMA}" use-default-font false
    else
        set_gsetting "${PLUMA_SCHEMA}" use-default-font true
    fi

    set_gsetting "${PLUMA_SCHEMA}" auto-indent true
    set_gsetting "${PLUMA_SCHEMA}" bracket-matching true
    set_gsetting "${PLUMA_SCHEMA}" display-line-numbers true
    set_gsetting "${PLUMA_SCHEMA}" enable-space-drawer-space "show-trailing"
    set_gsetting "${PLUMA_SCHEMA}" enable-space-drawer-tab "show-all"
    set_gsetting "${PLUMA_SCHEMA}" insert-spaces true
    set_gsetting "${PLUMA_SCHEMA}" show-single-tab false
    set_gsetting "${PLUMA_SCHEMA}" toolbar-visible false
fi

##############
### Tiling ###
##############
#if [ -d "${ROOT_USR}/share/gnome-shell/extensions/wintile@nowsci.com/" ]; then
#    WINTILE_SCHEMA="org.gnome.shell.extensions.wintile"
#    set_gsetting "${WINTILE_SCHEMA}" use-minimize false
#fi

###########################
### TORRENT DOWNLOADERS ###
###########################
if does-bin-exist "fragments"; then
    #FRAGMENTS_SCHEMA="de.haeckerfelix.Fragments"
    FRAGMENTS_SETTINGS_FILE="${HOME_CONFIG}/fragments/settings.json"

    #set_gsetting "${FRAGMENTS_SCHEMA}" dark-mode ${DESKTOP_THEME_IS_DARK}

    set_json_value "${FRAGMENTS_SETTINGS_FILE}" '.["encryption"]' 1
    set_json_value "${FRAGMENTS_SETTINGS_FILE}" '.["download-dir"]' "${HOME}/Downloads"
    set_json_value "${FRAGMENTS_SETTINGS_FILE}" '.["incomplete-dir"]' "${HOME}/Downloads/.incomplete_fragments"
    set_json_value "${FRAGMENTS_SETTINGS_FILE}" '.["incomplete-dir-enabled"]' true
    set_json_value "${FRAGMENTS_SETTINGS_FILE}" '.["download-queue-size"]' 5
fi

########################
### TRANSLATION APPS ###
########################
if does-bin-exist "dialect"; then
    DIALECT_SCHEMA="com.github.gi_lom.dialect"

    set_gsetting "${DIALECT_SCHEMA}" dark-mode ${DESKTOP_THEME_IS_DARK}
    set_gsetting "${DIALECT_SCHEMA}" show-pronunciation true
    set_gsetting "${DIALECT_SCHEMA}" translate-accel 1
fi

#####################
### VIDEO PLAYERS ###
#####################
if does-bin-exist "totem"; then
    TOTEM_SCHEMA="org.gnome.totem"

    set_gsetting "${TOTEM_SCHEMA}" autoload-subtitles true
    set_gsetting "${TOTEM_SCHEMA}" subtitle-font "${SUBTITLES_FONT}"
fi

##############################
### WEATHER APPS & PLUGINS ###
##############################
if [ -d "${ROOT_USR}/share/gnome-shell/extensions/openweather-extension@jenslody.de" ]; then
    OPENWEATHER_GSEXT_SCHEMA="org.gnome.shell.extensions.openweather"

    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" pressure-unit "mbar"
    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" unit "celsius"
    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" wind-speed-unit "kph"
fi
if [ -d "${ROOT_USR}/share/gnome-shell/extensions/weather-extension@xeked.com" ]; then
    WEATHER_GSEXT_SCHEMA="org.gnome.shell.extensions.weather"

    set_gsetting "${WEATHER_GSEXT_SCHEMA}" show-comment-in-panel true
    set_gsetting "${WEATHER_GSEXT_SCHEMA}" city "[<(uint32 2, <('Cluj-Napoca', 'LRCL', true, [(0.81652319590691635, 0.41131593287109447)], [(0.81623231933377882, 0.41189770347066179)])>)>]"
fi

#######################
### Window Managers ###
#######################
if does-bin-exist "mutter"; then
    #set_gsetting "org.gnome.desktop.wm.preferences" button-layout ":minimize,maximize,close"
    set_gsetting "org.gnome.desktop.wm.preferences" button-layout "close,maximize,minimize:"
    set_gsetting "org.gnome.desktop.wm.preferences" theme "${GTK3_THEME}"
    set_gsetting "org.gnome.desktop.wm.preferences" titlebar-font "${TITLEBAR_FONT}"
fi

if does-bin-exist "openbox" && does-bin-exist "lxsession"; then
    OPENBOX_LXDE_RC="${HOME_REAL}/.config/openbox/lxde-rc.xml"

    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/name" "${GTK2_THEME}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/titleLayout" "LIMC"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='ActiveWindow']/name" "${TITLEBAR_FONT_NAME}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='ActiveWindow']/size" "${TITLEBAR_FONT_SIZE}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='ActiveWindow']/weight" "$(get_openbox_font_weight ${TITLEBAR_FONT_STYLE})"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='InactiveWindow']/name" "${TITLEBAR_FONT_NAME}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='InactiveWindow']/size" "${TITLEBAR_FONT_SIZE}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='InactiveWindow']/weight" "$(get_openbox_font_weight ${TITLEBAR_FONT_STYLE})"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuHeader']/name" "${MENUHEADER_FONT_NAME}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuHeader']/size" "${MENUHEADER_FONT_SIZE}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuHeader']/weight" "$(get_openbox_font_weight ${MENUHEADER_FONT_STYLE})"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuItem']/name" "${MENU_FONT_NAME}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuItem']/size" "${MENU_FONT_SIZE}"
    set_xml_node "${OPENBOX_LXDE_RC}" "//openbox_config/theme/font[@place='MenuItem']/weight" "$(get_openbox_font_weight ${MENU_FONT_STYLE})"
fi

if does-bin-exist "xfwm4"; then
    XFWM4_CONFIG_FILE="${HOME_REAL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"

    set_xml_node "${XFWM4_CONFIG_FILE}" "//channel/property[@name='general']/property[@name='button-layout']/@value" "CMH|"
    set_xml_node "${XFWM4_CONFIG_FILE}" "//channel/property[@name='general']/property[@name='theme']/@value" "${GTK2_THEME}"
    set_xml_node "${XFWM4_CONFIG_FILE}" "//channel/property[@name='general']/property[@name='title_font']/@value" "${TITLEBAR_FONT}"
fi