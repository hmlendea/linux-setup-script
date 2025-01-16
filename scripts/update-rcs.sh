#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/apps.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"

# .profile
create_file "${HOME}/.profile"
set_config_value "${HOME}/.profile" 'export XDG_CACHE_HOME'     "\"${HOME}/.cache\""
set_config_value "${HOME}/.profile" 'export XDG_CONFIG_HOME'    "\"${HOME}/.config\""
set_config_value "${HOME}/.profile" 'export XDG_DATA_HOME'      "\"${HOME}/.local/share\""
set_config_value "${HOME}/.profile" 'export XDG_STATE_HOME'     "\"${HOME}/.local/state\""
set_config_value "${HOME}/.profile" 'export XDG_DESKTOP_DIR'    "\"${XDG_DESKTOP_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_DOCUMENTS_DIR'  "\"${XDG_DOCUMENTS_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_DOWNLOAD_DIR'   "\"${XDG_DOWNLOAD_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_MUSIC_DIR'      "\"${XDG_MUSIC_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_PICTURES_DIR'   "\"${XDG_PICTURES_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_PUBLIC_DIR'     "\"${XDG_PUBLIC_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_TEMPLATES_DIR'  "\"${XDG_TEMPLATES_DIR}\""
set_config_value "${HOME}/.profile" 'export XDG_VIDEOS_DIR'     "\"${XDG_VIDEOS_DIR}\""
if [ -d "${HOME}/.local/bin" ]; then
    set_config_value "${HOME}/.profile" 'export PATH' '"${PATH}:/'"${HOME}"'/.local/bin"'
else
    set_config_value "${HOME}/.profile" 'export PATH' '"${PATH}"'
fi

#update_file_if_distinct "${REPO_RC_DIR}/profile" "${HOME}/.profile"
update_file_if_distinct "${REPO_RC_DIR}/inputrc" "${XDG_CONFIG_HOME}/readline/inputrc"

SHELL_RCS_DIR="${XDG_DATA_HOME}/bash"
SHELL_VARIABLES_RC_PATH="${SHELL_RCS_DIR}/variables"

update_file_if_distinct "${REPO_RC_DIR}/shell/aliases" "${XDG_DATA_HOME}/bash/aliases"
update_file_if_distinct "${REPO_RC_DIR}/shell/functions" "${XDG_DATA_HOME}/bash/functions"
update_file_if_distinct "${REPO_RC_DIR}/shell/opts" "${XDG_DATA_HOME}/bash/options"
update_file_if_distinct "${REPO_RC_DIR}/shell/prompt" "${XDG_DATA_HOME}/bash/prompt"

if does_bin_exist 'bash'; then
    update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bashrc"
    update_file_if_distinct "${REPO_RC_DIR}/shell/bash_profile" "${HOME}/.bash_profile"
    update_file_if_distinct "${REPO_RC_DIR}/shell/bashrc" "${HOME}/.bash_prompt"
fi

for RC in 'gimprc' 'sessionrc' 'toolrc'; do
    does_bin_exist 'gimp' && update_file_if_distinct "${REPO_RC_DIR}/gimp/${RC}" "${XDG_CONFIG_HOME}/GIMP/2.10/${RC}"
    does_bin_exist 'org.gimp.GIMP' && update_file_if_distinct "${REPO_RC_DIR}/gimp/${RC}" "${HOME_VAR_APP}/org.gimp.GIMP/config/GIMP/2.10/${RC}"
done

does_bin_exist 'nano'       && update_file_if_distinct "${REPO_RC_DIR}/nanorc"      "${HOME}/.nanorc"
does_bin_exist 'vim'        && update_file_if_distinct "${REPO_RC_DIR}/vimrc"       "${HOME}/.vimrc"
does_bin_exist 'git'        && update_file_if_distinct "${REPO_RC_DIR}/gitconfig"   "${XDG_CONFIG_HOME}/git/config"
does_bin_exist 'lxpanel'    && update_file_if_distinct "${REPO_RC_DIR}/lxde-panel"  "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/panel"
#does_bin_exist 'lxpanel'    && update_file_if_distinct "${REPO_RC_DIR}/lxde-dock"   "${XDG_CONFIG_HOME}/lxpanel/LXDE/panels/dock"

