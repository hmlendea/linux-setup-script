#!/bin/bash
source "scripts/_common.sh"

function set_config_value() {
    local SEPARATOR="="

    if [ "${1}" == "--separator" ]; then
        shift
        SEPARATOR="${1}"
        shift
    fi

    local FILE_PATH="${1}"
    local KEY="${2}"
    local VALUE_RAW="${@:3}"

    if [ ! -f "${FILE_PATH}" ]; then
        # TODO: Handle directory creation
        touch "${FILE_PATH}"
    fi

    #local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    local VALUE=$VALUE_RAW
    local FILE_CONTENT=$(cat "${FILE_PATH}")

    # If the value is not already set
    if [ $(grep -c "^${KEY}${SEPARATOR}${VALUE}$" <<< "$FILE_CONTENT") == 0 ]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^${KEY}${SEPARATOR}.*$" <<< "$FILE_CONTENT") -gt 0 ]; then
            if [ -w "${FILE_PATH}" ]; then
                sed -i 's|^'"${KEY}${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
            else
                sudo sed -i 's|^'"${KEY}${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
            fi
        else
            file-append-line "${FILE_PATH}" "${KEY}${SEPARATOR}${VALUE}"
        fi

        echo "${FILE_PATH} >>> ${KEY} ${SEPARATOR} ${VALUE}"
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

        file-append-line "${FILE}" "user_pref(\"${KEY}\", ${VALUE});"

        echo "${FILE} >>> ${KEY} = ${VALUE}"
    fi
}

