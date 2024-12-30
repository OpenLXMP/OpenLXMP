#!/usr/bin/env bash

MySQL_Select_Menu()
{
    echo "===== Choose MySQL version ====="
    echo " 1. MySQL 5.5"
    echo " 2. MySQL 5.6 (Default)"
    echo " 3. MySQL 5.7"
    echo " 4. MySQL 8.0"
    echo " 5. MySQL 8.2"
    echo " 0. No DataBase installation"
    echo "================================"
    read -p "Please enter: " DBSelect
    case "${DBSelect}" in
        1) Echo_Blue "Install MySQL 5.5" ;;
        2) Echo_Blue "Install MySQL 5.6" ;;
        3) Echo_Blue "Install MySQL 5.7" ;;
        4) Echo_Blue "Install MySQL 8.0" ;;
        5) Echo_Blue "Install MySQL 8.2" ;;
        0) Echo_Blue "No Database installation" ;;
        *) Echo_Blue "Invalid input, defaulting to MySQL 5.6"; DBSelect='2' ;;
    esac
}

MySQL_Use_Bin()
{
    if [[ "${DBSelect}" =~ ^(1|2|3) ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "i686" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *) 
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    elif [[ "${DBSelect}" =~ ^4 ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "i686" || "${ARCH}" == "aarch64" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *) 
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    elif [[ "${DBSelect}" =~ ^5 ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                if [[ "${ARCH}" == "aarch64" ]]; then
                    GLIBC_VER='2.17'
                fi
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *) 
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    else
        Bin="n"
    fi
}

MySQL_Innodb_Option()
{
    read -p "Enable InnoDB? (y/n): " EnableInnoDB
    case ${EnableInnoDB} in
        y|Y)
            EnableInnoDB="y"
            ;;
        n|N)
            EnableInnoDB="n"
            ;;
        *) 
            Echo_Red "Invalid input, Default enable InnoDB"
            EnableInnoDB="y"
            ;;
    esac
}

Set_DB_Root_Password()
{
    read -p "Please enter MySQL root password: " DBRootPasswd
    if [[ -z "${DBRootPasswd}" ]]; then
        echo "No input, generate a random password"
        DBRootPasswd=$(tr -dc 'A-HJ-NP-Za-hj-km-np-z2-9' < /dev/urandom | head -c 10)
        echo "MySQL Root Password: ${DBRootPasswd}"
    fi
}

PHP_Select_Menu()
{
    echo "====== Choose PHP version ======"
    echo " 1.  PHP 5.6"
    echo " 2.  PHP 7.0"
    echo " 3.  PHP 7.1"
    echo " 4.  PHP 7.2"
    echo " 5.  PHP 7.3"
    echo " 6.  PHP 7.4"
    echo " 7.  PHP 8.0"
    echo " 8.  PHP 8.1"
    echo " 9.  PHP 8.2"
    echo " 10. PHP 8.3"
    echo "================================"
    read -p "Please enter: " PHPSelect
    case "${PHPSelect}" in
        1) Echo_Blue "Install PHP 5.6"; PHP_Ver=${PHP56_Ver} ;;
        2) Echo_Blue "Install PHP 7.0"; PHP_Ver=${PHP70_Ver} ;;
        3) Echo_Blue "Install PHP 7.1"; PHP_Ver=${PHP71_Ver} ;;
        4) Echo_Blue "Install PHP 7.2"; PHP_Ver=${PHP72_Ver} ;;
        5) Echo_Blue "Install PHP 7.3"; PHP_Ver=${PHP73_Ver} ;;
        6) Echo_Blue "Install PHP 7.4"; PHP_Ver=${PHP74_Ver} ;;
        7) Echo_Blue "Install PHP 8.0"; PHP_Ver=${PHP80_Ver} ;;
        8) Echo_Blue "Install PHP 8.1"; PHP_Ver=${PHP81_Ver} ;;
        9) Echo_Blue "Install PHP 8.2"; PHP_Ver=${PHP82_Ver} ;;
        10) Echo_Blue "Install PHP 8.3"; PHP_Ver=${PHP83_Ver} ;;
        *) Echo_Blue "Invalid input, defaulting to PHP 7.4"; PHP_Ver=${PHP74_Ver}; PHPSelect='6' ;;
    esac
}

Main_Menu()
{
    MySQL_Select_Menu
    if [[ "${DBSelect}" != "0" ]]; then
        MySQL_Use_Bin
        MySQL_Innodb_Option
        Set_DB_Root_Password
    fi
    PHP_Select_Menu
}

Help_Menu()
{
    echo "Usage: $0 <--lnmp|--lamp> [OPTIONS]"
    echo "  -h, --help      Display this help menu"
    echo "  --lnmp          Install lnmp stack"
    echo "  --lamp          Install lamp stack"
    echo "  --nginx         Install only Nginx."
    echo "  --mysql         Install only MySQL."
    echo "  --php_fileinfo  Install PHP fileinfo extension"
    echo "  --php_ldap      Install PHP LDAP extension"
    echo "  --php_bz2       Install PHP bz2 extension"
    echo "  --php_sodium    Install PHP Sodium extension"
    echo "  --php_imap      Install PHP imap extension"
}

Upgrade_Help_Menu()
{
    echo "Usage: $0 <nginx|php|mysql> [OPTIONS]"
    echo "  -h, --help      Display this help menu"
    echo "  nginx           Upgrade Nginx"
    echo "  php             Upgrade PHP"
    echo "  mysql           Upgrade MySQL"
    echo "  --php_fileinfo  Upgrade PHP with fileinfo extension"
    echo "  --php_ldap      Upgrade PHP with LDAP extension"
    echo "  --php_bz2       Upgrade PHP with bz2 extension"
    echo "  --php_sodium    Upgrade PHP with Sodium extension"
    echo "  --php_imap      Upgrade PHP with imap extension"
}

Upgrade_Menu()
{
    echo "1. Upgrade Nginx"
    echo "2. Upgrade Apache"
    echo "3. Upgrade MySQL"
    echo "4. Upgrade PHP"
    echo "5. Upgrade PHPMyAdmin"
    read -p "Please enter number: " upgrade_selected_num
}

Addons_Help_Menu()
{
    echo "Usage: $0 [OPTIONS]"
    echo "  -h, --help      Display this help menu"
    echo "  --redis         Install Redis"
    echo "  --memcached     Install Memcached"
    echo "  --opcache       Install opcache"
    echo "  --php_fileinfo  Install PHP with fileinfo extension"
    echo "  --php_ldap      Install PHP with LDAP extension"
    echo "  --php_bz2       Install PHP with bz2 extension"
    echo "  --php_sodium    Install PHP with Sodium extension"
    echo "  --php_imap      Install PHP with imap extension"
}

Addons_Menu()
{
    echo "1. Install Redis"
    echo "2. Install Memcached"
    echo "3. Install opcache"
    echo "4. Install PHP with fileinfo extension"
    echo "5. Install PHP with LDAP extension"
    echo "6. Install PHP with bz2 extension"
    echo "7. Install PHP with Sodium extension"
    echo "8. Install PHP with imap extension"
    read -p "Please enter number: " addons_select_num
}