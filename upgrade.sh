#!/usr/bin/env bash
# Author: OpenLXMP admin@OpenLXMP.com
# Website: https://OpenLXMP.com
# Github: https://github.com/OpenLXMP/OpenLXMP
# Version: 1.0
# 

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin

if [ $(id -u) != "0" ]; then
    echo "Error: You must run the current script with root or sudo."
    exit 1
fi

CUR_DIR=$(readlink -f $(dirname "$0"))
SRC_DIR="${CUR_DIR}/src"
STACK='lnmp'

LXMP_Ver='1.0'
. ${CUR_DIR}/include/main.sh
Get_Distro_Info
. ${CUR_DIR}/openlxmp.conf
. ${CUR_DIR}/include/version.sh
. ${CUR_DIR}/include/menu.sh
. ${CUR_DIR}/include/main.sh
. ${CUR_DIR}/include/init.sh
. ${CUR_DIR}/include/upgrade_nginx.sh
. ${CUR_DIR}/include/upgrade_apache.sh
. ${CUR_DIR}/include/upgrade_mysql.sh
. ${CUR_DIR}/include/php.sh
. ${CUR_DIR}/include/upgrade_php.sh
. ${CUR_DIR}/include/upgrade_phpmyadmin.sh

Upgrade_Date=$(date +"%Y%m%d%H%M%S")

clear
printf "
+------------------------------------------------------------------------+
+              Nginx/PHP/MySQL Upgrade script for OpenLXMP               +
+                        https://OpenLXMP.com                            +
+------------------------------------------------------------------------+
"

while [[ $# -gt 0 ]]; do
    case $1 in
        nginx|apache|mysql|php|phpmyadmin)
            upgrade_selected=$1
            ;;
        --php_fileinfo)
            Enable_PHP_Fileinfo='y'
            ;;
        --php_ldap)
            Enable_PHP_LDAP='y'
            ;;
        --php_bz2)
            Enable_PHP_Bz2='y'
            ;;
        --php_sodium)
            Enable_PHP_Sodium='y'
            ;;
        --php_imap)
            Enable_PHP_Imap='y'
            ;;
        --help|-h)
            Upgrade_Help_Menu
            exit 0
            ;;
        *)
            Echo_Red "Invalid option: $1"
            Upgrade_Help_Menu
            exit 1
            ;;
    esac
    shift
done

if [[ "${upgrade_selected}" == "" ]]; then
    Upgrade_Menu
    case "${upgrade_selected_num}" in
        1) upgrade_selected="nginx" ;;
        2) upgrade_selected="apache" ;;
        3) upgrade_selected="mysql" ;;
        4) upgrade_selected="php" ;;
        5) upgrade_selected="phpmyadmin" ;;
        *) Echo_Red "Invalid input, Please re-enter"; Upgrade_Menu ;;
    esac
fi

case $upgrade_selected in
    nginx)
        Upgrade_Nginx 2>&1 | tee /root/openlxmp-upgrade-nginx-${Upgrade_Date}.log
        ;;
    apache)
        echo "Upgrading Apache"
        Upgrade_Apache 2>&1 | tee /root/openlxmp-upgrade-apache-${Upgrade_Date}.log
        ;;
    php)
        Upgrade_PHP 2>&1 | tee /root/openlxmp-upgrade-php-${Upgrade_Date}.log
        ;;
    mysql)
        Upgrade_MySQL 2>&1 | tee /root/openlxmp-upgrade-mysql-${Upgrade_Date}.log
        ;;
    phpmyadmin)
        Upgrade_phpMyAdmin 2>&1 | tee /root/openlxmp-upgrade-phpmyadmin-${Upgrade_Date}.log
        ;;
esac


