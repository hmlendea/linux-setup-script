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

CPU_ARCHITECTURE=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g')
if [[ "${CPU_ARCHITECTURE}" == "x86_64" ]]; then
    ARCH="x86_64"
else
    ARCH="arm"
fi

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

function update-gnome-extensions() {
    if [ -f "/usr/bin/gnome-shell-extension-installer" ]; then
        echo "Updating GNOME extensions..."
        gnome-shell-extension-installer --yes --update --restart-shell
    fi
}

function remove-unused-dependencies() {
    echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT)..."

    UNUSED_DEPS=$(pacman -Qdtq)
    UNUSED_DEPS_COUNT=$(echo $UNUSED_DEPS | wc -w)

    if [ -n "$UNUSED_DEPS" ]; then
        sudo pacman --noconfirm -Rns $UNUSED_DEPS
    fi
}

echo "ARCH: ${ARCH}"

execute-script "install-pkgs.sh"

update-system
update-gnome-extensions
remove-unused-dependencies

execute-script "config-system.sh"

execute-script-superuser "set-system-locale-timedate.sh"
execute-script-superuser "install-profiles.sh"
execute-script-superuser "customise-launchers.sh"

execute-script "update-rcs.sh"
execute-script-superuser "update-rcs.sh"

execute-script "setup-git-gpg.sh"

execute-script "enable-services.sh"

if [[ "${ARCH}" == "x86_64" ]]; then
    sudo update-grub
fi

source ~/.bashrc

