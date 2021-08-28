#!/bin/bash

USER_REAL=${SUDO_USER}
[ ! -n "${USER_REAL}" ] && USER_REAL=${USER}
HOME_REAL="/home/${USER_REAL}"

function set_config_value() {
    FILE="${1}"
    KEY="${2}"
    VALUE_RAW="${@:3}"

    if [ ! -f "${FILE}" ]; then
        # TODO: Handle directory creation
        touch "${FILE}"
    fi

    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    FILE_CONTENT=$(cat "${FILE}")

    # If the value is not already set
    if [ $(grep -c "^${KEY}=${VALUE}$" <<< "$FILE_CONTENT") == 0 ]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^${KEY}=.*$" <<< "$FILE_CONTENT") -gt 0 ]; then
            sed -i 's|^'"${KEY}"'=.*$|'"${KEY}"'='"${VALUE}"'|g' "$FILE"
        else
            LINE="$KEY=$VALUE"
            echo "$LINE" | sudo tee -a "$FILE" &>/dev/null
            #printf "$LINE\n" >> "$FILE"
        fi

        echo "${FILE} >>> ${KEY} = ${VALUE}"
    fi
}

function set_firefox_config_string() {
    set_firefox_config "${1}" "${2}" "\"${@:3}\""
}

function set_firefox_config() {
    PROFILE="${1}"
    KEY="${2}"
    VALUE_RAW="${@:3}"

    FILE="${HOME_REAL}/.mozilla/firefox/${PROFILE}/prefs.js"

    if [ ! -f "${FILE}" ]; then
        # TODO: Handle directory creation
        touch "${FILE}"
    fi

    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    FILE_CONTENT=$(cat "${FILE}")

    # If the value is not already set
    if [ $(grep -c "^user_pref(\"${KEY}\", *${VALUE});$" <<< "${FILE_CONTENT}") == 0 ] && \
       [ $(grep -c "^user_pref(\"${KEY}\", *\"${VALUE}\");$" <<< "${FILE_CONTENT}") == 0 ]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^user_pref(\"${KEY}.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
            sed -i '/^user_pref('"\"${KEY}"'/d' "${FILE}"
        fi

        LINE="user_pref(\"${KEY}\", ${VALUE});"
        echo "${LINE}" | sudo tee -a "${FILE}" &>/dev/null
        #printf "$LINE\n" >> "$FILE"

        echo "${FILE} >>> ${KEY} = ${VALUE}"
    fi
}

function set_json_value() {
    local FILE_PATH="${1}"

    if [ ! -f "${FILE_PATH}" ]; then
        return
    fi

    local PROPERTY="${2}"
    local VALUE=$(echo "${@:3}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    local FILE_CONTENT=$(cat "${FILE_PATH}" | grep -v "^[ \t]*//" | tr -d '\n' | sed 's/,[ \t]*}/ }/g')
    local CURRENT_VALUE=$(jq "${PROPERTY}" <<< ${FILE_CONTENT})

    if [ "${VALUE}" != "false" ] && [ "${VALUE}" != "true" ] && \
       ! [[ ${VALUE} =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        VALUE="\"${VALUE}\""
    fi

    # If the value is not already set
    if [ "${VALUE}" != "${CURRENT_VALUE}" ]; then
        jq "${PROPERTY}"'='"${VALUE}" <<< ${FILE_CONTENT} > "${FILE_PATH}"
        echo "${FILE_PATH} >>> ${PROPERTY} = ${VALUE}"
    fi
}

function set_xml_node() {
    FILE="${1}"
    NODE_RAW="${2}"
    VALUE_RAW="${@:3}"

    if [ ! -f "${FILE}" ]; then
        # TODO: Handle directory creation
        touch "${FILE}"
    fi

    NAMESPACE=$(cat "${FILE}" | grep "xmlns=" | sed 's/.*xmlns=\"\([^\"]*\)\".*/\1/g')
    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    if [ -z "${NAMESPACE}" ]; then
        NODE=${NODE_RAW}
    else
        NODE=$(echo "${NODE_RAW}" | sed 's/\/\([^\/]\)/\/x:\1/g')
    fi

    OLD_VALUE=$(xmlstarlet sel -N x="${NAMESPACE}" -t -m ''"${NODE}"'' -v n -n "${FILE}")

    if [ "${VALUE}" != "${OLD_VALUE}" ]; then
        echo "${FILE} >>> ${NODE_RAW} = ${VALUE}"
        xmlstarlet ed -L -N x="${NAMESPACE}" -u ''"${NODE}"'' -v ''"${VALUE}"'' "${FILE}"
    fi
}

function set_modprobe_option() {
    FILE="/etc/modprobe.d/hori-system-config.conf"
    MODULE="$1"
    KEY="$2"
    VALUE="$3"

    FILE_CONTENT=$(cat "$FILE")

    # If the option is not already set
    if [ $(grep -c "^options ${MODULE} ${KEY}=${VALUE}$" <<< "$FILE_CONTENT") == 0 ]; then
        # If the option key already exists (with a different value)
        if [ $(grep -c "^options ${MODULE} ${KEY}=.*$" <<< "$FILE_CONTENT") -gt 0 ]; then
            sed -i 's|^options '"${MODULE} ${KEY}"'=.*$|options '"${MODULE} ${KEY}"'='"${VALUE}"'|g' "$FILE"
        else
            LINE="options $MODULE $KEY=$VALUE"
            echo "$LINE" | sudo tee -a "$FILE"
            #printf "$LINE\n" >> "$FILE"
        fi

        echo "$FILE >>> $KEY=$VALUE"
    fi
}

function get_gsetting() {
    SCHEMA="${1}"
    PROPERTY="${2}"
    VALUE=$(gsettings get "${SCHEMA}" "${PROPERTY}" | sed "s/^'\(.*\)'$/\1/g")

    echo "${VALUE}"
}

function set_gsetting() {
    SCHEMA="${1}"
    PROPERTY="${2}"
    VALUE="${@:3}"

    CURRENT_VALUE=$(get_gsetting "${SCHEMA}" "${PROPERTY}")

    if [ "${CURRENT_VALUE}" != "${VALUE}" ] && \
       [ "${CURRENT_VALUE}" != "'${VALUE}'" ]; then
        echo "GSettings >>> ${SCHEMA}.${PROPERTY}=${VALUE}"
        gsettings set "${SCHEMA}" "${PROPERTY}" "${VALUE}"
    fi
}

function get_openbox_font_weight() {
    [ "$@" == "Bold" ] && echo "Bold" || echo "Normal"
}

### BLUETOOTH
# Xbox One Controller
#echo "options bluetooth disable_ertm=1" | tee --append /etc/modprobe.d/xbox_bt.conf

if [ "${ARCH}" == "x86_64" ]; then
    USING_NVIDIA_GPU=$(lspci | grep VGA | grep -c "NVIDIA")
else
    USING_NVIDIA_GPU=0
fi

# SCREEN RESOLUTION
SCREEN_RESOLUTION=$(xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*\([0-9]*x[0-9]*\) pixels.*/\1/g')
SCREEN_RESOLUTION_H=$(echo ${SCREEN_RESOLUTION} | awk -F "x" '{print $1}')
SCREEN_RESOLUTION_V=$(echo ${SCREEN_RESOLUTION} | awk -F "x" '{print $2}')

# THEMES
GTK_THEME="ZorinGrey-Dark"
GTK_THEME_VARIANT="dark"
GTK2_THEME="${GTK_THEME}"
GTK3_THEME="${GTK_THEME}"
ICON_THEME="Papirus-Dark"
ICON_THEME_FOLDER_COLOUR="grey"
CURSOR_THEME="Vimix-white-cursors"

[ "${GTK_THEME_VARIANT}" == "dark" ] && GTK_THEME_IS_DARK=true      || GTK_THEME_IS_DARK=false
[ "${GTK_THEME_VARIANT}" == "dark" ] && GTK_THEME_IS_DARK_BINARY=1  || GTK_THEME_IS_DARK_BINARY=0

GTK_THEME_BG_COLOUR="#202020"

# FONT FACES
INTERFACE_FONT_NAME="Sans"
INTERFACE_FONT_STYLE="Regular"
INTERFACE_FONT_SIZE="12"
[ ${SCREEN_RESOLUTION_V} -lt 1080 ] && INTERFACE_FONT_SIZE=10

DOCUMENT_FONT_NAME=${INTERFACE_FONT_NAME}
DOCUMENT_FONT_STYLE=${INTERFACE_FONT_STYLE}
DOCUMENT_FONT_SIZE=${INTERFACE_FONT_SIZE}

TITLEBAR_FONT_NAME=${INTERFACE_FONT_NAME}
TITLEBAR_FONT_STYLE="Bold"
TITLEBAR_FONT_SIZE=${INTERFACE_FONT_SIZE}

MENU_FONT_NAME=${TITLEBAR_FONT_NAME}
MENU_FONT_STYLE=${INTERFACE_FONT_STYLE}
MENU_FONT_SIZE=${TITLEBAR_FONT_SIZE}

MENUHEADER_FONT_NAME=${MENU_FONT_NAME}
MENUHEADER_FONT_STYLE=${TITLEBAR_FONT_STYLE}
MENUHEADER_FONT_SIZE=${MENU_FONT_SIZE}

MONOSPACE_FONT_NAME="Droid Sans"
MONOSPACE_FONT_STYLE="Mono"
MONOSPACE_FONT_SIZE=13
[ ${SCREEN_RESOLUTION_V} -lt 1080 ] && MONOSPACE_FONT_SIZE=12

SUBTITLES_FONT_NAME=${INTERFACE_FONT_NAME}
SUBTITLES_FONT_STYLE="Bold"
SUBTITLES_FONT_SIZE=20
[ ${SCREEN_RESOLUTION_V} -lt 1080 ] && SUBTITLES_FONT_SIZE=17

TEXT_EDITOR_FONT_NAME=${MONOSPACE_FONT_NAME}
TEXT_EDITOR_FONT_STYLE=${MONOSPACE_FONT_STYLE}
TEXT_EDITOR_FONT_SIZE=12
[ ${SCREEN_RESOLUTION_V} -lt 1080 ] && TEXT_EDITOR_FONT_SIZE=11

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
TERMINAL_SIZE_COLS=100
TERMINAL_SIZE_ROWS=32
TERMINAL_SCROLLBACK_SIZE=15000
TERMINAL_BOLD_TEXT_IS_BRIGHT=false

if [ ${SCREEN_RESOLUTION_V} -lt 1080 ]; then
    TERMINAL_SIZE_COLS=80
    TERMINAL_SIZE_ROWS=24
fi

if [[ "${ICON_THEME}" == *"Papirus"* ]]; then
    CURRENT_PAPIRUS_FOLDER_COLOUR=$(papirus-folders -l -t "${ICON_THEME}" | grep ">" | sed 's/ *> *//g')

    if [ "${CURRENT_PAPIRUS_FOLDER_COLOUR}" != "${ICON_THEME_FOLDER_COLOUR}" ]; then
        papirus-folders -t "${ICON_THEME}" -C "${ICON_THEME_FOLDER_COLOUR}"
    fi
fi

if [ $USING_NVIDIA_GPU = 1 ]; then
    set_modprobe_option nvidia-drm modset 1
fi

set_modprobe_option bluetooth disable_ertm 1    # Xbox One Controller Pairing
set_modprobe_option btusb enable_autosuspend n  # Xbox One Controller Connecting, possibly other devices as well

if [ -f "/usr/bin/pulseaudio" ]; then
    set_config_value "/etc/pulse/daemon.conf" resample-method speex-float-10
fi

if [ -d "/usr/bin/openal-info" ]; then
    set_config_value "${HOME_REAL}/.alsoftrc" hrtf true
fi

if [ -f "/etc/default/grub" ]; then
    GRUB_CONFIG_FILE="/etc/default/grub"

    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_TIMEOUT" 1
    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_DISABLE_RECOVERY" true
fi

if [ -f "/usr/bin/gnome-contacts" ]; then
    set_gsetting "org.gnome.Contacts" sort-on-surname true
fi

if [ -f "/usr/bin/gnome-screenshot" ]; then
    set_gsetting "org.gnome.gnome-screenshot" last-save-directory "${HOME}/Pictures"
fi

if [ -f "/usr/bin/gnome-shell" ]; then
    if [ "${ARCH}" == "aarch64" ]; then
        set_gsetting "org.gnome.settings-daemon.plugins.remote-display" active false
        set_gsetting "org.gnome.desktop.interface" enable-animations false
    fi

    set_gsetting "org.gnome.desktop.datetime" automatic-timezone true

    set_gsetting "org.gnome.desktop.interface" clock-show-weekday true
    set_gsetting "org.gnome.desktop.interface" enable-hot-corners false

    set_gsetting "org.gnome.desktop.privacy" old-files-age "uint32 14"
    set_gsetting "org.gnome.desktop.privacy" remove-old-temp-files "true"
    set_gsetting "org.gnome.desktop.privacy" remove-old-trash-files "true"

    set_gsetting "org.gnome.desktop.peripherals.touchpad" click-method "default"
    set_gsetting "org.gnome.desktop.peripherals.touchpad" tap-to-click "true"

    #set_gsetting "org.gnome.desktop.wm.preferences" button-layout ":minimize,maximize,close"
    set_gsetting "org.gnome.desktop.wm.preferences" button-layout "close,maximize,minimize:"
    set_gsetting "org.gnome.desktop.wm.preferences" theme "${GTK3_THEME}"
    set_gsetting "org.gnome.desktop.wm.preferences" titlebar-font "${TITLEBAR_FONT}"

    set_gsetting "org.gnome.desktop.sound" allow-volume-above-100-percent "true"

    set_gsetting "org.gnome.desktop.interface" clock-show-date "true"
    set_gsetting "org.gnome.desktop.interface" document-font-name "${DOCUMENT_FONT}"
    set_gsetting "org.gnome.desktop.interface" font-name "${INTERFACE_FONT}"
    set_gsetting "org.gnome.desktop.interface" gtk-theme "${GTK_THEME}"
    set_gsetting "org.gnome.desktop.interface" icon-theme "${ICON_THEME}"
    set_gsetting "org.gnome.desktop.interface" monospace-font-name "${MONOSPACE_FONT}"
    set_gsetting "org.gnome.desktop.interface" show-battery-percentage "true"

    set_gsetting "org.gnome.desktop.peripherals.touchpad" disable-while-typing false

    set_gsetting "org.gnome.mutter" attach-modal-dialogs false
    set_gsetting "org.gnome.mutter" center-new-windows true

    set_gsetting org.gnome.settings-daemon.plugins.housekeeping free-size-gb-no-notify 2
    set_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true

    set_gsetting "org.gnome.shell.overrides" attach-modal-dialogs false
fi

if [ -d "/usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/" ]; then
    set_gsetting "org.gnome.shell.extensions.user-theme" name "${GTK_THEME}"
fi

if [ -d "/usr/share/gnome-shell/extensions/multi-monitors-add-on@spin83" ]; then
    set_gsetting "org.gnome.shell.extensions.multi-monitors-add-on" show-indicator false
fi

if [ -f "/usr/bin/panther_launcher" ]; then
    set_gsetting "org.rastersoft.panther" icon-size 48
    set_gsetting "org.rastersoft.panther" use-category true
fi

ENVIRONMENT_VARS_FILE="/etc/environment"
set_config_value "${ENVIRONMENT_VARS_FILE}" QT_QPA_PLATFORMTHEME "gtk3"

GTK2_CONFIG_FILE="${HOME_REAL}/.gtkrc-2.0"
GTK3_CONFIG_FILE="${HOME_REAL}/.config/gtk-3.0/settings.ini"
GTK4_CONFIG_FILE="${HOME_REAL}/.config/gtk-4.0/settings.ini"

set_config_value "${GTK2_CONFIG_FILE}" gtk-theme-name "${GTK2_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-cursor-theme-name "${ICON_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-button-images 0
set_config_value "${GTK2_CONFIG_FILE}" gtk-menu-images 0
set_config_value "${GTK2_CONFIG_FILE}" gtk-toolbar-style GTK_TOOLBAR_ICONS

if [ -f "${GTK3_CONFIG_FILE}" ]; then
    set_config_value "${GTK3_CONFIG_FILE}" gtk-application-prefer-dark-theme ${GTK_THEME_IS_DARK_BINARY}
    set_config_value "${GTK3_CONFIG_FILE}" gtk-theme-name "${GTK_THEME}"
    set_config_value "${GTK3_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
    set_config_value "${GTK3_CONFIG_FILE}" gtk-cursor-theme-name "${CURSOR_THEME}"
    set_config_value "${GTK3_CONFIG_FILE}" gtk-button-images 0
    set_config_value "${GTK3_CONFIG_FILE}" gtk-menu-images 0
    set_config_value "${GTK3_CONFIG_FILE}" gtk-toolbar-style GTK_TOOLBAR_ICONS
fi

if [ -f "${GTK4_CONFIG_FILE}" ]; then
    set_config_value "${GTK3_CONFIG_FILE}" gtk-application-prefer-dark-theme ${GTK_THEME_IS_DARK_BINARY}
fi

if [ -f "${HOME_REAL}/.config/lxsession/LXDE/desktop.conf" ]; then
    LXSESSION_CONFIG_FILE="${HOME_REAL}/.config/lxsession/LXDE/desktop.conf"

    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/ThemeName "${GTK_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/IconThemeName "${ICON_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" sNet/CursorThemeName "${CURSOR_THEME}"
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/ButtonImages 0
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/MenuImages 0
    set_config_value "${LXSESSION_CONFIG_FILE}" iGtk/ToolbarStyle 0
fi

if [ -f "/usr/bin/openbox" ] && [ -f "/usr/bin/lxsession" ]; then
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

########################
### ARCHIVE MANAGERS ###
########################
if [ -f "/usr/bin/file-roller" ]; then
    set_gsetting "org.gnome.FileRoller.General" compression-level "maximum"
fi

###################
### CALCULATORS ###
###################
if [ -f "/usr/bin/gnome-calculator" ]; then
    set_gsetting "org.gnome.calculator" show-thousands true
fi
if [ -f "/usr/bin/mate-calc" ]; then
    set_gsetting "org.mate.calc" show-thousands true
fi

#################
### CHAT APPS ###
#################
if [ -f "/usr/bin/discord" ]; then
    set_json_value "${HOME_REAL}/.config/discord/settings.json" '.BACKGROUND_COLOR' ${GTK_THEME_BG_COLOUR}
fi
if [ -f "/usr/bin/telegram-desktop" ]; then
    set_config_value "${ENVIRONMENT_VARS_FILE}" TDESKTOP_I_KNOW_ABOUT_GTK_INCOMPATIBILITY "1"
fi
if [ -f "/usr/bin/whatsapp-for-linux" ]; then
    WAPP_CONFIG_FILE="${HOME_REAL}/.config/whatsapp-for-linux/settings.conf"

    # Disable tray because tray icons don't work and the window becomes inaccessible
    set_config_value "${WAPP_CONFIG_FILE}" close_to_tray false
    set_config_value "${WAPP_CONFIG_FILE}" start_in_tray false
fi

#############################
### CONFIGURATION EDITORS ###
#############################
if [ -f "/usr/bin/dconf-editor" ]; then
    set_gsetting ca.desrt.dconf-editor.Settings show-warning false
fi

#############
### DOCKS ###
#############
if [ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/" ]; then
    DTD_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

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
fi
if [ -f "/usr/bin/plank" ]; then
    PLANK_SCHEMA="net.launchpad.plank.docks.dock1"

    set_gsetting "${PLANK_SCHEMA}" theme "Gtk+"
    set_gsetting "${PLANK_SCHEMA}" hide-mode "window-dodge"
fi

########################
### DOCUMENT VIEWERS ###
########################
if [ -f "/usr/bin/epdfview" ]; then
    EPDFVIEW_CONFIG_FILE="${HOME_REAL}/.config/epdfview/main.conf"

    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToFit false
    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToWidth true
    set_config_value "${EPDFVIEW_CONFIG_FILE}" browser "chromium %s"
fi

#####################
### FILE MANAGERS ###
#####################
if [ -f "/usr/bin/nautilus" ]; then
    NAUTILUS_SCHEMA="org.gnome.nautilus"

    set_gsetting "${NAUTILUS_SCHEMA}.icon-view" default-zoom-level "small"
    set_gsetting "${NAUTILUS_SCHEMA}.list-view" default-zoom-level "small"
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-create-link true
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-delete-permanently true
    set_gsetting "${NAUTILUS_SCHEMA}.window-state" sidebar-width 240
fi
if [ -f "/usr/bin/pcmanfm" ]; then
    PCMANFM_CONFIG_FILE="${HOME_REAL}/.config/pcmanfm/LXDE/pcmanfm.conf"

    set_config_value "${PCMANFM_CONFIG_FILE}" always_show_tabs 0
    set_config_value "${PCMANFM_CONFIG_FILE}" max_tab_chars 48
    set_config_value "${PCMANFM_CONFIG_FILE}" pathbar_mode_buttons 1
    set_config_value "${PCMANFM_CONFIG_FILE}" toolbar "navigation;"
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
if [ -f "/usr/bin/firefox" ]; then
    FIREFOX_PROFILES_INI_FILE="${HOME_REAL}/.mozilla/firefox/profiles.ini"
    FIREFOX_PROFILE_ID=$(grep "^Path=" "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

    set_firefox_config "${FIREFOX_PROFILE_ID}" "beacon.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.anchor_color" "#00BCD4"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.section.highlights" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.snippets" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.topsites" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.safebrowsing.downloads.remote.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.search.region" "RO"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.send_pings" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.delayHidingAudioPlayingIconMS" "0"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.insertAfterCurrent" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.tabMinWidth" "0"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.warnOnClose" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.translation.detectLanguage" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.underline_anchors" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.uidensity" "1"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.autoFill" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.urlbar.speculativeConnect.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "dom.event.clipboardevents.enabled" "true" # Fix for Google's office suite
    set_firefox_config "${FIREFOX_PROFILE_ID}" "extensions.screenshots.disabled" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "findbar.highlightAll" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "full-screen-api.warning.timeout" "0"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "media.autoplay.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "media.navigator.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.IDN_show_punycode" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "privacy.trackingprotection.enabled" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "security.insecure_connection_text.enabled" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "security.sandbox.content.level" "0" # iHD fix
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.tabbox.switchByScrolling" "true"

    # Appearance
    set_firefox_config "${FIREFOX_PROFILE_ID}" "devtools.theme" ${GTK_THEME_VARIANT}
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.in-content.dark-mode" ${GTK_THEME_IS_DARK}
    set_firefox_config "${FIREFOX_PROFILE_ID}" "ui.systemUsesDarkTheme" ${GTK_THEME_IS_DARK}

    set_firefox_config "${FIREFOX_PROFILE_ID}" "widget.disable-native-theme-for-content" "true"

    # Useless features
    set_firefox_config "${FIREFOX_PROFILE_ID}" "extensions.pocket.enabled" "false"

    # Telemetry
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.telemetry" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.newtabpage.activity-stream.feeds.telemetry" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.ping-centre.telemetry" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.archive.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.bhrPing.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.firstShutdownPing.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.hybridContent.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.newProfilePing.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.reportingpolicy.firstRun" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.shutdownPingSender.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.unified" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "toolkit.telemetry.updatePing.enabled" "false"

    # DNS Prefetching
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dns.disablePrefetch" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.dns.disablePrefetchFromHTTPS" "true"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.predictor.enabled" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.predictor.enable-prefetch" "false"
    set_firefox_config "${FIREFOX_PROFILE_ID}" "network.prefetch-next" "false"

    # Fingerprinting
    #set_firefox_config "${FIREFOX_PROFILE_ID}" privacy.resistFingerprinting true
    set_firefox_config "${FIREFOX_PROFILE_ID}" privacy.trackingprotection.fingerprinting.enabled true
fi

############
### IDEs ###
############
if [ -f "/usr/bin/code" ]; then
    VSCODE_CONFIG_FILE="${HOME}/.config/Code/User/settings.json"

    # Appearance
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.codeLens"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.roundedSelection"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.maxColumn"]' 100
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.renderCharacters"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectActivityBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectTabActiveBorder"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.showColorInStatusBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.autoDetectColorScheme"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.menuBarVisibility"]' "toggle"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.colorTheme"]' "Default Dark+"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.iconTheme"]' "seti"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.drawBoldTextInBrightColors"]' ${TERMINAL_BOLD_TEXT_IS_BRIGHT}

    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.autoClosingBrackets"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDragAndDrop"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDelete"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autofetch"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.scrollback"]' ${TERMINAL_SCROLLBACK_SIZE}
fi

########################
### KEYBOARD & MOUSE ###
########################
if [ -f "/usr/bin/gnome-shell" ]; then
    # Keyboard
    set_gsetting org.gnome.desktop.peripherals.keyboard numlock-state true

    # Keybindings
    set_gsetting org.gnome.settings-daemon.plugins.media-keys logout "['<Alt>l']"
    set_gsetting org.gnome.desktop.wm.keybindings panel-run-dialog "['<Super>r']"
    set_gsetting org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
    set_gsetting org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
    set_gsetting org.gnome.desktop.wm.keybindings switch-group "['<Super>Tab']"
    set_gsetting org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Super>Tab']"
    set_gsetting org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

    # Mouse
    set_gsetting org.gnome.desktop.peripherals.mouse accel-profile "flat"
fi

############
### MAPS ###
############
if [ -f "/usr/bin/gnome-maps" ]; then
    set_gsetting org.gnome.Maps night-mode true
fi

###################
### NIGHT LIGHT ###
###################
if [ -f "/usr/bin/gnome-shell" ]; then
    set_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true
fi

########################
### POWER MANAGEMENT ###
########################
if [ -f "/usr/bin/gnome-shell" ]; then
    GNOME_POWER_SCHEMA="org.gnome.settings-daemon.plugins.power"

    set_gsetting "${GNOME_POWER_SCHEMA}" idle-dim true
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-ac-timeout 1800
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-battery-timeout 900
fi

#################
### TERMINALS ###
#################
if [ -f "/usr/bin/gnome-terminal" ]; then
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
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" cursor-shape "ibeam"
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" scrollback-lines ${TERMINAL_SCROLLBACK_SIZE}
    set_gsetting "${GNOME_TERMINAL_PROFILE_SCHEMA}" visible-name "NuciTerm"
fi
if [ -f "/usr/bin/lxterminal" ]; then
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
if [ -f "/usr/bin/gedit" ]; then
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
if [ -f "/usr/bin/pluma" ]; then
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

###########################
### TORRENT DOWNLOADERS ###
###########################
if [ -f "/usr/bin/fragments" ]; then
    FRAGMENTS_SCHEMA="de.haeckerfelix.Fragments"

    set_gsetting "${FRAGMENTS_SCHEMA}" download-folder "${HOME}/Downloads"
    set_gsetting "${FRAGMENTS_SCHEMA}" enable-dark-theme ${GTK_THEME_IS_DARK}
    set_gsetting "${FRAGMENTS_SCHEMA}" encryption-mode 1
    set_gsetting "${FRAGMENTS_SCHEMA}" max-downloads 5
fi

########################
### TRANSLATION APPS ###
########################
if [ -f "/usr/bin/dialect" ]; then
    DIALECT_SCHEMA="com.github.gi_lom.dialect"

    set_gsetting "${DIALECT_SCHEMA}" dark-mode ${GTK_THEME_IS_DARK}
    set_gsetting "${DIALECT_SCHEMA}" show-pronunciation true
    set_gsetting "${DIALECT_SCHEMA}" translate-accel 1
fi

#####################
### VIDEO PLAYERS ###
#####################
if [ -f "/usr/bin/totem" ]; then
    TOTEM_SCHEMA="org.gnome.totem"

    set_gsetting "${TOTEM_SCHEMA}" autoload-subtitles "true"
    set_gsetting "${TOTEM_SCHEMA}" subtitle-font "${SUBTITLES_FONT}"
fi

#######################
### Weather Plugins ###
#######################
if [ -d "/usr/share/gnome-shell/extensions/openweather-extension@jenslody.de" ]; then
    OPENWEATHER_GSEXT_SCHEMA="org.gnome.shell.extensions.openweather"

    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" pressure-unit "bar"
    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" unit "celsius"
    set_gsetting "${OPENWEATHER_GSEXT_SCHEMA}" wind-speed-unit "kph"
fi
if [ -d "/usr/share/gnome-shell/extensions/weather-extension@xeked.com" ]; then
    WEATHER_GSEXT_SCHEMA="org.gnome.shell.extensions.weather"

    set_gsetting "${WEATHER_GSEXT_SCHEMA}" show-comment-in-panel true
    set_gsetting "${WEATHER_GSEXT_SCHEMA}" city "[<(uint32 2, <('Cluj-Napoca', 'LRCL', true, [(0.81652319590691635, 0.41131593287109447)], [(0.81623231933377882, 0.41189770347066179)])>)>]"
fi
