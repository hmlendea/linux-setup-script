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

function execute-script() {
    SCRIPT_PATH="$1"

    echo "Executing '$EXEDIR/$SCRIPT_PATH'..."
    /usr/bin/bash "$EXEDIR/$SCRIPT_PATH"
}

function execute-script-superuser() {
    SCRIPT_PATH="$1"

    echo "Executing '$EXEDIR/$SCRIPT_PATH'..."
    sudo /usr/bin/bash "$EXEDIR/$SCRIPT_PATH"
}

execute-script "scripts/install-pkgs.sh"
execute-script "scripts/config-system.sh"
execute-script-superuser "scripts/customise-launchers.sh"

sudo update-grub
