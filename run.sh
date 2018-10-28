#!/usr/bin/bash
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$EXEDIR/$SOURCE"
done
EXEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd "$EXEDIR"

function execute-script() {
    SCRIPT_PATH="$1"

    echo "Executing '$EXEDIR/$SCRIPT_PATH'..."
    /usr/bin/bash "$EXEDIR/$SCRIPT_PATH"
}

execute-script "scripts/install-pkgs.sh"
execute-script "scripts/config-system.sh"
execute-script "scripts/customise-launchers.sh"
