#!/usr/bin/env bash

Install_PHP_Sodium()
{
    if [[ ${cur_php_ver} =~ ^5\. ]]; then
        local php_sodium_ext="libsodium.so"
        if /usr/local/php/bin/php -m|grep -q "libsodium"; then
            Echo_Red "PHP extension 'sodium' has already loaded!"
            exit 1
        fi
    else
        local php_sodium_ext="sodium.so"
        if /usr/local/php/bin/php -m|grep -q "sodium"; then
            Echo_Red "PHP extension 'sodium' has already loaded!"
            exit 1
        fi
    fi

    if [[ "${PM}" == "yum" ]]; then
        yum install epel-release -y
        yum install libsodium-devel -y
    elif [[ "${PM}" == "apt" ]]; then
        apt-get install libsodium-dev -y
    fi

    if [[ ${cur_php_ver} =~ ^(7\.2\.|7\.3\.|7\.4\.|8\.) ]]; then
        cd ${SRC_DIR}/php-${cur_php_ver}/ext/sodium
    elif [[ ${cur_php_ver} =~ ^(7\.0\.|7\.1\.) ]]; then
        Download "${PHP7_Libsodium_URL}"
        Tar_Cd ${PHP7_Libsodium_Ver}.tgz ${PHP7_Libsodium_Ver}
    elif [[ ${cur_php_ver} =~ ^5\. ]]; then
        Download "${PHP5_Libsodium_URL}"
        Tar_Cd ${PHP5_Libsodium_Ver}.tgz ${PHP5_Libsodium_Ver}
    fi

    /usr/local/php/bin/phpize
    ./configure --with-php-config=/usr/local/php/bin/php-config
    Make_And_Install

    if [[ -s "${php_ext_dir}/${php_sodium_ext}" ]]; then
        cat >/usr/local/php/conf.d/sodium.ini<<EOF
extension = "${php_sodium_ext}"
EOF
        Echo_Green "PHP extension 'sodium' has been successfully installed."
    else
        Echo_Red "PHP extension 'sodium' install failed."
    fi
}