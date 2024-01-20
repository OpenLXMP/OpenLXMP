#!/usr/bin/env bash

Install_Memcached()
{
    local php_mem=''
    Echo_Blue "Please choose which memcached PHP extension to install?"
    echo "1: php-memcache"
    echo "2: php-memcached"
    while [[ ${php_mem} != "1" && ${php_mem} != "2" ]]; do
        read -p "Please enter 1 or 2: " php_mem
    done
    Press_Start
    Print_Sys_Info

    cd ${SRC_DIR}
    Get_Ext_Dir
    Download "${Memcached_URL}" "${Memcached_Ver}.tar.gz"
    Tar_Cd ${Memcached_Ver}.tar.gz ${Memcached_Ver}
    ./configure --prefix=/usr/local/memcached
    Make_And_Install
    cd ${SRC_DIR}
    rm -rf ${Memcached_Ver}
    id -u nobody &>/dev/null || useradd -r -M -s /sbin/nologin nobody
    cat > /usr/local/memcached/memcached.conf<<EOF
IP="127.0.0.1,::1"
PORT="11211"
USER="nobody"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS=""
EOF
    if [[ ! -d /var/lock/subsys ]]; then
      mkdir -p /var/lock/subsys
    fi

    Echo_Blue "Installing php extension of memcached..."
    cd ${SRC_DIR}
    if [[ ${php_mem} == "1" ]]; then
        Echo_Blue "Install php-memcache..."
        local php_mem_ext="memcache.so"
        if [[ ${cur_php_ver} =~ ^5\. ]]; then
            Download "${PHP5_Memcache_URL}"
            Tar_Cd ${PHP5_Memcache_Ver}.tgz ${PHP5_Memcache_Ver}
        elif [[ ${cur_php_ver} =~ ^7\. ]]; then
            Download "${PHP7_Memcache_URL}"
            Tar_Cd ${PHP7_Memcache_Ver}.tgz ${PHP7_Memcache_Ver}
        elif [[ ${cur_php_ver} =~ ^8\. ]]; then
            Download "${PHP8_Memcache_URL}"
            Tar_Cd ${PHP8_Memcache_Ver}.tgz ${PHP8_Memcache_Ver}
        fi
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config
    elif [[ ${php_mem} == "2" ]]; then
        Echo_Blue "Installing php-memcached..."
        local php_mem_ext="memcached.so"
        if [[ "${PM}" == "yum" ]]; then
            yum install cyrus-sasl-devel -y
        elif [[ "${PM}" == "apt" ]]; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get install libsasl2-2 sasl2-bin libsasl2-2 libsasl2-dev libsasl2-modules -y
        fi
        Download "${LibMemcached_URL}"
        Tar_Cd ${LibMemcached_Ver}.tar.gz ${LibMemcached_Ver}
        if gcc -dumpversion|grep -Eq "^[7-9]|1[0-5]"; then
            patch -p1 < ${SRC_DIR}/patch/libmemcached-1.0.18-gcc7.patch
        fi
        ./configure --prefix=/usr/local/libmemcached --with-memcached
        Make_And_Install
        cd ${SRC_DIR}
        rm -rf ${LibMemcached_Ver}
        if [[ ${cur_php_ver} =~ ^5\. ]]; then
            Download "${PHP5_Memcached_URL}"
            Tar_Cd ${PHP5_Memcached_Ver}.tgz ${PHP5_Memcached_Ver}
            if ! gcc -dumpversion|grep -q "^[34]."; then
                export CFLAGS=" -fgnu89-inline"
            fi
        elif [[ ${cur_php_ver} =~ ^7\. ]]; then
            Download "${PHP7_Memcached_URL}"
            Tar_Cd ${PHP7_Memcached_Ver}.tgz ${PHP7_Memcached_Ver}
        elif [[ ${cur_php_ver} =~ ^8\. ]]; then
            Download "${PHP8_Memcached_URL}"
            Tar_Cd ${PHP8_Memcached_Ver}.tgz ${PHP8_Memcached_Ver}
        fi
        /usr/local/php/bin/phpize
        ./configure --with-php-config=/usr/local/php/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached
    fi
    Make_And_Install
    cd ${SRC_DIR}

    cat >/usr/local/php/conf.d/memcached.ini<<EOF
extension = "${php_mem_ext}"
EOF

    if [[ -s /usr/local/memcached/bin/memcached && -s "${php_ext_dir}/${php_mem_ext}" ]]; then
        \cp ${CUR_DIR}/init.d/memcached.service /etc/systemd/system/memcached.service
        Enable_Startup redis
        systemctl start redis
        Echo_Green "Memcached has been successfully installed."
    else
        Echo_Red "Memcached install failed."
    fi
}