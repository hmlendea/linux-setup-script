#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_SCRIPTS_DIR}/common/common.sh"
source "${REPO_SCRIPTS_DIR}/common/config.sh"
source "${REPO_SCRIPTS_DIR}/common/package-management.sh"
source "${REPO_SCRIPTS_DIR}/common/service-management.sh"

install_native_package "nextcloud"

if ! is_native_package_installed "php" && \
   ! is_native_package_installed "php-legacy"; then
    install_native_package "php-legacy"
fi

install_native_package_dependency "php-imagick"
install_native_package_dependency "mariadb"

[ ! -f "${SYSTEM_PHP_CONFIG_FILE}" ] && SYSTEM_PHP_CONFIG_FILE="${ROOT_ETC}/php-legacy/php.ini"

if [ ! -f "${SYSTEM_PHP_CONFIG_FILE}" ]; then
    echo "ERROR: Cannot locate the php.ini system-level configuration file!"
    exit 1
fi

set_config_value "${NEXTCLOUD_PHP_CONFIG_FILE}" "date.timezone" "Europe/Bucharest"
set_config_value "${NEXTCLOUD_PHP_CONFIG_FILE}" "memory_limit" "512M"
set_config_value "${NEXTCLOUD_PHP_CONFIG_FILE}" "open_basedir" "/var/lib/nextcloud:/tmp:/usr/share/webapps/nextcloud:/etc/webapps/nextcloud:/dev/urandom:/usr/lib/php-legacy/modules:/var/log/nextcloud:/proc/meminfo:/proc/cpuinfo"

set_config_value --separator " " --section "mysqld" "${MARIADB_SERVER_CONFIG_FILE}" "skip_networking" " "
set_config_value --section "mysqld" "${MARIADB_SERVER_CONFIG_FILE}" "transaction_isolation" "READ-COMMITTED"

run_as_su mariadb-install-db --user=mysql --basedir=${ROOT_USR} --datadir=${ROOT_VAR_LIB}/mysql
enable_service "mariadb"
