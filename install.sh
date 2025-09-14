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
STACK=''

LXMP_Ver='1.0'
. ${CUR_DIR}/include/main.sh
Get_Distro_Info
. ${CUR_DIR}/openlxmp.conf
. ${CUR_DIR}/include/version.sh
. ${CUR_DIR}/include/menu.sh
. ${CUR_DIR}/include/init.sh
. ${CUR_DIR}/include/nginx.sh
. ${CUR_DIR}/include/mysql.sh
. ${CUR_DIR}/include/php.sh
. ${CUR_DIR}/include/apache.sh
. ${CUR_DIR}/include/web.sh
. ${CUR_DIR}/include/check.sh
. ${CUR_DIR}/include/only.sh

clear
printf "
+------------------------------------------------------------------------+
+              OpenLXMP                                                  +
+            https://OpenLXMP.com                                        +
+------------------------------------------------------------------------+
"

Init()
{
    Press_Start
    Print_Sys_Info
    Print_Install_Info
    Set_Timezone
    Sync_DateTime
    Disable_Selinux
    if [[ "${PM}" == "yum" ]]; then
        Yum_Remove_Packages
        Yum_Install_Dependency
    elif [[ "${PM}" == "apt" ]]; then
        Apt_Remove_packages
        Apt_Install_Dependency
    fi
    Check_Openssl
    Download_Files
    Install_Libiconv
    Install_Mhash
    Install_Mcrypt
    Install_Freetype
    if [[ "${PM}" == "yum" ]]; then
        Redhat_Lib_Opt
    elif [[ "${PM}" == "apt" ]]; then
        Debian_Lib_Opt
    fi
}

LNMP_Stack()
{
    Main_Menu
    Init
    Install_Nginx
    case "${DBSelect}" in
        1) Install_MySQL_55 ;;
        2) Install_MySQL_56 ;;
        3) Install_MySQL_57 ;;
        4) Install_MySQL_80 ;;
        5) Install_MySQL_84 ;;
    esac

    PHP_Options
    case "${PHPSelect}" in
        1) Install_PHP_56 ;;
        2) Install_PHP_70 ;;
        3) Install_PHP_71 ;;
        4) Install_PHP_72 ;;
        5) Install_PHP_73 ;;
        6) Install_PHP_74 ;;
        7) Install_PHP_80 ;;
        8) Install_PHP_81 ;;
        9) Install_PHP_82 ;;
        10) Install_PHP_83 ;;
        11) Install_PHP_84 ;;
    esac
    Install_Default_Web
    LNMP_Check
}

LAMP_Stack()
{
    Main_Menu
    Init
    Install_Apache
    case "${DBSelect}" in
        1) Install_MySQL_55 ;;
        2) Install_MySQL_56 ;;
        3) Install_MySQL_57 ;;
        4) Install_MySQL_80 ;;
        5) Install_MySQL_84 ;;
    esac

    PHP_Options
    case "${PHPSelect}" in
        1) Install_PHP_56 ;;
        2) Install_PHP_70 ;;
        3) Install_PHP_71 ;;
        4) Install_PHP_72 ;;
        5) Install_PHP_73 ;;
        6) Install_PHP_74 ;;
        7) Install_PHP_80 ;;
        8) Install_PHP_81 ;;
        9) Install_PHP_82 ;;
        10) Install_PHP_83 ;;
        11) Install_PHP_84 ;;
    esac
    Install_Default_Web
    LAMP_Check
}


action=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lnmp)
            if [[ -z $action ]]; then
                action="lnmp"
            else
                echo "Only one of --lnmp, --lamp, --nginx, or --mysql can be specified."
                Help_Menu
                exit 1
            fi
            ;;
        --lamp)
            if [[ -z $action ]]; then
                action="lamp"
            else
                echo "Only one of --lnmp, --lamp, --nginx, or --mysql can be specified."
                Help_Menu
                exit 1
            fi
            ;;
        --nginx)
            if [[ -z $action ]]; then
                action="nginx"
            else
                echo "Only one of --lnmp, --lamp, --nginx, or --mysql can be specified."
                Help_Menu
                exit 1
            fi
            ;;
        --mysql)
            if [[ -z $action ]]; then
                action="mysql"
            else
                echo "Only one of --lnmp, --lamp, --nginx, or --mysql can be specified."
                Help_Menu
                exit 1
            fi
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
            Help_Menu
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            Help_Menu
            exit 1
            ;;
    esac
    shift
done

if [[ -z $action ]]; then
    action="lnmp"
fi

case "$action" in
    lnmp)
        STACK='lnmp'
        LNMP_Stack 2>&1 | tee /root/openlxmp-install.log
        ;;
    lamp)
        STACK='lamp'
        LAMP_Stack 2>&1 | tee /root/openlxmp-install.log
        ;;
    nginx)
        Only_Install_Nginx 2>&1 | tee /root/openlxmp-nginx-install.log
        ;;
    mysql)
        Only_Install_MySQL 2>&1 | tee /root/openlxmp-mysql-install.log
        ;;
    *)
        echo "Unknown action: $action"
        Help_Menu
        exit 1
        ;;
esac