#!/usr/bin/env bash

. ${CUR_DIR}/include/php_fileinfo.sh
. ${CUR_DIR}/include/php_ldap.sh
. ${CUR_DIR}/include/php_bz2.sh
. ${CUR_DIR}/include/php_sodium.sh
. ${CUR_DIR}/include/php_imap.sh

Install_PHP_Ext()
{
    Echo_Blue "Installing PHP Extesion..."
    Press_Start
    Print_Sys_Info

    cd ${SRC_DIR}
    Get_Ext_Dir
    Download "https://www.php.net/distributions/php-${cur_php_ver}.tar.xz"
    Tar_Cd php-${cur_php_ver}.tar.xz php-${cur_php_ver}

    if [[ "${Enable_PHP_Fileinfo}" == "y" ]]; then
        Install_PHP_Fileinfo
    fi
    if [[ "${Enable_PHP_LDAP}" == "y" ]]; then
        Install_PHP_LDAP
    fi
    if [[ "${Enable_PHP_Bz2}" == "y" ]]; then
        Install_PHP_Bz2
    fi
    if [[ "${Enable_PHP_Sodium}" == "y" ]]; then
        Install_PHP_Sodium
    fi
    if [[ "${Enable_PHP_Imap}" == "y" ]]; then
        Install_PHP_Imap
    fi
}