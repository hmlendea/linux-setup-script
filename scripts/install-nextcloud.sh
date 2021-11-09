#!/bin/bash

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR_PATH=$(dirname ${SCRIPT_PATH})
cd ${SCRIPT_DIR_PATH}

PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
PHP_CONFIG_FILE="/etc/php/php.ini"
APACHE_CONFIG_DIR="/etc/httpd/conf"
APACHE_CONFIG_FILE="${APACHE_CONFIG_DIR}/httpd.conf"
MYSQL_CONFIG_FILE="/etc/my.cnf"

source "${SCRIPT_DIR_PATH}/common/package-manager-functions.sh"

install-pkg nextcloud
install-dep php-apache
install-dep php-sqlite
install-dep php-fpm
install-dep php-intl

install-pkg libexif

sudo mkdir -p "${PACMAN_HOOKS_DIR}"

NEXTCLOUD_PACMAN_HOOKS_FILE="${PACMAN_HOOKS_DIR}/nextcloud.hook"
NEXTCLOUD_APACHE_CONF_FILE="/etc/httpd/conf/extra/nextcloud.conf"
NEXTCLOUD_DATA_DIR="/var/nextcloud"
NEXTCLOUD_WEBAPPS_APPS_DIR="/usr/share/webapps/nextcloud/apps"
NEXTCLOUD_WEBAPPS_DATA_DIR="/usr/share/webapps/nextcloud/data"
NEXTCLOUD_WEBAPPS_CONFIG_FILE="/etc/webapps/nextcloud/config"

if [ ! -f "${NEXTCLOUD_PACMAN_HOOKS_FILE}" ]; then
    echo "Creating the pacman hook for Nextcloud..."
    {
        echo "[Trigger]"
        echo "Operation = Install"
        echo "Operation = Upgrade"
        echo "Type = Package"
        echo "Target = nextcloud"
        echo "Target = nextcloud-app-*"
        echo ""
        echo "[Action]"
        echo "Description = Update Nextcloud installation"
        echo "When = PostTransaction"
        echo "Exec = /usr/bin/runuser -u http -- /usr/bin/php /usr/share/webapps/nextcloud/occ upgrade"
    } | sudo tee "${NEXTCLOUD_PACMAN_HOOKS_FILE}" > /dev/null
fi

sudo sed -i 's/^;\(session.save_path = \"\/tmp\"\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=exif\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=gd\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=iconv\)$/\1/g' "${PHP_CONFIG_FILE}" # Required by certain apps
sudo sed -i 's/^;\(extension=pdo_mysql\)$/\1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(extension=mysqli\)$/\1/g' "${PHP_CONFIG_FILE}"

sudo sed -i 's/^;\(opcache.enable=\)=.*$/\1=1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(opcache.interned_strings_buffer\)=.*$/\1=8/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(opcache.max_accelerated_files\)=.*$/\1=10000/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(opcache.max_memory_consumption\)=.*$/\1=128/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(opcache.save_comments\)=.*$/\1=1/g' "${PHP_CONFIG_FILE}"
sudo sed -i 's/^;\(opcache.revalidate_freq\)=.*$/\1=1/g' "${PHP_CONFIG_FILE}"

sudo sed -i 's/^\(memory_limit\) *=.*$/\1=512M/g' "${PHP_CONFIG_FILE}"

install-pkg mariadb

sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

if [ $(grep -c "\[mysqld\]" "${MYSQL_CONFIG_FILE}") -eq 0 ]; then
    echo "Enabling READ-COMMITED on the database..."
    {
        echo "[mysqld]"
        echo "transaction_isolation = READ-COMMITTED"
        echo "binlog_format = ROW"
        echo "innodb_buffer_pool_size=1G"
        echo "innodb_io_capacity=4000"
    } | sudo tee -a "${MYSQL_CONFIG_FILE}" > /dev/null
elif [ $(grep -c "transaction_isolation = READ-COMMITTED" "${MYSQL_CONFIG_FILE}") -eq 0 ]; then
    echo "@@@@ PLEASE CONFIGURE MYSQL MANUALLY @@@@"
fi

sudo systemctl enable mariadb
sudo systemctl start mariadb

if [ ! -f "${APACHE_CONFIG_DIR}/extra/nextcloud.conf" ]; then
    echo "Writing the Nextcloud configuration for Apache..."
    sudo cp "/etc/webapps/nextcloud/apache.example.conf" "${APACHE_CONFIG_DIR}/extra/nextcloud.conf"