if does_bin_exist 'firefox' 'firefox-esr' 'io.gitlab.librewolf-community' 'org.mozilla.firefox'; then
    FIREFOX_PROFILES_DIR="$(get_firefox_profiles_dir)"
    FIREFOX_PROFILES_INI_FILE="${FIREFOX_PROFILES_DIR}/profiles.ini"

    if [ -f "${FIREFOX_PROFILES_INI_FILE}" ]; then
        FIREFOX_PROFILE_ID=$(grep '^Path=' "${FIREFOX_PROFILES_INI_FILE}" | awk -F= '{print $2}' | head -n 1)

        if [ -d "${ROOT_USR_LIB}/firefox" ]; then
            update_file_if_distinct "${REPO_RC_DIR}/firefox-policies.json" "${ROOT_USR_LIB}/firefox/distribution/policies.json"
        fi
    fi
fi

if does_bin_exist 'npm'; then
    NPMRC_FILE="${HOME}/.npmrc"

    [ -n "${NPM_CONFIG_USERCONFIG}" ] && NPMRC_FILE="${NPM_CONFIG_USERCONFIG}"

    set_config_value "${NPMRC_FILE}" prefix "\"${XDG_DATA_HOME}/npm\""
    set_config_value "${NPMRC_FILE}" cache "\"${XDG_CACHE_HOME}/npm\""
    set_config_value "${NPMRC_FILE}" tmp "\"${XDG_RUNTIME_DIR}/npm\""
    set_config_value "${NPMRC_FILE}" init-module "\"${XDG_CONFIG_HOME}/npm/config/npm-init.js\""
fi

#########################
### Shell - Variables ###
#########################
touch "${SHELL_VARIABLES_RC_PATH}"

set_config_values "${SHELL_VARIABLES_RC_PATH}" \
    'export SHELL'          "${ROOT_BIN}/bash" \
    'export HISTFILE'       "${SHELL_RCS_DIR}/history" \
    'export HISTSIZE'       10000 \
    'export HISTCONTROL'    'ignoredups' \
    'export LESSHISTFILE'   "${XDG_CACHE_HOME}/less/history" \
    'export GPG_TTY'        '${SSH_TTY}'

if [ -n "${USER}" ]; then
    set_config_values "${SHELL_VARIABLES_RC_PATH}" \
        'export USER'       '${USER}' \
        'export USERNAME'   '${USER}'
elif [ -n "${USERNAME}" ]; then
    set_config_values "${SHELL_VARIABLES_RC_PATH}" \
        'export USER'       '${USERNAME}' \
        'export USERNAME'   '${USERNAME}'
else
    set_config_values "${SHELL_VARIABLES_RC_PATH}" \
        'export USER'       '$(whoami)' \
        'export USERNAME'   '$(whoami)'
fi

set_config_values "${SHELL_VARIABLES_RC_PATH}" \
    'export LANG'           'en_GB.UTF-8' \
    'export NUGET_PACKAGES' "${XDG_CACHE_HOME}/nuget/packages" \
    'export SSL_CERT_DIR'   "${ROOT_ETC}/ssl/certs" \
    'export XAUTHORITY'     "${XDG_RUNTIME_DIR}/Xauthority"

set_config_values "${SHELL_VARIABLES_RC_PATH}" \
    'export CARGOGHOME'         "${XDG_DATA_HOME}/cargo" \
    'export GNUPGHOME'          "${XDG_DATA_HOME}/gnupg" \
    'export GRADLE_USER_HOME'   "${XDG_DATA_HOME}/gradle"

