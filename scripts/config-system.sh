#!/bin/bash

USER_REAL=$SUDO_USER
[ ! -n "$USER_REAL" ] && USER_REAL=$USER
HOME_REAL="/home/$USER_REAL"

set_config_value() {
    FILE="$1"
    KEY="$2"
    VALUE_RAW="${@:3}"

    if [ ! -f "$FILE" ]; then
        # TODO: Handle directory creation
        touch "$FILE"
    fi

    VALUE=$(echo "$VALUE_RAW" | sed -e 's/[]\/$*.^|[]/\\&/g')
    FILE_CONTENT=$(cat "$FILE")

    # If the value is not already set
    if [ $(grep -c "^${KEY}=${VALUE}$" <<< "$FILE_CONTENT") == 0 ]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^${KEY}=.*$" <<< "$FILE_CONTENT") -gt 0 ]; then
            sed -i 's|^'"${KEY}"'=.*$|'"${KEY}"'='"${VALUE}"'|g' "$FILE"
        else
            LINE="$KEY=$VALUE"
            echo "$LINE" | sudo tee -a "$FILE"
            #printf "$LINE\n" >> "$FILE"
        fi

        echo "$FILE >>> $KEY=$VALUE"
    fi
}

set_modprobe_option() {
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

set_gsetting() {
    SCHEMA="$1"
    PROPERTY="$2"
    VALUE="$3"

    CURRENT_VALUE=$(gsettings get $SCHEMA $PROPERTY)

    if [ "$CURRENT_VALUE" != "$VALUE" ] && [ "$CURRENT_VALUE" != "'$VALUE'" ]; then
        echo "GSettings >>> $SCHEMA.$PROPERTY=$VALUE"
        gsettings set "$SCHEMA" "$PROPERTY" "$VALUE"
    fi
}

### BLUETOOTH
# Xbox One Controller
#echo "options bluetooth disable_ertm=1" | tee --append /etc/modprobe.d/xbox_bt.conf

if [ "${ARCH}" == "x86_64" ]; then
    USING_NVIDIA_GPU=$(lspci | grep VGA | grep -c "NVIDIA")
else
    USING_NVIDIA_GPU=0
fi

# COMMON VALUES
MONOSPACE_FONT="Droid Sans Mono 13"
TERMINAL_BG="#1E272C"
TERMINAL_FG="#CFD8DC"
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
    set_config_value "/etc/default/grub" "GRUB_TIMEOUT" 1
    set_config_value "/etc/default/grub" "GRUB_DISABLE_RECOVERY" true
fi

if [ -f "/usr/bin/gnome-shell" ]; then
    if [ "${ARCH}" == "aarch64" ]; then
        set_gsetting "org.gnome.settings-daemon.plugins.remote-display" active false
        set_gsetting "org.gnome.desktop.interface" enable-animations false
    fi

    set_gsetting "org.gnome.desktop.datetime" automatic-timezone true

    set_gsetting "org.gnome.desktop.privacy" old-files-age "uint32 14"
    set_gsetting "org.gnome.desktop.privacy" remove-old-temp-files "true"
    set_gsetting "org.gnome.desktop.privacy" remove-old-trash-files "true"

    set_gsetting "org.gnome.desktop.peripherals.touchpad" click-method "default"
    set_gsetting "org.gnome.desktop.peripherals.touchpad" tap-to-click "true"

    set_gsetting "org.gnome.desktop.wm.keybindings" panel-run-dialog "['<Super>r']"
    set_gsetting "org.gnome.desktop.wm.keybindings" switch-applications "['<Alt>Tab']"
    set_gsetting "org.gnome.desktop.wm.keybindings" switch-applications-backward "['<Shift><Alt>Tab']"
    set_gsetting "org.gnome.desktop.wm.keybindings" switch-group "['<Super>Tab']"
    set_gsetting "org.gnome.desktop.wm.keybindings" switch-group-backward "['<Shift><Super>Tab']"
    set_gsetting "org.gnome.desktop.wm.keybindings" toggle-fullscreen "['<Super>f']"

    set_gsetting "org.gnome.desktop.wm.preferences" button-layout ":minimize,maximize,close"
    set_gsetting "org.gnome.desktop.wm.preferences" titlebar-font "Sans Regular 12"

    set_gsetting "org.gnome.shell.overrides" attach-modal-dialogs false
    set_gsetting "org.gnome.mutter" attach-modal-dialogs false

    set_gsetting "org.gnome.desktop.sound" allow-volume-above-100-percent "true"

    set_gsetting "org.gnome.desktop.interface" clock-show-date "true"
    set_gsetting "org.gnome.desktop.interface" show-battery-percentage "true"

    set_gsetting "org.gnome.desktop.peripherals.touchpad" disable-while-typing false

    set_gsetting "org.gnome.desktop.interface" document-font-name "Sans Regular 12"
    set_gsetting "org.gnome.desktop.interface" font-name "Sans Regular 12"
    set_gsetting "org.gnome.desktop.interface" monospace-font-name "${MONOSPACE_FONT}"

    if [ -d "/usr/share/themes/Adapta-Nokto-Eta" ]; then
        set_gsetting "org.gnome.desktop.interface" gtk-theme "Adapta-Nokto-Eta"
    elif [ -d "/usr/share/themes/Materia-dark-compact" ]; then
        set_gsetting "org.gnome.desktop.interface" gtk-theme "Materia-dark-compact"
    fi

    if [ -d "/usr/share/icons/ePapirus" ]; then
        set_gsetting "org.gnome.desktop.interface" icon-theme "ePapirus"
    fi
fi

if [ -f "/usr/bin/totem" ]; then
    set_gsetting "org.gnome.totem" autoload-subtitles "true"
    set_gsetting "org.gnome.totem" subtitle-font "Sans Bold 12"
fi

if [ -d "/usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/" ]; then
    if [ -d "/usr/share/themes/Materia-dark-compact" ]; then
        set_gsetting "org.gnome.shell.extensions.user-theme" name "Materia-dark-compact"
    fi
fi

if [ -d "/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/" ]; then
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" background-opacity 0.0
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" click-action minimize
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" custom-theme-customize-running-dots true
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" custom-theme-running-dots-color "#01a299"
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" custom-theme-shrink true
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" dock-position BOTTOM
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" intellihide-mode ALL_WINDOWS
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" multi-monitor true
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" running-indicator-style DOTS
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" scroll-action cycle-windows
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" show-show-apps-button false
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" show-trash false
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" transparency-mode FIXED
fi

if [ -d "/usr/share/gnome-shell/extensions/weather-extension@xeked.com" ]; then
    set_gsetting "org.gnome.shell.extensions.weather" show-comment-in-panel true
    set_gsetting "org.gnome.shell.extensions.weather" city "[<(uint32 2, <('Cluj-Napoca', 'LRCL', true, [(0.81652319590691635, 0.41131593287109447)], [(0.81623231933377882, 0.41189770347066179)])>)>]"
fi

if [ -d "/usr/share/gnome-shell/extensions/multi-monitors-add-on@spin83" ]; then
    set_gsetting "org.gnome.shell.extensions.multi-monitors-add-on" show-indicator false
fi

if [ -f "/usr/bin/panther_launcher" ]; then
    set_gsetting "org.rastersoft.panther" icon-size 48
    set_gsetting "org.rastersoft.panther" use-category true
fi

###################
### CALCULATORS ###
###################
if [ -f "/usr/bin/mate-calc" ]; then
    set_gsetting "org.mate.calc" show-thousands true
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
    set_gsetting "org.gnome.nautilus.icon-view" default-zoom-level "'small'"
    set_gsetting "org.gnome.nautilus.preferences" executable-text-activation "'display'"
    set_gsetting "org.gnome.nautilus.preferences" show-create-link true
    set_gsetting "org.gnome.nautilus.preferences" show-delete-permanently true
    set_gsetting "org.gnome.nautilus.window-state" sidebar-width 240
fi
if [ -f "/usr/bin/pcmanfm" ]; then
    PCMANFM_CONFIG_FILE="${HOME_REAL}/.config/pcmanfm/default/pcmanfm.conf"
    set_config_value "${PCMANFM_CONFIG_FILE}" always_show_tabs 0
    set_config_value "${PCMANFM_CONFIG_FILE}" max_tab_chars 48
    set_config_value "${PCMANFM_CONFIG_FILE}" pathbar_mode_buttons 1
    set_config_value "${PCMANFM_CONFIG_FILE}" toolbar "navigation;"
fi

####################
### TEXT EDITORS ###
####################
if [ -f "/usr/bin/gedit" ]; then
    set_gsetting "org.gnome.gedit.preferences.editor" highlight-current-line false
    set_gsetting "org.gnome.gedit.preferences.editor" insert-spaces true
    set_gsetting "org.gnome.gedit.preferences.editor" tabs-size 4
fi
if [ -f "/usr/bin/pluma" ]; then
    set_gsetting "org.mate.pluma" bracket-matching true
    set_gsetting "org.mate.pluma" display-line-numbers true
    set_gsetting "org.mate.pluma" editor-font "${MONOSPACE_FONT}"
    set_gsetting "org.mate.pluma" enable-space-drawer-space "show-trailing"
    set_gsetting "org.mate.pluma" enable-space-drawer-tab "show-all"
    set_gsetting "org.mate.pluma" insert-spaces true
    set_gsetting "org.mate.pluma" show-single-tab false
    set_gsetting "org.mate.pluma" toolbar-visible false
fi

#################
### TERMINALS ###
#################
if [ -f "/usr/bin/gnome-terminal" ]; then
    set_gsetting "org.gnome.Terminal.Legacy.Settings" default-show-menubar false
fi
if [ -f "/usr/bin/lxterminal" ]; then
    LXTERMINAL_CONFIG_FILE="${HOME_REAL}/.config/lxterminal/lxterminal.conf"
    set_config_value "${LXTERMINAL_CONFIG_FILE}" fontname ${MONOSPACE_FONT}
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
    set_config_value "${LXTERMINAL_CONFIG_FILE}" cursorblinks true
    set_config_value "${LXTERMINAL_CONFIG_FILE}" cursorunderline true
    set_config_value "${LXTERMINAL_CONFIG_FILE}" hidescrollbar true
    set_config_value "${LXTERMINAL_CONFIG_FILE}" hidemenubar true
fi

