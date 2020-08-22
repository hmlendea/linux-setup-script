#!/bin/bash

GRUB_CFG_FILE_PATH="/boot/grub/grub.cfg"

[ ! -f "/usr/bin/grub-reboot" ] && exit 1

if [ -f "/usr/bin/update-grub" ]; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

function rename-menuentry {
    OLD_NAME=${1}
    NEW_NAME=${2}

    sed -i 's/^menuentry ['\''\"]'"${OLD_NAME}"'[^'\''\"]*['\''\"]/menuentry '\'"${NEW_NAME}"\''/g' ${GRUB_CFG_FILE_PATH}
}

rename-menuentry "Arch Linux" "Linux"
rename-menuentry "Windows Boot Manager" "Windows"
