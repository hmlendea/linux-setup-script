#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$EXEDIR/$SOURCE"
done
EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd "$EXEDIR"

# Make sure the USER envar is set (on Android it is not)
export USER="$(whoami)"

source "${EXEDIR}/scripts/common/common.sh"
source "${EXEDIR}/scripts/common/system-info.sh"

if ${HAS_SU_PRIVILEGES}; then
    echo "I need SU privileges!"
    run-as-su printf "Thank you!\n\n"
fi

function execute-script() {
    [ "${UID}" -eq 0 ] && return

    SCRIPT_NAME="${1}"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo -e "Executing as \e[1;94m$USER\e[0;39m: '${SCRIPT_NAME}'..."
    "${ROOT_BIN}/bash" "${SCRIPT_PATH}"
}

function execute-script-superuser() {
    ! ${HAS_SU_PRIVILEGES} && return

    SCRIPT_NAME="${1}"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo -e "Executing as \e[1;91mroot\e[0;39m: '${SCRIPT_NAME}'..."
    run-as-su "${ROOT_BIN}/bash" "${SCRIPT_PATH}"
}

function update-system() {
    ! ${HAS_SU_PRIVILEGES} && return

    echo "Updating the system..."

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        if does-bin-exist "paru"; then
            paru -Syu --noconfirm --needed --noredownload --norebuild --sudoloop
        else
            run-as-su pacman -Syu
        fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        yes | pkg update
        yes | pkg upgrade
    elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        yes | run-as-su apt update
        yes | run-as-su apt upgrade
    fi
}

echo "OS:           ${OS}"
echo "Distro:       ${DISTRO} (${DISTRO_FAMILY})"
echo "Architecture: $(get_arch) ($(get_arch_family))"
echo "CPU:          $(get_cpu)"
echo "GPU:          $(get_gpu)"
echo "Chassis:      $(get_chassis_type)"
echo "GUI:          ${HAS_GUI}"
echo "EFI support:  ${HAS_EFI_SUPPORT}"
echo "Powerful PC:  ${POWERFUL_PC}"
echo "Gaming PC:    ${GAMING_PC}"
echo "Screen DPI:   $(get_screen_dpi)"
echo ""

# Remove the MOTD
[ -f "${ROOT_ETC}/motd" ] && remove "${ROOT_ETC}/motd"

# Configure package repositories
execute-script-superuser "configure-repositories.sh"

# Package management
if [ "${OS}" != "Windows" ]; then
    # Manage packages and extensions
    execute-script "uninstall-pkgs.sh"
    update-system
    execute-script "install-pkgs.sh"
fi

if [[ "${OS}" == "Linux" ]]; then
    execute-script "clean-files.sh"
    execute-script-superuser "clean-files.sh"

    execute-script "update-extensions.sh"

    if ${HAS_GUI}; then
        execute-script-superuser "customise-launchers.sh"
    fi
fi

# Update the RCs
execute-script "update-rcs.sh"
[ "${OS}" == "Linux" ] && execute-script-superuser "update-rcs.sh"

# Configure and customise the system
execute-script "config-system.sh" # Run after update-rcs.sh
[ "${DISTRO_FAMILY}" == "Arch" ] && execute-script-superuser "set-system-locale-timedate.sh"
[ "${DISTRO_FAMILY}" != "Android" ] && execute-script-superuser "install-profiles.sh"

if [ "${OS}" == "Linux" ]; then
    does-bin-exist "systemctl" && execute-script-superuser "enable-services.sh"
    does-bin-exist "grub-mkconfig" && execute-script-superuser "update-grub.sh" # Run after config-system.sh

    if ${HAS_GUI}; then
        execute-script "update-hidden-files.sh"
        execute-script "configure-autostart-apps.sh"
    fi
fi

# Update the resources
if [[ "${OS}" == "Linux" ]]; then
    execute-script "update-resources.sh"
    execute-script-superuser "update-resources.sh"
fi

execute-script "git/setup-gpg-key.sh"

# Assign users and groups
[ "${OS}" == "Linux" ] && execute-script-superuser "assign-users-and-groups.sh"

# Clean journals older than 1 week
if ${HAS_SU_PRIVILEGES} && does-bin-exist "journalctl"; then
    run-as-su journalctl -q --vacuum-time=7d
fi

source ~/.bashrc
