#!/usr/bin/env bash

Install_PHP_Fileinfo()
{
    if /usr/local/php/bin/php -m|grep -q "fileinfo"; then
        Echo_Red "PHP extension 'fileinfo' has already loaded!"
        exit 1
    else
        cd ${SRC_DIR}/php-${cur_php_ver}/ext/fileinfo
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config
        Make_And_Install
        cat >/usr/local/php/conf.d/bz2.ini<<EOF
extension = "fileinfo.so"
EOF
        if [[ -s "${php_ext_dir}/fileinfo.so" ]]; then
            Echo_Green "PHP extension 'fileinfo' has been successfully installed."
        else
            Echo_Red "PHP extension 'fileinfo' install failed."
        fi
    fi
}