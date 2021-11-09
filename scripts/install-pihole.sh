#!/bin/bash
source "scripts/common/package-management.sh"

install-pkg pi-hole-server
install-pkg php-sqlite

install-dep lighttpd
install-dep php-cgi

sudo cp "/usr/share/pihole/configs/lighttpd.example.conf" "/etc/lighttpd/lighttpd.conf"

sudo sed -i 's/^;\(extension=pdo_sqlite\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sockets\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sqlite3\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^server\.port.*$/server.port = 8093/' "/etc/lighttpd/lighttpd.conf"
sudo sed -i 's/^#DBINTERVAL=.*/DBINTERVAL=60.0/' "/etc/pihole/pihole-FTL.conf"
sudo sed -i 's/^#IGNORE_LOCALHOST=.*/IGNORE_LOCALHOST=yes/' "/etc/pihole/pihole-FTL.conf"

set_config_value "/etc/dnsmasq.d/01-pihole.conf" "local-ttl" 3600 # 60 minutes
set_config_value "/etc/dnsmasq.d/01-pihole.conf" "min-cache-ttl" 900 # 15 minutes

sudo systemctl disable systemd-resolved
sudo systemctl enable pihole-FTL
sudo systemctl enable lighttpd

sudo systemctl stop systemd-resolved
sudo systemctl start pihole-FTL
sudo systemctl start lighttpd

sudo usermod -a -G http pihole

pihole -a -p

echo "UPDATE THE HOSTS FILE!!!"
