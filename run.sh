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
    echo "GUI:              $(get_screen_width)x$(get_screen_height), $(get_screen_dpi) DPI"
    echo "Development:      ${IS_DEVELOPMENT_DEVICE}"
    echo "Gaming:           ${IS_GAMING_DEVICE}"
    echo "General purpose:  ${IS_GENERAL_PURPOSE_DEVICE}"
    echo "Powerful system:  ${POWERFUL_PC}"
    echo ""
fi

# Remove the MOTD
[ -f "${ROOT_ETC}/motd" ] && remove "${ROOT_ETC}/motd"

# Package management
if [ "${OS}" != "Windows" ]; then
    # Configure package repositories
    run_script_as_su "${REPO_SCRIPTS_DIR}/configure-repositories.sh"
    run_script "${REPO_SCRIPTS_DIR}/update-package-repositories.sh"

    # Manage packages and extensions
    run_script "${REPO_SCRIPTS_DIR}/uninstall-packages.sh"
    run_script "${REPO_SCRIPTS_DIR}/update-packages.sh"
    run_script "${REPO_SCRIPTS_DIR}/install-packages.sh"
    run_script "${REPO_SCRIPTS_DIR}/uninstall-packages.sh"
    run_script "${REPO_SCRIPTS_DIR}/clean-packages.sh"
fi

# Update the RCs
run_script "${REPO_SCRIPTS_DIR}/update-rcs.sh"
[ "${OS}" == "Linux" ] && run_script_as_su "${REPO_SCRIPTS_DIR}/update-rcs.sh"

# Update the resources
if [[ "${OS}" == "Linux" ]]; then
    run_script "${REPO_SCRIPTS_DIR}/update-resources.sh"
    run_script_as_su "${REPO_SCRIPTS_DIR}/update-resources.sh"
fi

# Configure and customise the system
run_script "${REPO_SCRIPTS_DIR}/configure-system.sh" # Run after update-rcs.sh
if [[ "${OS}" == "Linux" ]]; then
    if ${HAS_GUI}; then
        run_script "${REPO_SCRIPTS_DIR}/customise-launchers.sh"
        run_script "${REPO_SCRIPTS_DIR}/configure-autostart-apps.sh"
        run_script "${REPO_SCRIPTS_DIR}/configure-default-apps.sh"
    fi
fi

run_script "${REPO_SCRIPTS_DIR}/configure-permissions.sh" # Run after install-packages.sh
[ "${OS}" == "Linux" ] && run_script_as_su "${REPO_SCRIPTS_DIR}/set-system-locale-timedate.sh"
[ "${DISTRO_FAMILY}" != "Android" ] && run_script_as_su "${REPO_SCRIPTS_DIR}/update-profiles.sh"

if [ "${OS}" == "Linux" ]; then
    does_bin_exist "systemctl" && run_script_as_su "${REPO_SCRIPTS_DIR}/enable-services.sh"
    does_bin_exist "grub-mkconfig" && run_script_as_su "${REPO_SCRIPTS_DIR}/update-grub.sh" # Run after configure-system.sh
fi
run_script "${REPO_SCRIPTS_DIR}/configure-directories.sh"

run_script "${REPO_SCRIPTS_DIR}/git/setup-gpg-key.sh"

run_script "${REPO_SCRIPTS_DIR}/clean-files.sh"

# Assign users and groups
[ "${OS}" == "Linux" ] && run_script_as_su "${REPO_SCRIPTS_DIR}/assign-users-and-groups.sh"

source ~/.bashrc
