#!/usr/bin/env bash

Install_PHP_LDAP()
{
    if /usr/local/php/bin/php -m|grep -q "ldap"; then
        Echo_Red "PHP extension 'ldap' has already loaded!"
        exit 1
    else
        PHP_With_LDAP
        cd ${SRC_DIR}/php-${cur_php_ver}/ext/ldap
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config ${with_ldap}
        Make_And_Install
        cat >/usr/local/php/conf.d/bz2.ini<<EOF
extension = "ldap.so"
EOF
        if [[ -s "${php_ext_dir}/ldap.so" ]]; then
            Echo_Green "PHP extension 'ldap' has been successfully installed."
        else
            Echo_Red "PHP extension 'ldap' install failed."
        fi
    fi
}