set_config_values "${SHELL_VARIABLES_RC_PATH}" \
    'export INPUTRC'                "${XDG_CONFIG_HOME}/readline/inputrc" \
    'export NPM_CONFIG_USERCONFIG'  "${XDG_CONFIG_HOME}/npm/npmrc"

[ -d "${ROOT_USR_LIB32}" ]          && set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export LD_LIBRARY_PATH'   '${LD_LIBRARY_PATH-}:'"${ROOT_USR_LIB32}"
[ -d "${ROOT_USR_LIB}/gtk-2.0" ]    && set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export GTK2_RC_FILES'     "${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"

if [ "${GPU_FAMILY}" = 'Nvidia' ]; then
    set_config_values "${SHELL_VARIABLES_RC_PATH}" \
        'export __GL_SHADER_DISK_CACHE_PATH'  "${XDG_CACHE_HOME}/nvidia/GLCache" \
        'export CUDA_CACHE_PATH'              "${XDG_CACHE_HOME}/nvidia"
fi

does_bin_exist 'bat'        && set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export BAT_THEME'     'Visual Studio Dark+'
does_bin_exist 'optirun'    && set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export VGL_READBACK'  'pbo' # Better optirun performance

if does_bin_exist 'dotnet'; then
    set_config_values "${SHELL_VARIABLES_RC_PATH}" \
        'export DOTNET_CLI_TELEMETRY_OUTPUT'        1 \
        'export DOTNET_SKIP_FIRST_TIME_EXPERIENCE'  1
fi

#if [ -f "${ROOT_USR_BIN}/firefox" ] \
#|| [ -f "${ROOT_USR_BIN}/firefox-esr" ] \
#|| [ -f "${GLOBAL_FLATPAK_BIN}/io.gitlab.librewolf-community" ] \
#|| [ -f "${GLOBAL_FLATPAK_BIN}/org.mozilla.firefox" ] \
#|| [ -f "${LOCAL_FLATPAK_BIN}/io.gitlab.librewolf-community" ] \
#|| [ -f "${LOCAL_FLATPAK_BIN}/org.mozilla.firefox" ]; then
#    if [ -n "${WAYLAND_DISPLAY}" ]; then
#        export MOZ_ENABLE_WAYLAND=1
#    fi
#fi

if does_bin_exist 'paru'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export PACKAGE_MANAGER' 'paru'
elif does_bin_exist 'yay'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export PACKAGE_MANAGER' 'yay'
else
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export PACKAGE_MANAGER' 'pacman'
fi

if does_bin_exist 'micro'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export EDITOR' 'micro'
    [[ ${COLORTERM} =~ ^(truecolor|24-bit|24bit)$ ]] && set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export MICRO_TRUECOLOR' 1
elif does_bin_exist 'nano'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export EDITOR' 'nano'
elif does_bin_exist 'vim'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export EDITOR' 'vim'
elif does_bin_exist 'vi'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export EDITOR' 'vi'
fi

if does_bin_exist 'steam'; then
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS' 0               # Fix for loosing focus in Steam BPM after exiting a game
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export VKD3D_CONFIG'                     'upload_hvv'    # Resizeable BAR
    set_config_value "${SHELL_VARIABLES_RC_PATH}" 'export WINE_FULLSCREEN_FSR'              1
fi

# Shell colours
set_config_values "${SHELL_VARIABLES_RC_PATH}" \
    'export LESS_TERMCAP_mb' '$'"'"'\e[1;32m'"'" \
    'export LESS_TERMCAP_md' '$'"'"'\e[1;36m'"'" \
    'export LESS_TERMCAP_me' '$'"'"'\e[0m'"'" \
    'export LESS_TERMCAP_se' '$'"'"'\e[0m'"'" \
    'export LESS_TERMCAP_so' '$'"'"'\e[01;97m'"'" \
    'export LESS_TERMCAP_ue' '$'"'"'\e[0m'"'" \
    'export LESS_TERMCAP_us' '$'"'"'\e[1;4;033m'"'"
