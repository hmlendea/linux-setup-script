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

    echo -e "Executing as \e[1;94m$USER\e[0;39m: '${SCRIPT_PATH}'..."
    /usr/bin/bash "${SCRIPT_PATH}"
}

function execute-script-superuser() {
    SCRIPT_NAME="$1"
    SCRIPT_PATH="${EXEDIR}/scripts/${SCRIPT_NAME}"

    echo -e "Executing as \e[1;91mroot\e[0;39m: '${SCRIPT_PATH}'..."
    sudo /usr/bin/bash "${SCRIPT_PATH}"
}

function update-system() {
    echo "Updating the system..."
    if [ -f "/usr/bin/yaourt" ]; then
        yaourt -Suya --noconfirm --needed
    else
        sudo pacman -Suy
    fi
}

echo "Architecture: ${ARCH}"

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

if [ -f "/etc/systemd/system/display-manager.service" ]; then # Only customise launchers a DM is used
    execute-script-superuser "customise-launchers.sh"
fi

execute-script-superuser "enable-services.sh"
execute-script-superuser "update-grub.sh"

# Update the RCs
execute-script "update-rcs.sh"
execute-script-superuser "update-rcs.sh"

# Update the resources
execute-script "update-resources.sh"
execute-script-superuser "update-resources.sh"

execute-script "setup-git-gpg.sh"

# Clean journals older than 1 week
sudo journalctl -q --vacuum-time=7d

source ~/.bashrc
