#!/usr/bin/env bash

PHP_With_Fileinfo()
{
    if [[ "${Enable_PHP_Fileinfo}" == "n" ]]; then
        if [[ "${MemTotal}" -gt 950 ]]; then
            with_fileinfo=''
        else
            with_fileinfo='--disable-fileinfo'
        fi
    else
        with_fileinfo=''
    fi
}

PHP_With_ICU()
{
    if pkg-config --modversion icu-i18n | grep -Eqi '^6[89]|7[0-9]'; then
        export CXX="g++ -DTRUE=1 -DFALSE=0"
        export  CC="gcc -DTRUE=1 -DFALSE=0"
    fi
}

PHP_ICU_Patch()
{
    if pkg-config --modversion icu-i18n | grep -Eqi '^[7-9][0-9]'; then
        PHP_Short_Ver="$(echo ${PHP_Ver} | cut -d- -f2 | cut -d. -f1-2)"
        echo "apply a icu 70+ patch to PHP ${PHP_Short_Ver}..."
        patch -p1 < ${SRC_DIR}/patch/php-${PHP_Short_Ver}-icu70.patch
    fi
}

PHP_OpenSSL3_Patch()
{
    if [[ "${isOpenSSL3}" = "y" ]]; then
        PHP_Short_Ver="$(echo ${PHP_Ver} | cut -d- -f2 | cut -d. -f1-2)"
        echo "Apply a OpenSSL 3.0 patch to PHP ${PHP_Short_Ver}..."
        patch -p1 < ${SRC_DIR}/patch/php-${PHP_Short_Ver}-openssl3.0.patch
    fi
}

PHP_With_LDAP()
{
    if [[ "${Enable_PHP_LDAP}" == "y" ]]; then
        if [[ "${PM}" = "yum" ]]; then
            yum -y install openldap-devel cyrus-sasl-devel
            if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
                ln -sf /usr/lib64/libldap* /usr/lib/
                ln -sf /usr/lib64/liblber* /usr/lib/
            fi
        elif [[ "${PM}" = "apt" ]]; then
            apt-get install -y libldap2-dev libsasl2-dev
            if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
                ln -sf /usr/lib/${ARCH}-linux-gnu/libldap.so /usr/lib/
                ln -sf /usr/lib/${ARCH}-linux-gnu/libldap_r.a /usr/lib/
                ln -sf /usr/lib/${ARCH}-linux-gnu/liblber.so /usr/lib/
            fi
        fi
        with_ldap='--with-ldap --with-ldap-sasl'
    else
        with_ldap=''
    fi
}

PHP_With_Bz2()
{
    if [[ "${Enable_PHP_Bz2}" == "y" ]]; then
        Install_Libzip
        with_bz2='--with-bz2'
    else
        with_bz2=''
    fi
}

PHP_With_Sodium()
{
    if [[ "${Enable_PHP_Sodium}" == "y" ]]; then
        if [[ "${PM}" = "yum" ]]; then
            yum install epel-release -y
            yum install libsodium-devel -y
        elif [[ "${PM}" = "apt" ]]; then
            apt-get install libsodium-dev -y
        fi
        if echo "${PHP_Ver}" | grep -Eqi "php-7.[2-4].*|php-8.*"; then
            with_sodium='--with-sodium'
        else
            Echo_Red 'php 7.1 and below do not support the sodium extension, only support libsodium-php 3rd party extension.'
            with_sodium=''
        fi
    fi
}

PHP_With_Imap()
{
    if [[ "${Enable_PHP_Imap}" == "y" ]]; then
        if [[ "${PM}" = "yum" ]]; then
            yum install epel-release -y
            local packages
            for packages in libc-client-devel krb5-devel uw-imap-devel;
            do yum install ${packages} -y; done
            if echo "${CentOS_Version}" | grep -Eqi "^9" || echo "${Alma_Version}" | grep -Eqi "^9" || echo "${Rocky_Version}" | grep -Eqi "^9"; then
                rpm -ivh http://rpms.remirepo.net/enterprise/9/remi/${ARCH}/libc-client-2007f-30.el9.remi.${ARCH}.rpm
                rpm -ivh http://rpms.remirepo.net/enterprise/9/remi/${ARCH}/uw-imap-devel-2007f-30.el9.remi.${ARCH}.rpm
            fi
            [[ -s /usr/lib64/libc-client.so ]] && ln -sf /usr/lib64/libc-client.so /usr/lib/libc-client.so
        elif [[ "${PM}" = "apt" ]]; then
            apt-get install libc-client-dev libkrb5-dev -y
        fi
        with_imap='--with-imap --with-imap-ssl --with-kerberos'
    else
        with_imap=''
    fi
}

