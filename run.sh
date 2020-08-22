#!/usr/bin/bash
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

ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g')

if [ -f "/usr/bin/sudo" ]; then
    echo "I need sudo access!"
    sudo printf "Thank you!\n\n"
else
    echo "ERROR: Please make sure 'sudo' is installed and configured"
    exit 1
fi

function execute-script() {
    SCRIPT_NAME="$1"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo "Executing as $USER: '${SCRIPT_PATH}'..."
    /usr/bin/bash "${SCRIPT_PATH}" "${ARCH}"
}

function execute-script-superuser() {
    SCRIPT_NAME="$1"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo "Executing as root: '${SCRIPT_PATH}'..."
    sudo /usr/bin/bash "${SCRIPT_PATH}" "${ARCH}"
}

function update-system() {
    echo "Updating the system..."
    if [ -f "/usr/bin/yaourt" ]; then
        yaourt -Suya --noconfirm --needed
    else
        sudo pacman -Suy
    fi
}

echo "ARCH: ${ARCH}"

execute-script-superuser "configure-repositories.sh"

# Manage packages and extensions
execute-script "install-pkgs.sh"
update-system
execute-script "update-extensions.sh"
execute-script-superuser "uninstall-pkgs.sh"

# Configure and customise the system
execute-script "config-system.sh"
execute-script-superuser "set-system-locale-timedate.sh"
execute-script-superuser "install-profiles.sh"
execute-script-superuser "customise-launchers.sh"
execute-script-superuser "enable-services.sh"
execute-script-superuser "update-grub.sh"

# Update the RCs
execute-script "update-rcs.sh"
execute-script-superuser "update-rcs.sh"

execute-script "setup-git-gpg.sh"

source ~/.bashrc
