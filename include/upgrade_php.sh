#!/usr/bin/env bash

Upgrade_PHP()
{
    Cur_PHP_Ver=$(/usr/local/php/bin/php -v | awk 'NR==1 {print $2}')
    php_ver=''
    PHP_Ver=''

    Echo_Cyan "Current PHP Version: ${Cur_PHP_Ver}"
    Echo_Cyan "Please get the PHP version number from https://www.php.net/downloads"
    while [[ -z ${php_ver} ]]; do
        read -p "Please enter PHP version, (example: 8.3.1): " php_ver
    done
    if [[ ${php_ver} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        Echo_Cyan "The PHP version that you have entered: ${php_ver}"
    else
        Echo_Red "Error: Invalid PHP version format."
        exit 1
    fi

    if [[ ! $php_ver =~ ^(5\.6|7\.0|7\.1|7\.2|7\.3|7\.4|8\.0|8\.1|8\.2|8\.3) ]]; then
        Echo_Red "Error: PHP ${php_ver} is not supported."
        exit 1
    fi

    Press_Start
    Print_Sys_Info
    Echo_Blue "Backup PHP files before upgrading..."
    cd ${SRC_DIR}
    Check_Stack
    Echo_Blue "Current Stack: ${STACK}"
    mv /usr/local/php /usr/local/backup_php_${Upgrade_Date}
    if [[ "${STACK}" != "lamp" ]]; then
        /etc/init.d/php-fpm stop
    fi
    PHP_Ver="php-${php_ver}"
    Download "https://www.php.net/distributions/${PHP_Ver}.tar.xz" "${PHP_Ver}.tar.xz"
    if [ $? -ne 0 ]; then
        Echo_Red "Unable to download ${PHP_Ver}.tar.xz from https://www.php.net/distributions/${PHP_Ver}.tar.xz"
        Echo_Red "Please download the file manually and place it in the src directory."
        exit 1
    fi
    PHP_Options
    case "${php_ver}" in
        5.6.*) Upgrade_PHP_56 ;;
        7.0.*) Upgrade_PHP_70 ;;
        7.1.*) Upgrade_PHP_71 ;;
        7.2.*) Upgrade_PHP_72 ;;
        7.3.*) Upgrade_PHP_73 ;;
        7.4.*) Upgrade_PHP_74 ;;
        8.0.*) Upgrade_PHP_80 ;;
        8.1.*) Upgrade_PHP_81 ;;
        8.2.*) Upgrade_PHP_82 ;;
        8.3.*) Upgrade_PHP_83 ;;
        *) Echo_Red "Error: PHP ${php_ver} is not supported."; exit 1 ;;
    esac
    if [[ -s /usr/local/php/etc/php.ini && -s /usr/local/php/bin/php ]]; then
        if [[ "${STACK}" != "lamp" ]]; then
            /etc/init.d/php-fpm start
        fi
        Echo_Green "PHP has been successfully upgraded to the version: ${php_ver}."
    else
        Echo_Red "PHP upgrade failed."
    fi
}

Upgrade_PHP_56()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    if [[ -s /usr/local/php/bin/php-config ]]; then
        Echo_Blue "Installing ZendGuardLoader..."
        cd ${SRC_DIR}
        Download http://downloads.zend.com/guard/7.0.0/zend-loader-php5.6-linux-${ARCH}_update1.tar.gz
        Tar_Cd zend-loader-php5.6-linux-${ARCH}_update1.tar.gz
        mv zend-loader-php5.6-linux-x86_64 /usr/local/zend
        cat >/usr/local/php/conf.d/001-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
zend_extension = /usr/local/zend/ZendGuardLoader.so
zend_loader.enable = 1
zend_loader.disable_licensing = 0
zend_loader.obfuscation_level_support = 3
zend_loader.license_path =
EOF
    fi

    Set_PHP
}

Upgrade_PHP_70()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_71()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_72()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_73()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_74()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Install_Libzip
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_80()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Install_Libzip
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_81()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Install_Libzip
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_82()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Install_Libzip
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}

Upgrade_PHP_83()
{
    Echo_Blue "Upgrading ${PHP_Ver}..."
    Install_Libzip
    Tar_Cd ${PHP_Ver}.tar.xz ${PHP_Ver}
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

    if [[ "${STACK}" != "lamp" ]]; then
        Create_PHPFPM_Conf
    fi

    Set_PHP
}