PHP_Options()
{
    PHP_With_Fileinfo
    PHP_With_ICU
    PHP_With_LDAP
    PHP_With_Bz2
    PHP_With_Sodium
    php_with_n_a='--enable-fpm --with-fpm-user=www --with-fpm-group=www'
    if [[ "${STACK}" == "lamp" ]]; then
        php_with_n_a='--with-apxs2=/usr/local/apache/bin/apxs'
        sed -i "s|#!/replace/with/path/to/perl/interpreter -w|#!$(which perl) -w|g" /usr/local/apache/bin/apxs
    fi
    php_with_options="${with_fileinfo} ${with_ldap} ${with_bz2} ${with_sodium} ${PHP_Modules_Options}"
}

Create_PHPFPM_Conf()
{
    cat >/usr/local/php/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
pm.max_requests = 1024
pm.process_idle_timeout = 10s
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF
    \cp ${SRC_DIR}/${PHP_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    \cp ${CUR_DIR}/init.d/php-fpm.service /etc/systemd/system/php-fpm.service
    chmod +x /etc/init.d/php-fpm
}

Set_PHP()
{
    Echo_Blue "Adjusting php.ini configuration file..."
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' /usr/local/php/etc/php.ini

    Echo_Blue "Create PHP symbolic link..."
    ln -sf /usr/local/php/bin/php /usr/bin/php
    ln -sf /usr/local/php/bin/phpize /usr/bin/phpize
    ln -sf /usr/local/php/bin/pear /usr/bin/pear
    ln -sf /usr/local/php/bin/pecl /usr/bin/pecl

    Echo_Blue "Configure pear & pecl..."
    pear config-set php_ini /usr/local/php/etc/php.ini
    pecl config-set php_ini /usr/local/php/etc/php.ini

    Echo_Blue "Installing Composer..."
    if [[ ${PHP_Ver} =~ ^php-(5\.6|7\.0|7\.1) ]]; then
        Download "${Composer22_URL}" "/usr/local/bin/composer"
    else
        Download "${Composer_URL}" "/usr/local/bin/composer"
    fi
    chmod +x /usr/local/bin/composer
}

Install_PHP_56()
{
    Echo_Blue "Installing ${PHP56_Ver}..."
    Download "${PHP56_URL}"
    Tar_Cd ${PHP56_Ver}.tar.xz ${PHP56_Ver}
    if [[ "${ARCH}" = "aarch64" ]]; then
        patch -p1 < ${SRC_DIR}/patch/php-5.6-asm-aarch64.patch
    fi
    if openssl version | awk '{print $2}' | grep -q "1.1.1"; then
        patch -p1 < ${SRC_DIR}/patch/php-5.6.x-OpenSSL-1.1.1.patch
    fi
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir -with-freetype-dir=/usr/local/freetype \
    --with-jpeg-dir --with-png-dir \
    --with-zlib --with-libxml-dir=/usr \
    --enable-xml --disable-rpath \
    --enable-bcmath --enable-shmop \
    --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl --enable-mbregex \
    --enable-mbstring --with-mcrypt \
    --enable-ftp --with-gd \
    --enable-gd-native-ttf --with-mhash \
    --enable-pcntl --enable-sockets \
    --with-xmlrpc --enable-zip \
    --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-opcache \
    --with-xsl \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_70()
{
    Echo_Blue "Installing ${PHP70_Ver}..."
    Download "${PHP70_URL}"
    Tar_Cd ${PHP70_Ver}.tar.xz ${PHP70_Ver}
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir --with-freetype-dir=/usr/local/freetype \
    --with-jpeg-dir --with-png-dir \
    --with-zlib --with-libxml-dir=/usr --enable-xml \
    --disable-rpath --enable-bcmath --enable-shmop \
    --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --with-mcrypt --enable-ftp --with-gd \
    --enable-gd-native-ttf --with-mhash \
    --enable-pcntl --enable-sockets --with-xmlrpc \
    --enable-zip --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-opcache \
    --with-xsl \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_71()
{
    Echo_Blue "Installing ${PHP71_Ver}..."
    Download "${PHP71_URL}"
    Tar_Cd ${PHP71_Ver}.tar.xz ${PHP71_Ver}
    PHP_ICU_Patch
    PHP_OpenSSL3_Patch
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir --with-freetype-dir=/usr/local/freetype \
    --with-jpeg-dir --with-png-dir \
    --with-zlib --with-libxml-dir=/usr \
    --enable-xml --disable-rpath \
    --enable-bcmath --enable-shmop \
    --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --with-mcrypt --enable-ftp \
    --with-gd --enable-gd-native-ttf \
    --with-mhash --enable-pcntl \
    --enable-sockets --with-xmlrpc \
    --enable-zip --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_72()
{
    Echo_Blue "Installing ${PHP72_Ver}..."
    Download "${PHP72_URL}"
    Tar_Cd ${PHP72_Ver}.tar.xz ${PHP72_Ver}
    PHP_ICU_Patch
    PHP_OpenSSL3_Patch
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir --with-freetype-dir=/usr/local/freetype \
    --with-jpeg-dir --with-png-dir \
    --with-zlib --with-libxml-dir=/usr --enable-xml \
    --disable-rpath --enable-bcmath --enable-shmop \
    --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl --enable-ftp \
    --with-gd --with-mhash \
    --enable-pcntl --enable-sockets \
    --with-xmlrpc --enable-zip \
    --enable-soap \
    --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_73()
{
    Echo_Blue "Installing ${PHP73_Ver}..."
    Download "${PHP73_URL}"
    Tar_Cd ${PHP73_Ver}.tar.xz ${PHP73_Ver}
    PHP_ICU_Patch
    PHP_OpenSSL3_Patch
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir --with-freetype-dir=/usr/local/freetype \
    --with-jpeg-dir --with-png-dir \
    --with-zlib --with-libxml-dir=/usr --enable-xml \
    --disable-rpath --enable-bcmath --enable-shmop \
    --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --enable-ftp --with-gd \
    --with-mhash --enable-pcntl \
    --enable-sockets --with-xmlrpc \
    --enable-zip --without-libzip \
    --enable-soap \
    --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_74()
{
    Echo_Blue "Installing ${PHP74_Ver}..."
    Install_Libzip
    Download "${PHP74_URL}"
    Tar_Cd ${PHP74_Ver}.tar.xz ${PHP74_Ver}
    PHP_OpenSSL3_Patch
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv-dir --with-freetype=/usr/local/freetype \
    --with-jpeg --with-png \
    --with-zlib --enable-xml --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem --enable-inline-optimization \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl --enable-ftp \
    --enable-gd --with-mhash --enable-pcntl \
    --enable-sockets --with-xmlrpc --with-zip \
    --without-libzip --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    --with-webp \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_80()
{
    Echo_Blue "Installing ${PHP80_Ver}..."
    Install_Libzip
    Download "${PHP80_URL}"
    Tar_Cd ${PHP80_Ver}.tar.xz ${PHP80_Ver}
    PHP_OpenSSL3_Patch
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv=/usr/local --with-freetype=/usr/local/freetype \
    --with-jpeg --with-zlib --enable-xml \
    --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl --enable-ftp \
    --enable-gd --with-mhash --enable-pcntl \
    --enable-sockets --with-zip \
    --enable-soap \
    --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    --with-webp \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_81()
{
    Echo_Blue "Installing ${PHP81_Ver}..."
    Install_Libzip
    Download "${PHP81_URL}"
    Tar_Cd ${PHP81_Ver}.tar.xz ${PHP81_Ver}
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv=/usr/local --with-freetype=/usr/local/freetype \
    --with-jpeg --with-zlib --enable-xml \
    --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --enable-ftp --enable-gd \
    --with-mhash --enable-pcntl \
    --enable-sockets --with-zip \
    --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    --with-webp \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_82()
{
    Echo_Blue "Installing ${PHP82_Ver}..."
    Install_Libzip
    Download "${PHP82_URL}"
    Tar_Cd ${PHP82_Ver}.tar.xz ${PHP82_Ver}
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv=/usr/local --with-freetype=/usr/local/freetype \
    --with-jpeg --with-zlib --enable-xml \
    --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --enable-ftp --enable-gd \
    --with-mhash --enable-pcntl \
    --enable-sockets --with-zip \
    --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    --with-webp \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Install_PHP_83()
{
    Echo_Blue "Installing ${PHP83_Ver}..."
    Install_Libzip
    Download "${PHP83_URL}"
    Tar_Cd ${PHP83_Ver}.tar.xz ${PHP83_Ver}
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/conf.d \
    ${php_with_n_a} \
    --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    --with-iconv=/usr/local --with-freetype=/usr/local/freetype \
    --with-jpeg --with-zlib --enable-xml \
    --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem \
    --with-curl --with-openssl \
    --enable-mbregex --enable-mbstring \
    --enable-intl --enable-pcntl \
    --enable-ftp --enable-gd \
    --with-mhash --enable-pcntl \
    --enable-sockets --with-zip \
    --enable-soap --with-gettext \
    --enable-exif \
    ${with_fileinfo} \
    --enable-intl \
    --enable-opcache \
    --with-xsl \
    --with-pear \
    --with-webp \
    ${php_with_options}

    PHP_Make_And_Install

    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    if [[ "${STACK}" == "lnmp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}