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

source "${EXEDIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

if ${HAS_SU_PRIVILEGES}; then
    echo "I need SU privileges!"
    run_as_su printf "Thank you!\n\n"
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
    run_as_su "${ROOT_BIN}/bash" "${SCRIPT_PATH}"
}

function update-system() {
    ! ${HAS_SU_PRIVILEGES} && return

    echo "Updating the system..."

    if [[ "${DISTRO_FAMILY}" == "Arch" ]]; then
        if does_bin_exist "paru"; then
            paru -Syu --noconfirm --needed --noredownload --norebuild --sudoloop
        else
            run_as_su pacman -Syu
        fi
    elif [[ "${DISTRO_FAMILY}" == "Android" ]]; then
        yes | pkg update
        yes | pkg upgrade
    elif [[ "${DISTRO_FAMILY}" == "Debian" ]]; then
        yes | run_as_su apt update
        yes | run_as_su apt upgrade
    fi

    call_flatpak update
}

echo "OS:               ${OS}"
echo "Distro:           ${DISTRO} (${DISTRO_FAMILY})"
echo "DE:               ${DESKTOP_ENVIRONMENT}"
echo "Architecture:     $(get_arch) ($(get_arch_family))"
echo "CPU:              $(get_cpu)"
echo "GPU:              $(get_gpu)"
echo "Audio driver:     $(get_audio_driver)"
echo "Chassis:          $(get_chassis_type)"
echo "EFI support:      ${HAS_EFI_SUPPORT}"
echo ""

if ${HAS_GUI}; then
    echo "GUI:        ${HAS_GUI}"
    echo "Screen DPI: $(get_screen_dpi)"
    echo ""

    echo "Is development device:        ${IS_DEVELOPMENT_DEVICE}"
    echo "Is gaming device:             ${IS_GAMING_DEVICE}"
    echo "Is general purpose device:    ${IS_GENERAL_PURPOSE_DEVICE}"
    echo "Is powerful device:           ${POWERFUL_PC}"
    echo ""
fi

# Remove the MOTD
[ -f "${ROOT_ETC}/motd" ] && remove "${ROOT_ETC}/motd"

# Package management
if [ "${OS}" != "Windows" ]; then
    # Configure package repositories
    execute-script-superuser "configure-repositories.sh"
    execute-script "update-package-repositories.sh"

    # Manage packages and extensions
    execute-script "uninstall-packages.sh"
    execute-script "update-packages.sh"
    execute-script "install-packages.sh"
    execute-script "uninstall-packages.sh"
    execute-script "clean-packages.sh"
fi

# Update the RCs
execute-script "update-rcs.sh"
[ "${OS}" == "Linux" ] && execute-script-superuser "update-rcs.sh"

# Update the resources
if [[ "${OS}" == "Linux" ]]; then
    execute-script "update-resources.sh"
    execute-script-superuser "update-resources.sh"
fi

# Configure and customise the system
execute-script "configure-system.sh" # Run after update-rcs.sh
if [[ "${OS}" == "Linux" ]]; then
    if ${HAS_GUI}; then
        execute-script-superuser "customise-launchers.sh"
        execute-script "configure-autostart-apps.sh"
        execute-script "configure-default-apps.sh"
    fi
fi

execute-script "configure-permissions.sh" # Run after install-packages.sh
[ "${DISTRO_FAMILY}" == "Linux" ] && execute-script-superuser "set-system-locale-timedate.sh"
[ "${DISTRO_FAMILY}" != "Android" ] && execute-script-superuser "update-profiles.sh"

if [ "${OS}" == "Linux" ]; then
    does_bin_exist "systemctl" && execute-script-superuser "enable-services.sh"
    does_bin_exist "grub-mkconfig" && execute-script-superuser "update-grub.sh" # Run after configure-system.sh
fi
execute-script "configure-directories.sh"

execute-script "git/setup-gpg-key.sh"

execute-script "clean-files.sh"

# Assign users and groups
[ "${OS}" == "Linux" ] && execute-script-superuser "assign-users-and-groups.sh"

# Clean journals older than 1 week
if ${HAS_SU_PRIVILEGES} && does_bin_exist "journalctl"; then
    run_as_su journalctl -q --vacuum-time=7d
fi

source ~/.bashrc
