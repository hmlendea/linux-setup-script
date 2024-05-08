#!/bin/bash
source "scripts/common/filesytem.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/common.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/config.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/package-management.sh"
source "${REPO_SCRIPTS_COMMON_DIR}/service-management.sh"

LIGHTTPD_CONFIG_FILE="${ROOT_ETC}/lighttpd/lighttpd.conf"
PHP_CONFIG_FILE="${ROOT_ETC}/php/php.ini"
PIHOLE_DNSMASQ_CONFIG_FILE="${ROOT_ETC}/dnsmasq.d/01-pihole.conf"
PIHOLE_FTL_CONFIG_FILE="${ROOT_ETC}/pihole/pihole-FTL.config"

DNS_CACHE_TTL=20 # Minutes
DNS_CACHE_SIZE=10000 # Entries


install_native_package 'pi-hole-server'
install_native_package 'php-sqlite'

install_native_package_dependency 'lighttpd'
install_native_package_dependency 'php-cgi'

update_file_if_distinct '/usr/share/pihole/configs/lighttpd.example.conf' '/etc/lighttpd/lighttpd.conf'

sudo sed -i 's/^;\(extension=pdo_sqlite\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=sockets\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=sqlite3\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^server\.port.*$/server.port = 8093/' "${LIGHTTPD_CONFIG_FILE}"
sudo sed -i 's/^#DBINTERVAL=.*/DBINTERVAL=60.0/' "${PIHOLE_FTL_CONFIG_FILE}"
sudo sed -i 's/^#IGNORE_LOCALHOST=.*/IGNORE_LOCALHOST=yes/' "${PIHOLE_FTL_CONFIG_FILE}"

set_config_value "${PIHOLE_DNSMASQ_CONFIG_FILE}" 'cache-size' $((DNS_CACHE_SIZE))
set_config_value "${PIHOLE_DNSMASQ_CONFIG_FILE}" 'local-ttl' $((DNS_CACHE_TTL*60*3))
set_config_value "${PIHOLE_DNSMASQ_CONFIG_FILE}" 'min-cache-ttl' $((DNS_CACHE_TTL*60))

disable_service 'systemd-resolved'
enable_service 'pihole-FTL'
enable_service 'lighttpd'

sudo usermod -a -G http pihole

pihole -a -p

for I in {1..5}; do
    echo 'UPDATE THE HOSTS FILE!!!    RESTART THE SYSTEM!!!'
done
