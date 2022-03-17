#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"
source "scripts/common/package-management.sh"
source "scripts/common/service-management.sh"

DNS_CACHE_TTL=20 # Minutes
DNS_CACHE_SIZE=10000 # Entries

PIHOLE_DNSMASQ_CONFIG_PATH="${ROOT_ETC}/dnsmasq.d/01-pihole.conf"

install_native_package pi-hole-server
install_native_package php-sqlite

install_native_package_dependency lighttpd
install_native_package_dependency php-cgi

update_file_if_distinct "/usr/share/pihole/configs/lighttpd.example.conf" "/etc/lighttpd/lighttpd.conf"

sudo sed -i 's/^;\(extension=pdo_sqlite\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sockets\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^;\(extension=sqlite3\)$/\1/g' "/etc/php/php.ini"
sudo sed -i 's/^server\.port.*$/server.port = 8093/' "/etc/lighttpd/lighttpd.conf"
sudo sed -i 's/^#DBINTERVAL=.*/DBINTERVAL=60.0/' "/etc/pihole/pihole-FTL.conf"
sudo sed -i 's/^#IGNORE_LOCALHOST=.*/IGNORE_LOCALHOST=yes/' "/etc/pihole/pihole-FTL.conf"

set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "cache-size" $((DNS_CACHE_SIZE))
set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "local-ttl" $((DNS_CACHE_TTL*60*3))
set_config_value "${PIHOLE_DNSMASQ_CONFIG_PATH}" "min-cache-ttl" $((DNS_CACHE_TTL*60))

disable_service "systemd-resolved"
enable_service "pihole-FTL"
enable_service "lighttpd"

sudo usermod -a -G http pihole

pihole -a -p

for I in {1..5}; do
    echo "UPDATE THE HOSTS FILE!!!    RESTART THE SYSTEM!!!"
done