function set_json_value() {
    local FILE_PATH="${1}"

    [ ! $(does-bin-exist "jq") ] && return
    [ ! -f "${FILE_PATH}" ] && return

    local PROPERTY="${2}"
    local VALUE=$(echo "${@:3}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    local FILE_CONTENT=$(cat "${FILE_PATH}" | grep -v "^[ \t]*//" | tr -d '\n' | sed 's/,[ \t]*}/ }/g')
    local CURRENT_VALUE=$(jq "${PROPERTY}" <<< ${FILE_CONTENT})

    VALUE=$(echo "${VALUE}" | sed 's/\\\././g') # dirty fix

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

function set_json_value_root() {
    if ${HAS_SU_PRIVILEGES}; then
        local FUNCTION_DECLARATIONS="$(declare -f set_json_value); $(declare -f does-bin-exist)"
        sudo bash -c "${FUNCTION_DECLARATIONS}; set_json_value \"${1}\" '${2}' \"${3}\""
    fi
}

function set_xml_node() {
    FILE="${1}"
    NODE_RAW="${2}"
    VALUE_RAW="${@:3}"

    ! $(does-bin-exist "xmlstarlet") && return
    [ ! -f "${FILE}" ] && return

    NAMESPACE=$(cat "${FILE}" | grep "xmlns=" | sed 's/.*xmlns=\"\([^\"]*\)\".*/\1/g')
    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    if [ -z "${NAMESPACE}" ]; then
        NODE=${NODE_RAW}
    else
        NODE=$(echo "${NODE_RAW}" | sed 's/\/\([^\/]\)/\/x:\1/g')
    fi

    OLD_VALUE=$(xmlstarlet sel -N x="${NAMESPACE}" -t -v ''"${NODE}"'' -n "${FILE}")

    if [ "${VALUE}" != "${OLD_VALUE}" ]; then
        echo "${FILE} >>> ${NODE_RAW} = ${VALUE}"
        xmlstarlet ed -L -N x="${NAMESPACE}" -u ''"${NODE}"'' -v ''"${VALUE}"'' "${FILE}"
    fi
}

function set_modprobe_option() {
    FILE="${ROOT_ETC}/modprobe.d/hori-system-config.conf"
    MODULE="${1}"
    KEY="${2}"
    VALUE="${3}"

    FILE_CONTENT=$(cat "${FILE}")

    # If the option is not already set
    if [ $(grep -c "^options ${MODULE} ${KEY}=${VALUE}$" <<< "${FILE_CONTENT}") == 0 ]; then
        # If the option key already exists (with a different value)
        if [ $(grep -c "^options ${MODULE} ${KEY}=.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
            sed -i 's|^options '"${MODULE} ${KEY}"'=.*$|options '"${MODULE} ${KEY}"'='"${VALUE}"'|g' "${FILE}"
        else
            file-append-line "${FILE}" "options ${MODULE} ${KEY}=${VALUE}"
        fi

        echo "${FILE} >>> ${KEY}=${VALUE}"
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

    $(does-bin-exist "gsettings") && return

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
    $(does-bin-exist "lspci") && USING_NVIDIA_GPU=$(lspci | grep VGA | grep -c "NVIDIA")
else
    USING_NVIDIA_GPU=0
fi

IS_SERVER=false
SCREEN_RESOLUTION_H=0
SCREEN_RESOLUTION_V=0

if $(does-bin-exist "xdpyinfo"); then
    SCREEN_RESOLUTION=$(xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*\([0-9]*x[0-9]*\) pixels.*/\1/g')

    if [ -n "${SCREEN_RESOLUTION}" ]; then
        IS_SERVER=false
        SCREEN_RESOLUTION_H=$(echo ${SCREEN_RESOLUTION} | awk -F "x" '{print $1}')
        SCREEN_RESOLUTION_V=$(echo ${SCREEN_RESOLUTION} | awk -F "x" '{print $2}')
    else
        IS_SERVER=true
    fi
fi

[ ${SCREEN_RESOLUTION_V} -le 2160 ] && ZOOM_LEVEL=1.15
[ ${SCREEN_RESOLUTION_V} -le 1440 ] && ZOOM_LEVEL=1.10
[ ${SCREEN_RESOLUTION_V} -le 1080 ] && ZOOM_LEVEL=1.00

# THEMES
GTK_THEME="ZorinGrey-Dark"
GTK_THEME_VARIANT="dark"
GTK2_THEME="${GTK_THEME}"
GTK3_THEME="${GTK_THEME}"
ICON_THEME="Papirus-Dark"
ICON_THEME_FOLDER_COLOUR="grey"
CURSOR_THEME="Vimix-white-cursors"

if [ "${GTK_THEME_VARIANT}" == "dark" ]; then
    GTK_THEME_IS_DARK=true
    GTK_THEME_IS_DARK_BINARY=1
else
    GTK_THEME_IS_DARK=false
    GTK_THEME_IS_DARK_BINARY=0
fi

GTK_THEME_BG_COLOUR="#202020"

# FONT FACES
INTERFACE_FONT_NAME="Sans"
INTERFACE_FONT_STYLE="Regular"
INTERFACE_FONT_SIZE=11
[ ${SCREEN_RESOLUTION_V} -lt 1440 ] && INTERFACE_FONT_SIZE=10

DOCUMENT_FONT_NAME=${INTERFACE_FONT_NAME}
DOCUMENT_FONT_STYLE=${INTERFACE_FONT_STYLE}
DOCUMENT_FONT_SIZE=${INTERFACE_FONT_SIZE}

TITLEBAR_FONT_NAME=${INTERFACE_FONT_NAME}
TITLEBAR_FONT_STYLE="Bold"
TITLEBAR_FONT_SIZE=12
[ ${SCREEN_RESOLUTION_V} -lt 1080 ] && TITLEBAR_FONT_SIZE=11

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
TERMINAL_SIZE_COLS=128
TERMINAL_SIZE_ROWS=32
TERMINAL_SCROLLBACK_SIZE=15000
TERMINAL_BOLD_TEXT_IS_BRIGHT=false


if [ ${SCREEN_RESOLUTION_V} -lt 1440 ]; then
    TERMINAL_SIZE_COLS=100
elif [ ${SCREEN_RESOLUTION_V} -lt 1080 ]; then
    TERMINAL_SIZE_COLS=80
    TERMINAL_SIZE_ROWS=24
fi

if [ ! ${IS_SERVER} ]; then
    if [[ "${ICON_THEME}" == *"Papirus"* ]]; then
        CURRENT_PAPIRUS_FOLDER_COLOUR=$(papirus-folders -l -t "${ICON_THEME}" | grep ">" | sed 's/ *> *//g')

        if [ "${CURRENT_PAPIRUS_FOLDER_COLOUR}" != "${ICON_THEME_FOLDER_COLOUR}" ]; then
            papirus-folders -t "${ICON_THEME}" -C "${ICON_THEME_FOLDER_COLOUR}"
        fi
    fi
fi

if [ -d "${ROOT_ETC}/modprobe.d" ]; then
    if [ $USING_NVIDIA_GPU = 1 ]; then
        set_modprobe_option nvidia-drm modset 1
    fi

    set_modprobe_option bluetooth disable_ertm 1    # Xbox One Controller Pairing
    set_modprobe_option btusb enable_autosuspend n  # Xbox One Controller Connecting, possibly other devices as well

    set_gsetting org.gtk.Settings.FileChooser startup-mode 'cwd'
fi

if [ -f "${ROOT_ETC}/default/grub" ]; then
    GRUB_CONFIG_FILE="${ROOT_ETC}/default/grub"

    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_DISABLE_RECOVERY" true
    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_TIMEOUT" 1
    set_config_value "${GRUB_CONFIG_FILE}" "GRUB_THEME" "${ROOT_USR}/share/grub/themes/Vimix/theme.txt"
fi

if $(does-bin-exist "gnome-shell"); then
    if [ "${ARCH}" == "aarch64" ]; then
        set_gsetting "org.gnome.settings-daemon.plugins.remote-display" active false
        set_gsetting "org.gnome.desktop.interface" enable-animations false
    fi

    set_gsetting "org.gnome.desktop.datetime" automatic-timezone true

    set_gsetting "org.gnome.desktop.interface" clock-show-weekday true
    set_gsetting "org.gnome.desktop.interface" enable-hot-corners false
    set_gsetting "org.gnome.desktop.interface" toolbar-icons-size 'small'
    set_gsetting "org.gnome.desktop.interface" toolbar-style 'icons'

    set_gsetting "org.gnome.desktop.privacy" old-files-age "uint32 14"
    set_gsetting "org.gnome.desktop.privacy" remove-old-temp-files "true"
    set_gsetting "org.gnome.desktop.privacy" remove-old-trash-files "true"

    set_gsetting "org.gnome.desktop.peripherals.touchpad" click-method "default"
    set_gsetting "org.gnome.desktop.peripherals.touchpad" tap-to-click "true"

    #set_gsetting "org.gnome.desktop.wm.preferences" button-layout ":minimize,maximize,close"
    set_gsetting "org.gnome.desktop.wm.preferences" button-layout "close,maximize,minimize:"
    set_gsetting "org.gnome.desktop.wm.preferences" theme "${GTK3_THEME}"
    set_gsetting "org.gnome.desktop.wm.preferences" titlebar-font "${TITLEBAR_FONT}"

    set_gsetting "org.gnome.desktop.interface" clock-show-date "true"
    set_gsetting "org.gnome.desktop.interface" cursor-theme "${CURSOR_THEME}"
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

    set_gsetting org.gnome.SessionManager logout-prompt false

    set_gsetting "org.gnome.shell.overrides" attach-modal-dialogs false
fi

if [ -d "${ROOT_USR}/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/" ]; then
    set_gsetting "org.gnome.shell.extensions.user-theme" name "${GTK_THEME}"
fi

if [ -d "${ROOT_USR}/share/gnome-shell/extensions/multi-monitors-add-on@spin83" ]; then
    set_gsetting "org.gnome.shell.extensions.multi-monitors-add-on" show-indicator false
fi

if $(does-bin-exist "panther_launcher"); then
    set_gsetting "org.rastersoft.panther" icon-size 48
    set_gsetting "org.rastersoft.panther" use-category true
fi

ENVIRONMENT_VARS_FILE="${ROOT_ETC}/environment"
set_config_value "${ENVIRONMENT_VARS_FILE}" QT_QPA_PLATFORMTHEME "gtk3"

GTK2_CONFIG_FILE="${HOME_REAL}/.gtkrc-2.0"
GTK2_FILECHOOSER_CONFIG_FILE="${HOME_REAL}/.config/gtk-2.0/filechooser.ini"
GTK3_CONFIG_FILE="${HOME_REAL}/.config/gtk-3.0/settings.ini"
GTK4_CONFIG_FILE="${HOME_REAL}/.config/gtk-4.0/settings.ini"

set_config_value "${GTK2_CONFIG_FILE}" gtk-theme-name "${GTK2_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-icon-theme-name "${ICON_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-cursor-theme-name "${CURSOR_THEME}"
set_config_value "${GTK2_CONFIG_FILE}" gtk-button-images 0
set_config_value "${GTK2_CONFIG_FILE}" gtk-menu-images 0
set_config_value "${GTK2_CONFIG_FILE}" gtk-toolbar-style GTK_TOOLBAR_ICONS

if [ -f "${GTK2_FILECHOOSER_CONFIG_FILE}" ]; then
    set_config_value "${GTK2_FILECHOOSER_CONFIG_FILE}" StartupMode=cwd
fi

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

    LXDE_WM=""

    if [ -f "${ROOT_USR_BIN}/openbox" ]; then
        LXDE_WM="openbox-lxde"
    elif [ -f "${ROOT_USR_BIN}/mutter" ]; then
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

if $(does-bin-exist "openbox") && $(does-bin-exist "lxsession"); then
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
if $(does-bin-exist "file-roller"); then
    set_gsetting "org.gnome.FileRoller.General" compression-level "maximum"
fi

#############
### Audio ###
#############
if $(does-bin-exist "gnome-shell"); then
    set_gsetting org.gnome.desktop.sound allow-volume-above-100-percent "true"
    set_gsetting org.gnome.settings-daemon.plugins.media-keys volume-step 3
fi
if $(does-bin-exist "openal-info"); then
    set_config_value "${HOME_REAL}/.alsoftrc" hrtf true
fi
if $(does-bin-exist "pulseaudio"); then
    set_config_value "${ROOT_ETC}/pulse/daemon.conf" resample-method speex-float-10
fi

###################
### CALCULATORS ###
###################
if $(does-bin-exist "gnome-calculator"); then
    GNOME_CALCULATOR_SCHEMA="org.gnome.calculator"
    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" show-thousands true
    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" source-currency 'EUR'
    set_gsetting "${GNOME_CALCULATOR_SCHEMA}" target-currency 'RON'
fi
if $(does-bin-exist "mate-calc"); then
    set_gsetting "org.mate.calc" show-thousands true
fi

#################
### CHAT APPS ###
#################
if $(does-bin-exist "discord"); then
    set_json_value "${HOME_REAL}/.config/discord/settings.json" '.BACKGROUND_COLOR' ${GTK_THEME_BG_COLOUR}
fi
if $(does-bin-exist "telegram-desktop"); then
    set_config_value "${ENVIRONMENT_VARS_FILE}" TDESKTOP_I_KNOW_ABOUT_GTK_INCOMPATIBILITY "1"
fi
if $(does-bin-exist "whatsapp-for-linux"); then
    WAPP_CONFIG_FILE="${HOME_REAL}/.config/whatsapp-for-linux/settings.conf"

    # Disable tray because tray icons don't work and the window becomes inaccessible
    set_config_value "${WAPP_CONFIG_FILE}" close_to_tray false
    set_config_value "${WAPP_CONFIG_FILE}" start_in_tray false
fi
if $(does-bin-exist "whatsapp-nativefier"); then
    WAPP_CONFIG_FILE="${ROOT_OPT}/whatsapp-nativefier/resources/app/nativefier.json"
    WAPP_PREFERENCES_FILE="${HOME}/.config/whatsapp-nativefier-d40211/Preferences"

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
if $(does-bin-exist "dconf-editor"); then
    set_gsetting ca.desrt.dconf-editor.Settings show-warning false
fi

################
### Contacts ###
################
if $(does-bin-exist "gnome-contacts"); then
    set_gsetting "org.gnome.Contacts" did-initial-setup true
    set_gsetting "org.gnome.Contacts" sort-on-surname true
fi

#############
### DOCKS ###
#############
if [ -d "${ROOT_USR}/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/" ]; then
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
if $(does-bin-exist "plank"); then
    PLANK_SCHEMA="net.launchpad.plank.docks.dock1"

    set_gsetting "${PLANK_SCHEMA}" theme "Gtk+"
    set_gsetting "${PLANK_SCHEMA}" hide-mode "window-dodge"
fi

########################
### DOCUMENT VIEWERS ###
########################
if $(does-bin-exist "epdfview"); then
    EPDFVIEW_CONFIG_FILE="${HOME_REAL}/.config/epdfview/main.conf"

    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToFit false
    set_config_value "${EPDFVIEW_CONFIG_FILE}" zoomToWidth true
    set_config_value "${EPDFVIEW_CONFIG_FILE}" browser "chromium %s"
fi

#####################
### FILE MANAGERS ###
#####################
if $(does-bin-exist "nautilus"); then
    NAUTILUS_SCHEMA="org.gnome.nautilus"

    set_gsetting "${NAUTILUS_SCHEMA}.icon-view" default-zoom-level "standard"
    set_gsetting "${NAUTILUS_SCHEMA}.list-view" default-zoom-level "small"
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-create-link true
    set_gsetting "${NAUTILUS_SCHEMA}.preferences" show-delete-permanently true
    set_gsetting "${NAUTILUS_SCHEMA}.window-state" sidebar-width 240
fi
if $(does-bin-exist "pcmanfm"); then
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
if $(does-bin-exist "firefox"); then
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
    set_firefox_config "${FIREFOX_PROFILE_ID}" "browser.tabs.insertAfterCurrent" "false"
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
    set_firefox_config "${FIREFOX_PROFILE_ID}" "identity.fxaccounts.account.device.name" ${HOSTNAME}
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

##############################
### Games & Game Launchers ###
##############################
MC_DIR="${HOME}/.minecraft"
MC_OPTIONS_FILE="${MC_DIR}/options.txt"
MC_LAUNCHER_PROFILES_FILE="${MC_DIR}/launcher_profiles.json"
MC_LAUNCHER_SETTINGS_FILE="${MC_DIR}/launcher_settings.json"

if [ -f "${MC_OPTIONS_FILE}" ]; then
    DEVICE_ID=$(shuf -i1000000000000000000-9999999999999999999 -n1)

    set_config_value --separator ":" "${MC_OPTIONS_FILE}" true
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" darkMojangStudiosBackground ${GTK_THEME_IS_DARK}
    set_config_value --separator ":" "${MC_OPTIONS_FILE}" pauseOnLostFocus false

    set_json_value "${MC_LAUNCHER_PROFILES_FILE}" '.settings.crashAssistance' false
    set_json_value "${MC_LAUNCHER_SETTINGS_FILE}" '.deviceId' ${DEVICE_ID}
    set_json_value "${MC_LAUNCHER_SETTINGS_FILE}" '.locale' en-GB
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
if $(does-bin-exist "code"); then
    VSCODE_CONFIG_FILE="${HOME}/.config/Code/User/settings.json"

    # Appearance
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.codeLens"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.find.autoFindInSelection"]' "multiline"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.find.seedSearchStringFromSelection"]' "never"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.fontFamily"]' "${MONOSPACE_FONT_NAME} ${MONOSPACE_FONT_STYLE}"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.fontSize"]' $((MONOSPACE_FONT_SIZE+3))
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.roundedSelection"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.maxColumn"]' 100
    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.minimap.renderCharacters"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectActivityBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.affectTabActiveBorder"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["peacock.showColorInStatusBar"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["update.mode"]' "none"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.autoDetectColorScheme"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["window.menuBarVisibility"]' "toggle"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.colorTheme"]' "Default Dark+"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["workbench.iconTheme"]' "seti"
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.drawBoldTextInBrightColors"]' ${TERMINAL_BOLD_TEXT_IS_BRIGHT}

    set_json_value "${VSCODE_CONFIG_FILE}" '.["editor.autoClosingBrackets"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDragAndDrop"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["explorer.confirmDelete"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autofetch"]' true
    set_json_value "${VSCODE_CONFIG_FILE}" '.["git.autofetchPeriod"]' 300
    set_json_value "${VSCODE_CONFIG_FILE}" '.["terminal.integrated.scrollback"]' ${TERMINAL_SCROLLBACK_SIZE}

    # C#
    set_json_value "${VSCODE_CONFIG_FILE}" '.["omnisharp.enableDecompilationSupport"]' true

    # Telemetry
    set_json_value "${VSCODE_CONFIG_FILE}" '.["telemetry.enableCrashReporter"]' false
    set_json_value "${VSCODE_CONFIG_FILE}" '.["telemetry.enableTelemetry"]' false
fi

################
### INKSCAPE ###
################
if $(does-bin-exist "inkscape"); then
    INKSCAPE_PREFERENCES_FILE="${HOME}/.config/inkscape/preferences.xml"

    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultPreferDarkTheme" "${GTK_THEME_IS_DARK_BINARY}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultGtkTheme" "${GTK_THEME}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@defaultIconTheme" "${ICON_THEME}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@darkTheme" "${GTK_THEME_IS_DARK_BINARY}"
    set_xml_node "${INKSCAPE_PREFERENCES_FILE}" "//group[@id='theme']/@preferDarkTheme" "${GTK_THEME_IS_DARK_BINARY}"
fi

########################
### KEYBOARD & MOUSE ###
########################
if $(does-bin-exist "gnome-shell"); then
    # Keyboard
    set_gsetting org.gnome.desktop.peripherals.keyboard numlock-state true
    set_gsetting org.gnome.desktop.input-sources sources "[('xkb', 'ro')]"
    set_gsetting org.gnome.desktop.input-sources xkb-options "['lv3:ralt_switch']"

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
    set_gsetting org.gnome.desktop.peripherals.mouse speed 0.17999999999999999 # 0.18 can't be set
fi

############
### MAPS ###
############
if $(does-bin-exist "gnome-maps"); then
    set_gsetting org.gnome.Maps night-mode true
fi

###################
### NIGHT LIGHT ###
###################
if $(does-bin-exist "gnome-shell"); then
    set_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true
fi

#####################
### NOTIFICATIONS ###
#####################
if $(does-bin-exist "gnome-shell"); then
    GNOME_NOTIFICATIONS_SCHEMA="org.gnome.desktop.notifications.application:/org/gnome/desktop/notifications/application"

    # Disable
    $(does-bin-exist "simplenote") && set_gsetting "${GNOME_NOTIFICATIONS_SCHEMA}/simplenote/" enable false

    # Hide on lockscreen
    set_gsetting "${GNOME_NOTIFICATIONS_SCHEMA}/gnome-power-panel/" show-in-lock-screen false
fi

########################
### POWER MANAGEMENT ###
########################
if $(does-bin-exist "gnome-shell"); then
    GNOME_POWER_SCHEMA="org.gnome.settings-daemon.plugins.power"

    set_gsetting "${GNOME_POWER_SCHEMA}" idle-dim true
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-ac-timeout 1800
    set_gsetting "${GNOME_POWER_SCHEMA}" sleep-inactive-battery-timeout 900
fi

###################
### Screenshots ###
###################
if $(does-bin-exist "gnome-screenshot"); then
    set_gsetting "org.gnome.gnome-screenshot" last-save-directory "${HOME}/Pictures"
fi

################
### Terminal ###
################
if $(does-bin-exist "gnome-terminal"); then
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

if $(does-bin-exist "lxterminal"); then
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
if $(does-bin-exist "gedit"); then
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
if $(does-bin-exist "pluma"); then
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
if [ -d "${ROOT_USR}/share/gnome-shell/extensions/wintile@nowsci.com/" ]; then
    WINTILE_SCHEMA="org.gnome.shell.extensions.wintile"
#    set_gsetting "${WINTILE_SCHEMA}" use-minimize false
fi

###########################
### TORRENT DOWNLOADERS ###
###########################
if $(does-bin-exist "fragments"); then
    FRAGMENTS_SCHEMA="de.haeckerfelix.Fragments"

    set_gsetting "${FRAGMENTS_SCHEMA}" download-folder "${HOME}/Downloads"
    set_gsetting "${FRAGMENTS_SCHEMA}" enable-dark-theme ${GTK_THEME_IS_DARK}
    set_gsetting "${FRAGMENTS_SCHEMA}" encryption-mode 1
    set_gsetting "${FRAGMENTS_SCHEMA}" max-downloads 5
fi

########################
### TRANSLATION APPS ###
########################
if $(does-bin-exist "dialect"); then
    DIALECT_SCHEMA="com.github.gi_lom.dialect"

    set_gsetting "${DIALECT_SCHEMA}" dark-mode ${GTK_THEME_IS_DARK}
    set_gsetting "${DIALECT_SCHEMA}" show-pronunciation true
    set_gsetting "${DIALECT_SCHEMA}" translate-accel 1
fi

#####################
### VIDEO PLAYERS ###
#####################
if $(does-bin-exist "totem"); then
    TOTEM_SCHEMA="org.gnome.totem"

    set_gsetting "${TOTEM_SCHEMA}" autoload-subtitles "true"
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
