#!/bin/bash

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR_PATH=$(dirname ${SCRIPT_PATH})
cd ${SCRIPT_DIR_PATH}

source "${SCRIPT_DIR_PATH}/package-manager-functions.sh"

install-pkg pi-hole-server
install-pkg php-sqlite

install-dep lighttpd
install-dep php-cgi

sudo sed -i 's/^;\(extension=pdo_sqlite\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sockets\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sqlite3\)$/\1/g' "/etc/php/php.ini"

cp "/usr/share/pihole/configs/lighttpd.example.conf" "/etc/lighttpd/lighttpd.conf"
sudo sed -i 's/^server\.port.*$/server.port = 8093/' "/etc/lighttpd/lighttpd.conf"

sudo systemctl disable systemd-resolved

sudo systemctl stop systemd-resolved

sudo systemctl enable pihole-FTL
sudo systemctl enable lighttpd

sudo systemctl start pihole-FTL
sudo systemctl start lighttpd

echo "SET UP THE PASSWORD! (EMPTY TO SKIP)"
pihole -a -p

echo "UPDATE THE HOSTS FILE!!!"
