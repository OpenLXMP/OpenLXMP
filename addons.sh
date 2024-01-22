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
. ${CUR_DIR}/include/php.sh
. ${CUR_DIR}/include/redis.sh
. ${CUR_DIR}/include/memcached.sh
. ${CUR_DIR}/include/opcache.sh
. ${CUR_DIR}/include/php_ext.sh

clear
printf "
+------------------------------------------------------------------------+
+                 Addons installation script for OpenLXMP                +
+                          https://OpenLXMP.com                          +
+------------------------------------------------------------------------+
"

while [[ $# -gt 0 ]]; do
    case $1 in
        --redis)
            addons_select='redis'
            ;;
        --memcached)
            addons_select='memcached'
            ;;
        --opcache)
            addons_select='opcache'
            ;;
        --php_fileinfo)
            addons_select='php'
            Enable_PHP_Fileinfo='y'
            ;;
        --php_ldap)
            addons_select='php'
            Enable_PHP_LDAP='y'
            ;;
        --php_bz2)
            addons_select='php'
            Enable_PHP_Bz2='y'
            ;;
        --php_sodium)
            addons_select='php'
            Enable_PHP_Sodium='y'
            ;;
        --php_imap)
            addons_select='php'
            Enable_PHP_Imap='y'
            ;;
        --help|-h)
            Addons_Help_Menu
            exit 0
            ;;
        *)
            Echo_Red "Invalid option: $1"
            Addons_Help_Menu
            exit 1
            ;;
    esac
    shift
done

if [[ "${addons_select}" == "" ]]; then
    Addons_Menu
    case "${addons_select_num}" in
        1) addons_select="redis" ;;
        2) addons_select="memcached" ;;
        3) addons_select="opcache" ;;
        4) addons_select='php'; Enable_PHP_Fileinfo='y' ;;
        5) addons_select='php'; Enable_PHP_LDAP='y' ;;
        6) addons_select='php'; Enable_PHP_Bz2='y' ;;
        7) addons_select='php'; Enable_PHP_Sodium='y' ;;
        8) addons_select='php'; Enable_PHP_Imap='y' ;;
        *) Echo_Red "Invalid input, Please re-enter"; Addons_Menu ;;
    esac
fi

case $addons_select in
    redis)
        Install_Redis 2>&1 | tee /root/openlxmp-addons-redis.log
        ;;
    memcached)
        Install_Memcached 2>&1 | tee /root/openlxmp-addons-memcached.log
        ;;
    opcache)
        Install_Opcache 2>&1 | tee /root/openlxmp-upgrade-opcache.log
        ;;
    php)
        Install_PHP_Ext 2>&1 | tee /root/openlxmp-addons-php-ext.log
        ;;
esac
