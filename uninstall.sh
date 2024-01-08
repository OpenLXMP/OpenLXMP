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

clear
printf "
+------------------------------------------------------------------------+
+                  Uninstall script for OpenLXMP                         +
+                        https://OpenLXMP.com                            +
+------------------------------------------------------------------------+
"

Press_Start
Check_Stack
if [[ "${STACK}" == "lnmp" ]]; then
    systemctl stop nginx
    systemctl stop php-fpm
    rm -rf /usr/local/nginx
    if [[ -d /usr/local/mysql ]]; then
        systemctl stop mysql
        Echo_Blue "Backup MySQL data directory..."
        mv ${Default_MySQL_Data_Dir} /root/backup_mysql_data_$(date +"%Y%m%d%H%M%S")
        rm -rf /usr/local/mysql
    fi
    rm -rf /usr/local/php
elif [[ "${STACK}" == "lamp" ]]; then
    systemctl stop httpd
    if [[ -d /usr/local/mysql ]]; then
        systemctl stop mysql
        Echo_Blue "Backup MySQL data directory..."
        mv ${Default_MySQL_Data_Dir} /root/backup_mysql_data_$(date +"%Y%m%d%H%M%S")
        rm -rf /usr/local/mysql
    fi
    rm -rf /usr/local/apache
    rm -rf /usr/local/php
else
    systemctl stop nginx
    systemctl stop httpd
    systemctl stop php-fpm
    rm -rf /usr/local/nginx
    rm -rf /usr/local/apache
    if [[ -d /usr/local/mysql ]]; then
        systemctl stop mysql
        Echo_Blue "Backup MySQL data directory..."
        mv ${Default_MySQL_Data_Dir} /root/backup_mysql_data_$(date +"%Y%m%d%H%M%S")
        rm -rf /usr/local/mysql
    fi
    rm -rf /usr/local/php
fi
Echo_Green "OpenLXMP has been successfully uninstalled."