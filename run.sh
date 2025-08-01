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
[ -z "${USER}" ] && export USER="$(whoami)"

source "${EXEDIR}/scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

if ${HAS_SU_PRIVILEGES}; then
    echo "I need SU privileges!"
    run_as_su printf "Thank you!\n\n"
fi

echo "Device:           ${DEVICE_TYPE} (${DEVICE_MODEL})"
echo "OS:               ${OS}"
echo "Distro:           ${DISTRO} (${DISTRO_FAMILY})"
echo "Architecture:     $(get_arch) ($(get_arch_family))"
echo "CPU:              $(get_cpu)"
echo "GPU:              $(get_gpu)"
echo "Audio driver:     $(get_audio_driver)"
echo "Chassis:          $(get_chassis_type)"
echo "EFI support:      ${HAS_EFI_SUPPORT}"
echo "Has battery:      ${IS_BATTERY_DEVICE}"

if ${HAS_GUI}; then
    echo "Display:          $(get_screen_width)x$(get_screen_height), $(get_screen_dpi) DPI"
    echo "DE:               ${DESKTOP_ENVIRONMENT}"
    echo "Development:      ${IS_DEVELOPMENT_DEVICE}"
    echo "Gaming:           ${IS_GAMING_DEVICE}"
    echo "General purpose:  ${IS_GENERAL_PURPOSE_DEVICE}"
    echo "Powerful system:  ${POWERFUL_PC}"
fi

echo ''

# Remove the MOTD
[ -f "${ROOT_ETC}/motd" ] && remove "${ROOT_ETC}/motd"

# Package management
if [ "${OS}" != 'Windows' ]; then
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
[ "${OS}" = 'Linux' ] && run_script_as_su "${REPO_SCRIPTS_DIR}/update-rcs.sh"

# Update the resources
if [ "${OS}" = 'Linux' ]; then
    run_script "${REPO_SCRIPTS_DIR}/update-resources.sh"
    run_script_as_su "${REPO_SCRIPTS_DIR}/update-resources.sh"
fi

# Configure and customise the system
run_script "${REPO_SCRIPTS_DIR}/configure-system.sh" # Run after update-rcs.sh
if [ "${OS}" = 'Linux' ] \
&& ${HAS_GUI} \
&& ! [[ "${DISTRO}" =~ 'WSL' ]]; then
    run_script "${REPO_SCRIPTS_DIR}/configure-launchers.sh"
    run_script "${REPO_SCRIPTS_DIR}/configure-autostart-apps.sh"
    run_script "${REPO_SCRIPTS_DIR}/configure-default-apps.sh"
fi

run_script "${REPO_SCRIPTS_DIR}/configure-permissions.sh" # Run after install-packages.sh
if [ "${OS}" = 'Linux' ]; then
    run_script_as_su "${REPO_SCRIPTS_DIR}/configure-locale.sh"
    run_script_as_su "${REPO_SCRIPTS_DIR}/configure-system-time.sh"
fi
[ "${DISTRO_FAMILY}" != 'Android' ] && run_script_as_su "${REPO_SCRIPTS_DIR}/update-profiles.sh"

if [ "${OS}" = 'Linux' ]; then
    run_script_as_su "${REPO_SCRIPTS_DIR}/enable-services.sh"
    does_bin_exist 'grub-mkconfig' && run_script_as_su "${REPO_SCRIPTS_DIR}/update-grub.sh" # Run after configure-system.sh
fi
run_script "${REPO_SCRIPTS_DIR}/configure-directories.sh"

run_script "${REPO_SCRIPTS_DIR}/git/setup-gpg-key.sh"

run_script "${REPO_SCRIPTS_DIR}/clean-files.sh"

# Assign users and groups
[ "${OS}" = 'Linux' ] && run_script_as_su "${REPO_SCRIPTS_DIR}/assign-users-and-groups.sh"

source "${HOME}/.bashrc"
