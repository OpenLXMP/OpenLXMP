#!/usr/bin/env bash

Install_Redis()
{
    Echo_Blue "Installing Redis..."
    Press_Start
    Print_Sys_Info

    cd ${SRC_DIR}
    Get_Ext_Dir
    Download "${Redis_URL}" "${Redis_Ver}.tar.gz"
    Tar_Cd ${Redis_Ver}.tar.gz ${Redis_Ver}
    if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
        make PREFIX=/usr/local/redis install
    elif [[ "${ARCH}" == "i686" || "${ARCH}" == "i386" ]]; then
        make CFLAGS="-march=i686" PREFIX=/usr/local/redis install
    fi
    mkdir -p /usr/local/redis/etc/
    \cp redis.conf  /usr/local/redis/etc/
    sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
    \cp utils/redis_init_script /etc/init.d/redis
    chmod +x /etc/init.d/redis
    sed -i 's@/etc/redis/${REDISPORT}.conf@/usr/local/redis/etc/redis.conf@g' /etc/init.d/redis
    sed -i 's@/usr/local/bin@/usr/local/redis/bin@g' /etc/init.d/redis
    \cp ${CUR_DIR}/init.d/redis.service /etc/systemd/system/redis.service

    Echo_Blue "Installing php-redis..."
    echo "Current PHP version: ${cur_php_ver}"
    cd ${SRC_DIR}
    if [[ ${cur_php_ver} =~ ^5\.6\.[0-9]+$ ]]; then
        Download "${PHP5_Redis_URL}" "${PHP5_Redis_Ver}.tgz"
        Tar_Cd ${PHP5_Redis_Ver}.tgz ${PHP5_Redis_Ver}
    else
        Download "${PHP_Redis_URL}" "${PHP_Redis_Ver}.tgz"
        Tar_Cd ${PHP_Redis_Ver}.tgz ${PHP_Redis_Ver}
    fi
    /usr/local/php/bin/phpize
    ./configure --with-php-config=/usr/local/php/bin/php-config
    Make_And_Install
    cd ${SRC_DIR}
    rm -rf ${Redis_Ver}

    cat >/usr/local/php/conf.d/redis.ini<<EOF
extension = "redis.so"
EOF

    if [ "$(sysctl -n vm.overcommit_memory)" -eq 1 ]; then
        echo "vm.overcommit_memory is already set to 1."
    else
        sysctl vm.overcommit_memory=1
        if grep -q "vm.overcommit_memory" /etc/sysctl.conf; then
            sed -i 's/\(vm.overcommit_memory *= *\).*/\11/' /etc/sysctl.conf
        else
            echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
        fi
        echo "vm.overcommit_memory has been set to 1."
    fi

    if [[ -s /usr/local/redis/bin/redis-server && -s "${php_ext_dir}/redis.so" ]]; then
        Enable_Startup redis
        systemctl start redis
        Echo_Green "Redis Server has been successfully installed."
    else
        Echo_Red "Redis Server install failed."
    fi
}