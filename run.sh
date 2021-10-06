#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$EXEDIR/$SOURCE"
done
EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd "$EXEDIR"

if [ "${UID}" -eq 0 ]; then
    echo "ERROR: You should not run this script as root!!!"
    exit 1
fi

# Make sure the USER envar is set (on Android it is not)
export USER="$(whoami)"

source "${EXEDIR}/scripts/_common.sh"

if [ -f "${ROOT_USR_BIN}/sudo" ]; then
    echo "I need sudo access!"
    sudo printf "Thank you!\n\n"
fi

function execute-script() {
    SCRIPT_NAME="$1"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo -e "Executing as \e[1;94m$USER\e[0;39m: '${SCRIPT_PATH}'..."
    "${ROOT_USR_BIN}/bash" "${SCRIPT_PATH}"
}

function execute-script-superuser() {
    SCRIPT_NAME="$1"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo -e "Executing as \e[1;91mroot\e[0;39m: '${SCRIPT_PATH}'..."

    if [ -f "${ROOT_USR_BIN}/sudo" ] ||
       [ -f "/data/data/com.termux/files/usr/bin/sudo" ]; then
        sudo "${ROOT_USR_BIN}/bash" "${SCRIPT_PATH}"
    else
        echo "ERROR: Please make sure 'sudo' is installed and configured"
    fi
}

function update-system() {
    echo "Updating the system..."

    if [ "${DISTRO_FAMILY}" == "arch" ]; then
        if [ -f "${ROOT_USR_BIN}/paru" ]; then
            paru -Syu --noconfirm --needed --noredownload --norebuild --sudoloop
        else
            sudo pacman -Syu
        fi
    elif [ "${DISTRO_FAMILY}" == "android" ]; then
        yes | pkg update
        yes | pkg upgrade
    fi
}

echo "Distro:       ${DISTRO} (${DISTRO_FAMILY})"
echo "Architecture: ${ARCH} (${ARCH_FAMILY})"
echo "CPU:          ${CPU_MODEL}"
echo "Chassis:      ${CHASSIS_TYPE}"
echo "GUI:          ${HAS_GUI}"
echo "EFI support:  ${IS_EFI}"
echo "Powerful PC:  ${POWERFUL_PC}"
echo "Gaming PC:    ${GAMING_PC}"
echo ""

execute-script-superuser "configure-repositories.sh"

# Manage packages and extensions
execute-script "install-pkgs.sh"
update-system
execute-script "update-extensions.sh"
[ "${DISTRO_FAMILY}" != "android" ] && execute-script-superuser "uninstall-pkgs.sh"

# Configure and customise the system
execute-script "config-system.sh"
[ "${DISTRO_FAMILY}" != "android" ] && execute-script-superuser "set-system-locale-timedate.sh"
[ "${DISTRO_FAMILY}" != "android" ] && execute-script-superuser "install-profiles.sh"

if [ -f "/etc/systemd/system/display-manager.service" ]; then # Only customise launchers a DM is used
    execute-script-superuser "customise-launchers.sh"
fi

[ "${DISTRO_FAMILY}" != "android" ] && execute-script-superuser "enable-services.sh"
[ "${DISTRO_FAMILY}" != "android" ] && execute-script-superuser "update-grub.sh"

# Update the RCs
execute-script "update-rcs.sh"
execute-script-superuser "update-rcs.sh"

# Update the resources
execute-script "update-resources.sh"
execute-script-superuser "update-resources.sh"

execute-script "setup-git-gpg.sh"

# Assign users and groups
execute-script "assign-users-and-groups.sh"

# Clean journals older than 1 week
[ -f "${ROOT_USR_BIN}/journalctl" ] && sudo journalctl -q --vacuum-time=7d

source ~/.bashrc
