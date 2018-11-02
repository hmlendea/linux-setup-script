#!/bin/bash

set_config_value() {
    FILE="$1"
    KEY="$2"
    VALUE_RAW="$3"

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
            printf "$KEY=$VALUE\n" >> "$FILE"
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
            printf "options $MODULE $KEY=$VALUE\n" >> "$FILE"
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

set_modprobe_option bluetooth disable_ertm 1    # Xbox One Controller Pairing
set_modprobe_option btusb enable_autosuspend n  # Xbox One Controller Connecting, possibly other devices as well

if [ -f "/etc/default/grub" ]; then
    set_config_value "/etc/default/grub" "GRUB_TIMEOUT" 1
fi

if [ -f "/usr/bin/gnome-shell" ]; then
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

    set_gsetting "org.gnome.desktop.wm.preferences" button-layout "close:minimize,maximize"
    set_gsetting "org.gnome.desktop.wm.preferences" titlebar-font "Roboto 10"

    set_gsetting "org.gnome.shell.overrides" attach-modal-dialogs false

    set_gsetting "org.gnome.desktop.sound" allow-volume-above-100-percent "true"

    set_gsetting "org.gnome.desktop.interface" clock-show-date "true"
    set_gsetting "org.gnome.desktop.interface" show-battery-percentage "true"
    set_gsetting "org.gnome.desktop.interface" document-font-name "Noto Sans 10"
    set_gsetting "org.gnome.desktop.interface" font-name "Noto Sans 10"
    set_gsetting "org.gnome.desktop.interface" monospace-font-name "Noto Sans Mono 11"

    if [ -d "/usr/share/themes/Materia-dark-compact" ]; then
        set_gsetting "org.gnome.desktop.interface" gtk-theme "Materia-dark-compact"
    fi

    if [ -d "/usr/share/icons/ePapirus" ]; then
        set_gsetting "org.gnome.desktop.interface" icon-theme "ePapirus"
    fi
fi

if [ -f "/usr/bin/gnome-terminal" ]; then
    set_gsetting "org.gnome.Terminal.Legacy.Settings" default-show-menubar false
fi

if [ -f "/usr/bin/totem" ]; then
    set_gsetting "org.gnome.totem" autoload-subtitles "true"
    set_gsetting "org.gnome.totem" subtitle-font "Sans Bold 12"
fi

if [ -f "/usr/bin/nautilus" ]; then
    set_gsetting "org.gnome.nautilus.icon-view" default-zoom-level "'small'"
    set_gsetting "org.gnome.nautilus.preferences" executable-text-activation "'display'"
    set_gsetting "org.gnome.nautilus.preferences" show-create-link true
    set_gsetting "org.gnome.nautilus.preferences" show-delete-permanently true
    set_gsetting "org.gnome.nautilus.window-state" sidebar-width 240
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
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" multi-monitor true
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" running-indicator-style DOTS
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" scroll-action cycle-windows
    set_gsetting "org.gnome.shell.extensions.dash-to-dock" show-show-apps-button false
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