fi
if [ $(grep -c "Include conf/extra/nextcloud.conf" "${APACHE_CONFIG_FILE}") -eq 0 ]; then
    echo "Including the Nextcloud configuration in Apache's config..."
    echo "Include conf/extra/nextcloud.conf" | sudo tee -a "${APACHE_CONFIG_FILE}" > /dev/null
fi

if [ ! -f "${APACHE_CONFIG_DIR}/extra/php-fpm.conf" ]; then
    echo "Writing the php-fpm configuration for Apache..."
    {
        echo "DirectoryIndex index.php index.html"
        echo "<FilesMatch \.php$>"
        echo "    SetHandler \"proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost/\""
        echo "</FilesMatch>"
    } | sudo tee "${APACHE_CONFIG_DIR}/extra/php-fpm.conf" > /dev/null
fi
if [ $(grep -c "Include conf/extra/php-fpm.conf" "${APACHE_CONFIG_FILE}") -eq 0 ]; then
    echo "Including the php-fpm configuration in Apache's config..."
    echo "Include conf/extra/php-fpm.conf" | sudo tee -a "${APACHE_CONFIG_FILE}" > /dev/null
fi

sudo sed -i 's/^#\(LoadModule proxy_module modules\/mod_proxy\.so\)$/\1/g' "${APACHE_CONFIG_FILE}"
sudo sed -i 's/^#\(LoadModule proxy_fcgi_module modules\/mod_proxy_fcgi\.so\)$/\1/g' "${APACHE_CONFIG_FILE}"
sudo sed -i 's/^#\(LoadModule socache_shmcb_module modules\/mod_socache_shmcb\.so\)$/\1/g' "${APACHE_CONFIG_FILE}"
sudo sed -i 's/^#\(LoadModule ssl_module modules\/mod_ssl\.so\)$/\1/g' "${APACHE_CONFIG_FILE}"
sudo sed -i 's/^Listen [0-9]*$/Listen 8897/g' "${APACHE_CONFIG_FILE}"

if [ $(grep -c "^Include conf/extra/httpd-ssl.conf$" "${APACHE_CONFIG_FILE}") -eq 0 ]; then
    echo "Including the SSL configuration in Apache's config..."
    sudo sed -i 's/^#\(Include conf\/extra\/httpd-ssl\.conf\)$/\1/g' "${APACHE_CONFIG_FILE}"
fi

#if [ $(grep -c "^Include conf/extra/httpd-vhosts.conf$" "${APACHE_CONFIG_FILE}") -eq 0 ]; then
#    echo "Including the vHosts configuration in Apache's config..."
#    sudo sed -i 's/^#\(Include conf\/extra\/httpd-vhosts\.conf\)$/\1/g' "${APACHE_CONFIG_FILE}"
#fi

sudo systemctl enable php-fpm
sudo systemctl enable httpd

sudo systemctl restart php-fpm
sudo systemctl restart httpd

for DIR in "/${NEXTCLOUD_DATA_DIR}" \
           "/usr/share/webapps/nextcloud/data" \
           "/usr/share/webapps/nextcloud/apps"; do
    if [ ! -d "${DIR}" ]; then
        echo "Configuring the \"${DIR}\" directory..."
        sudo mkdir -p "${DIR}"
        sudo chown http:http "${DIR}"
        sudo chmod 750 "${DIR}"
    fi
done

PHP_FPM_OVERRIDE_CONF_FILE="/etc/systemd/system/php-fpm.service.d/override.conf"
if [ ! -f "${PHP_FPM_OVERRIDE_CONF_FILE}" ]; then
    PHP_FPM_SERVICE_DIR=$(dirname "${PHP_FPM_OVERRIDE_CONF_FILE}")
    sudo mkdir -p "${PHP_FPM_SERVICE_DIR}"

    echo "Creating the php-fpm override config..."
    {
        echo "[Service]"
        echo "ReadWritePaths = ${NEXTCLOUD_WEBAPPS_APPS_DIR}"
        echo "ReadWritePaths = ${NEXTCLOUD_WEBAPPS_DATA_DIR}"
        echo "ReadWritePaths = ${NEXTCLOUD_WEBAPPS_CONFIG_FILE}"
        echo "ReadWritePaths = ${NEXTCLOUD_DATA_DIR}"
    } | sudo tee "${PHP_FPM_OVERRIDE_CONF_FILE}" > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl restart php-fpm
fi

sudo chown http:http /usr/share/webapps/nextcloud/ -R
