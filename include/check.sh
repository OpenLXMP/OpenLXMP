#!/usr/bin/env bash

Check_Nginx()
{
    if [[ -s /usr/local/nginx/conf/nginx.conf && -s /usr/local/nginx/sbin/nginx ]]; then
        Echo_Green "Nginx: OK"
        Nginx_Install_Status='y'
    else
        Echo_Red "Error: Nginx install failed."
    fi
}

Check_MySQL()
{
    if [[ "${DBSelect}" == "0" ]]; then
        Echo_Green "Do not install MySQL/MariaDB."
        MySQL_Install_Status='y'
    else    
        if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
            Echo_Green "MySQL: OK"
            MySQL_Install_Status='y'
        else
            Echo_Red "Error: MySQL install failed."
        fi
    fi
}

Check_PHP()
{
    if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php.ini && -s /usr/local/php/bin/php ]]; then
        Echo_Green "PHP: OK"
        Echo_Green "PHP-FPM: OK"
        PHP_Install_Status='y'
    else
        Echo_Red "Error: PHP install failed."
    fi
}

Sucess_Msg()
{
    echo "You have successfully install LNMP."
}

Failed_Msg()
{
    Echo_Red "Failed to install LNMP!"
}

LNMP_Check()
{
    Check_Nginx
    Check_MySQL
    Check_PHP
    if [[ "${Nginx_Install_Status}" == "y" && "${MySQL_Install_Status}" == "y" && "${PHP_Install_Status}" == "y" ]]; then
        Sucess_Msg
    else
        Failed_Msg
    fi
}