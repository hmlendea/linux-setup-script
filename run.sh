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

echo "I need sudo access!"
sudo printf "Thank you!\n\n"

function execute-script() {
    SCRIPT_PATH="$1"

    echo "Executing as $USER: '$EXEDIR/$SCRIPT_PATH'..."
    /usr/bin/bash "$EXEDIR/$SCRIPT_PATH"
}

function execute-script-superuser() {
    SCRIPT_PATH="$1"

    echo "Executing as root: '$EXEDIR/$SCRIPT_PATH'..."
    sudo /usr/bin/bash "$EXEDIR/$SCRIPT_PATH"
}

execute-script "scripts/install-pkgs.sh"

echo "Updating the system..."
if [ -f "/usr/bin/yaourt" ]; then
    yaourt -Suya --noconfirm --needed
else
    sudo pacman -Suy
fi

UNUSED_DEPS=$(pacman -Qdtq)
UNUSED_DEPS_COUNT=$(echo $UNUSED_DEPS | wc -w)

echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT)..."
if [ -n "$UNUSED_DEPS" ]; then
    sudo pacman --noconfirm -Rns $UNUSED_DEPS
fi

execute-script "scripts/config-system.sh"
execute-script-superuser "scripts/customise-launchers.sh"

execute-script "scripts/update-rcs.sh"
execute-script-superuser "scripts/update-rcs.sh"

sudo update-grub
