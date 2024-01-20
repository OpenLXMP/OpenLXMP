#!/usr/bin/env bash

Install_PHP_Bz2()
{
    if /usr/local/php/bin/php -m|grep -q "bz2"; then
        Echo_Red "PHP extension 'bz2' has already loaded!"
        exit 1
    else
        PHP_With_Bz2
        cd ${SRC_DIR}/php-${cur_php_ver}/ext/bz2
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config
        Make_And_Install
        cat >/usr/local/php/conf.d/bz2.ini<<EOF
extension = "bz2.so"
EOF
        if [[ -s "${php_ext_dir}/bz2.so" ]]; then
            Echo_Green "PHP extension 'bz2' has been successfully installed."
        else
            Echo_Red "PHP extension 'bz2' install failed."
        fi
    fi
}