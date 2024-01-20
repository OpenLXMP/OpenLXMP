#!/usr/bin/env bash

Install_PHP_Imap()
{
    if /usr/local/php/bin/php -m|grep -q "imap"; then
        Echo_Red "PHP extension 'imap' has already loaded!"
        exit 1
    else
        PHP_With_Imap
        cd ${SRC_DIR}/php-${cur_php_ver}/ext/imap
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config ${with_imap}
        Make_And_Install
        cat >/usr/local/php/conf.d/imap.ini<<EOF
extension = "imap.so"
EOF
        if [[ -s "${php_ext_dir}/imap.so" ]]; then
            Echo_Green "PHP extension 'imap' has been successfully installed."
        else
            Echo_Red "PHP extension 'imap' install failed."
        fi
    fi
}