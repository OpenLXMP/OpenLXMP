#!/usr/bin/env bash

Set_Timezone()
{
    if Cmd_Exists "timedatectl"; then
        Echo_Blue "Setting timezone using timedatectl..."
        timedatectl set-timezone "${TimeZone}"
    else
        Echo_Blue "Setting timezone..."
        rm -rf /etc/localtime
        ln -sf "/usr/share/zoneinfo/${TimeZone}" /etc/localtime
    fi
}

Sync_DateTime()
{
    if Cmd_Exists "timedatectl"; then
        Echo_Blue "Synchronize date and time using timedatectl..."
        timedatectl set-ntp true
    elif Cmd_Exists "chronyd"; then
        Echo_Blue "Synchronize date and time using chrony..."
        chronyd -d -q "server pool.ntp.org iburst"
    elif Cmd_Exists "ntpdate"; then
        Echo_Blue "Synchronize date and time using ntpdate..."
        ntpdate -u pool.ntp.org
    else
        Echo_Yellow "Skip synchronize date and time!"
    fi
}

Disable_Selinux()
{
    if [[ -s /etc/selinux/config ]]; then
        Echo_Blue "Disable selinux..."
        setenforce 0
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    fi
}

Yum_Remove_Packages()
{
    Echo_Blue "Remove Packages..."
    local YUM_RM_PKGS='mysql mysql-* mariadb mariadb-* php php-* nginx httpd httpd-*'
    local packages
    for packages in ${YUM_RM_PKGS}
        do yum remove $packages -y
    done
}

Apt_Remove_packages()
{
    Echo_Blue "Remove Packages..."
    local YUM_RM_PKGS='mysql mysql-* mariadb mariadb-* php php-* nginx apache2 apache2-*'
    local packages
    for packages in ${YUM_RM_PKGS}
        do apt-get purge $packages -y
    done
}

Yum_Install_Dependency()
{
    Echo_Blue "Install Dependecy for Red Hat family..."
    local YUM_INSTALL_PKGS='make cmake gcc gcc-c++ gcc-g77 kernel-headers glibc-headers flex bison file libtool libtool-libs autoconf patch wget pspell-devel unzip xz tar bzip2 bzip2-devel libzip-devel libcap diffutils ca-certificates net-tools git-core libc-client-devel psmisc crontabs perl lsof re2c pkg-config libarchive hostname initscripts iproute openssl openssl-devel gnutls-devel pcre-devel libevent libevent-devel ncurses ncurses-devel ncurses-libs curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel gettext gettext-devel gmp-devel libjpeg libjpeg-devel libjpeg-turbo-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel libXpm-devel c-ares-devel libicu-devel libxslt libxslt-devel expat-devel libaio-devel rpcgen libtirpc-devel cyrus-sasl-devel sqlite-devel oniguruma-devel numactl-devel libxcrypt libwebp-devel libxcrypt-compat ncurses-compat-libs freetype-devel libudev-devel'
    local packages
    for packages in ${YUM_INSTALL_PKGS}
        do yum install $packages -y
    done

    if [[ "${CentOS_VERSION}" =~ ^7 || "${RHEL_VERSION}" =~ ^7 || "${Alibaba_VERSION}" =~ ^2 || "${Oracle_VERSION}" =~ ^7 || "${Anolis_VERSION}" =~ ^7 ]]; then
        if [[ "${DISTRO}" == "Oracle" ]]; then
            yum install https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-epel-release-el7-1.0-4.el7.x86_64.rpm -y
            yum --enablerepo=*EPEL* install oniguruma-devel -y
        else
            yum install epel-release -y
        fi
        yum install oniguruma oniguruma-devel -y
    fi

    if [[ "${CentOS_VERSION}" =~ ^8 || "${RHEL_VERSION}" =~ ^8 || "${Rocky_VERSION}" =~ ^8 || "${Alma_VERSION}" =~ ^8 || "${Anolis_VERSION}" =~ ^8 || "${OpenCloudOS_VERSION}" =~ ^8 ]]; then
        echo "Installing packages use PowerTools repository..."
        repo_id=$(yum repolist all|grep -Ei "PowerTools"|head -n 1|awk '{print $1}')
        for c8pkgs in rpcgen re2c oniguruma-devel;
        do dnf --enablerepo=${repo_id} install ${c8pkgs} -y; done
        dnf install libarchive -y

        dnf install gcc-toolset-10 -y
    fi

    if [[ "${Oracle_VERSION}" =~ ^8 ]]; then
        repo_id=$(yum repolist all|grep -Ei "CodeReady"|head -n 1|awk '{print $1}')
        for o8pkgs in rpcgen re2c oniguruma-devel;
        do dnf --enablerepo=${repo_id} install ${o8pkgs} -y; done
        dnf install libarchive -y
    fi

    if [[ "${CentOS_VERSION}" =~ ^9 ]]; then
        crb_source_check=$(yum repolist all | grep -Ei '^crb' | awk '{print $1}')

        if [[ ! -n "$crb_source_check" ]]; then
            echo "Add crb source..."
            cat > /etc/yum.repos.d/centos-crb.repo << EOF
[CRB]
name=CentOS-\$releasever - CRB - mirrors.ustc.edu.cn
#failovermethod=priority
baseurl=https://mirrors.ustc.edu.cn/centos-stream/\$stream/CRB/\$basearch/os/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos-stream/RPM-GPG-KEY-CentOS-Official
EOF
        fi
    fi
    if [[ "${CentOS_VERSION}" =~ ^9 || "${Alma_VERSION}" =~ ^9 || "${Rocky_VERSION}" =~ ^9 ]]; then
        for cs9pkgs in oniguruma-devel libzip-devel libtirpc-devel libxcrypt-compat;
        do dnf --enablerepo=crb install ${cs9pkgs} -y; done
        if [[ "${Bin}" != "y" && "${DBSelect}" =~ ^(4|5) ]]; then
            dnf install gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc -y
        fi
    fi

    if [[ "${Oracle_VERSION}" =~ ^9 ]]; then
        repo_id=$(yum repolist all|grep -Ei "CodeReady"|head -n 1|awk '{print $1}')
        dnf --enablerepo=${repo_id} install libtirpc-devel -y
        if [[ "${Bin}" != "y" && "${DBSelect}" =~ ^(4|5) ]]; then
            dnf install gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc -y
        fi
    fi

    if [[ "${DISTRO}" == "UOS" ]]; then
        repo_id=$(yum repolist all|grep -Ei "PowerTools"|head -n 1|awk '{print $1}')
        for uospkgs in rpcgen re2c oniguruma-devel;
        do dnf --enablerepo=${repo_id} install ${uospkgs} -y; done
    fi

    if [[ "${DISTRO}" == "Fedora" || "${CentOS_VERSION}" =~ ^9 || "${Alma_VERSION}" =~ ^9 || "${Rocky_Version}" =~ ^9 || "${Amazon_VERSION}" =~ ^202[3-9] || "${OpenCloudOS_VERSION}" =~ ^9 ]]; then
        dnf install chkconfig -y
    fi
}

Apt_Install_Dependency()
{
    Echo_Blue "Install Dependecy for Debian family..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
    local APT_INSTALL_PKGS='debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake re2c wget cron bzip2 libzip-dev libc6-dev bison file flex bison m4 gawk less cpp binutils diffutils unzip tar bzip2 libbz2-dev xz-utils gzip lsof pkg-config ca-certificates libc-client2007e-dev psmisc patch git libc-ares-dev libncurses5 libncurses5-dev libtool libevent-dev openssl libssl-dev zlibc libsasl2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libjpeg-dev libpng-dev libpng12-0 libpng12-dev libkrb5-dev curl libcurl3-gnutls libcurl4-gnutls-dev libpcre3-dev libpq-dev libpq5 gettext libpng12-dev libxml2-dev libcap-dev libicu-dev e2fsprogs libxslt1.1 libxslt1-dev libc-client-dev libexpat1-dev libaio-dev libtirpc-dev libsqlite3-dev libonig-devlibtinfo-dev libnuma-dev libwebp-dev gnutls-dev iproute2 libfreetype-dev libfreetype6-dev libonig-dev libudev-dev'
    local packages
    for packages in ${APT_INSTALL_PKGS}
        do apt-get --no-install-recommends install $packages -y
    done
}

Check_Openssl()
{
    if openssl version | awk '{print $2}' | grep -q "3.*"; then
        isOpenSSL3='y'
    fi
}

Download_Files()
{
    cd ${SRC_DIR}
    Download "${Libiconv_URL}" "${Libiconv_Ver}.tar.gz"
    Download "${LibMcrypt_URL}" "${LibMcrypt_Ver}.tar.bz2"
    Download "${Mrcypt_URL}" "${Mrcypt_Ver}.tar.gz"
    Download "${Mhash_URL}" "${Mhash_Ver}.tar.bz2"
    if [[ "${STACK}" == "lnmp" ]]; then
        Download "${OpenSSL_URL}" "${OpenSSL_Ver}.tar.gz"
        Download "${Nginx_URL}" "${Nginx_Ver}.tar.gz"
    elif [[ "${STACK}" == "lamp" ]]; then
        Download "${APR_URL}" "${APR_Ver}.tar.bz2"
        Download "${APR_Util_URL}" "${APR_Util_Ver}.tar.bz2"
        Download "${Apache_URL}" "${Apache_Ver}.tar.bz2"
    fi
}

Make_And_Install()
{
    make -j${CPUCores}
    if [[ $? -ne 0 ]]; then
        make
    fi
    make install
}

PHP_Make_And_Install()
{
    make ZEND_EXTRA_LIBS='-liconv' -j${CPUCores}
    if [[ $? -ne 0 ]]; then
        make ZEND_EXTRA_LIBS='-liconv'
    fi
    make install
}

Install_Libiconv()
{
    Echo_Blue "Installing ${Libiconv_Ver}..."
    cd ${SRC_DIR}
    Tar_Cd ${Libiconv_Ver}.tar.gz ${Libiconv_Ver}
    ./configure --enable-static
    Make_And_Install
    Echo_Blue "Remove ${Libiconv_Ver} directory..."
    cd ${SRC_DIR}
    rm -rf ${Libiconv_Ver}
}

Install_Mcrypt()
{
    Echo_Blue "Installing ${LibMcrypt_Ver}..."
    Tar_Cd ${LibMcrypt_Ver}.tar.bz2 ${LibMcrypt_Ver}
    Tar_Cd ${LibMcrypt_Ver}.tar.bz2 ${LibMcrypt_Ver}
    \cp ${SRC_DIR}/patch/config.guess ${SRC_DIR}/patch/config.sub .
    ./configure
    Make_And_Install
    ldconfig
    cd libltdl/
    ./configure --enable-ltdl-install
    Make_And_Install
    ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
    ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
    ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
    ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
    cd ${SRC_DIR}

    Echo_Blue "Installing ${Mrcypt_Ver}..."
    Tar_Cd ${Mrcypt_Ver}.tar.gz ${Mrcypt_Ver}
    \cp ${SRC_DIR}/patch/config.guess ${SRC_DIR}/patch/config.sub .
    ./configure
    Make_And_Install
    cd ${SRC_DIR}
    rm -rf ${LibMcrypt_Ver}
    rm -rf ${Mcypt_Ver}
}

Install_Mhash()
{
    Echo_Blue "Installing ${Mhash_Ver}..."
    Tar_Cd ${Mhash_Ver}.tar.bz2 ${Mhash_Ver}
    \cp ${SRC_DIR}/patch/config.guess ${SRC_DIR}/patch/config.sub .
    ./configure
    Make_And_Install
    ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
    ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
    ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
    ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
    ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
    ldconfig
    cd ${SRC_DIR}
    rm -rf ${Mhash_Ver}
}

Install_Openssl()
{
    if [[ ! -s /usr/local/openssl1.1.1/bin/openssl ]] || /usr/local/openssl1.1.1/bin/openssl version | awk '{print $2}' | grep -q "1.1.1"; then
        Echo_Blue "Installing ${OpenSSL_Ver}..."
        Download "${OpenSSL_URL}" "${OpenSSL_Ver}.tar.gz"
        Tar_Cd ${OpenSSL_Ver}.tar.gz ${OpenSSL_Ver}
        ./config enable-weak-ssl-ciphers -fPIC --prefix=/usr/local/openssl1.1.1 --openssldir=/usr/local/openssl1.1.1
        make depend
        Make_And_Install
        ldconfig
        cd ${SRC_DIR}
        rm -rf ${OpenSSL_Ver}
    fi
}

Install_Freetype()
{
    Echo_Blue "Installing ${Freetype_Ver}..."
    Download "${Freetype_URL}" "${Freetype_Ver}.tar.xz"
    Tar_Cd ${Freetype_Ver}.tar.xz ${Freetype_Ver}
    ./configure --prefix=/usr/local/freetype --enable-freetype-config
    Make_And_Install
    cd ${SRC_DIR}
    rm -rf ${Freetype_Ver}
}

Install_Libzip()
{
    if Cmd_Exists "dpkg"; then
        local libzip_ver=$(dpkg -s libzip-dev | grep Version | cut -d' ' -f2)
    elif Cmd_Exists "rpm"; then
        local libzip_ver=$(rpm -q --queryformat '%{VERSION}' libzip-devel)
    fi
    if echo ${libzip_ver} | grep -Eq "^0\.(0[0-9]|10)"; then
        Echo_Blue "Installing ${Libzip_Ver}..."
        cd ${SRC_DIR}
        Download "${Libzip_URL}" "${Libzip_Ver}.tar.xz"
        Tar_Cd ${Libzip_Ver}.tar.xz ${Libzip_Ver}
        ./configure
        Make_And_Install
        export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
        ldconfig
        cd ${SRC_DIR}
        rm -rf ${Libzip_Ver}
    fi
}

Install_Nghttp2()
{
    Echo_Blue "Installing ${Nghttp2_Ver}..."
    cd ${SRC_DIR}
    Download "${Nghttp2_URL}" "${Nghttp2_Ver}.tar.xz"
    Tar_Cd ${Nghttp2_Ver}.tar.xz ${Nghttp2_Ver}
    ./configure --prefix=/usr/local/nghttp2
    Make_And_Install
    cd ${SRC_DIR}
    rm -rf ${Nghttp2_Ver}
    apache_with_nghttp2='--with-nghttp2=/usr/local/nghttp2'
}

Redhat_Lib_Opt()
{
    if [[ "${ARCH}" == "x86_64" ]]; then
        ln -sf /usr/lib64/libpng.* /usr/lib/
        ln -sf /usr/lib64/libjpeg.* /usr/lib/
    fi

    ulimit -v unlimited

    local lib_dir=("/lib" "/usr/lib" "/usr/lib64" "/usr/local/lib")
    for dir in "${lib_dir[@]}"; do
        if ! grep -q "^${dir}$" /etc/ld.so.conf; then
            echo "${dir}" >> /etc/ld.so.conf
        fi
    done

    ldconfig

    if command -v systemd-detect-virt >/dev/null 2>&1 && [[ "$(systemd-detect-virt)" = "lxc" ]]; then
        cat >>/etc/security/limits.conf<<eof
* soft nofile 65535
* hard nofile 65535
eof
    else
        cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof
    fi

    echo "fs.file-max=65535" >> /etc/sysctl.conf

    if [ -s /usr/lib64/libtinfo.so.6 ]; then
        ln -sf /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5
    elif [ -s /usr/lib/libtinfo.so.6 ]; then
        ln -sf /usr/lib/libtinfo.so.6 /usr/lib/libtinfo.so.5
    fi

    if [ -s /usr/lib64/libncurses.so.6 ]; then
        ln -sf /usr/lib64/libncurses.so.6 /usr/lib64/libncurses.so.5
    elif [ -s /usr/lib/libncurses.so.6 ]; then
        ln -sf /usr/lib/libncurses.so.6 /usr/lib/libncurses.so.5
    fi
}

Debian_Lib_Opt()
{
    if [[ "${ARCH}" == "x86_64" ]]; then
        ln -sf /usr/lib/x86_64-linux-gnu/libpng* /usr/lib/
        ln -sf /usr/lib/x86_64-linux-gnu/libjpeg* /usr/lib/
    else
        ln -sf /usr/lib/i386-linux-gnu/libpng* /usr/lib/
        ln -sf /usr/lib/i386-linux-gnu/libjpeg* /usr/lib/
        ln -sf /usr/include/i386-linux-gnu/asm /usr/include/asm
    fi

    if [ -d "/usr/lib/arm-linux-gnueabihf" ]; then
        ln -sf /usr/lib/arm-linux-gnueabihf/libpng* /usr/lib/
        ln -sf /usr/lib/arm-linux-gnueabihf/libjpeg* /usr/lib/
        ln -sf /usr/include/arm-linux-gnueabihf/curl /usr/include/
    fi

    ulimit -v unlimited

    local lib_dir=("/lib" "/usr/lib" "/usr/lib64" "/usr/local/lib")
    for dir in "${lib_dir[@]}"; do
        if ! grep -q "${dir}" /etc/ld.so.conf; then
            echo "${dir}" >> /etc/ld.so.conf
        fi
    done

    if [ -d /usr/include/x86_64-linux-gnu/curl ]; then
        ln -sf /usr/include/x86_64-linux-gnu/curl /usr/include/
    elif [ -d /usr/include/i386-linux-gnu/curl ]; then
        ln -sf /usr/include/i386-linux-gnu/curl /usr/include/
    fi

    if [ -d /usr/include/arm-linux-gnueabihf/curl ]; then
        ln -sf /usr/include/arm-linux-gnueabihf/curl /usr/include/
    fi

    if [ -d /usr/include/aarch64-linux-gnu/curl ]; then
        ln -sf /usr/include/aarch64-linux-gnu/curl /usr/include/
    fi

    if echo "${Ubuntu_VERSION}" | grep -Eqi "^24."; then
        ln -sf /usr/lib/${ARCH}-linux-gnu/libaio.so.1t64 /usr/lib/${ARCH}-linux-gnu/libaio.so.1
        ln -sf /usr/lib/${ARCH}-linux-gnu/libncurses.so.6 /usr/lib/${ARCH}-linux-gnu/libncurses.so.5
        ln -sf /usr/lib/${ARCH}-linux-gnu/libtinfo.so.6 /usr/lib/${ARCH}-linux-gnu/libtinfo.so.5
    fi

    ldconfig

    cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

    echo "fs.file-max=65535" >> /etc/sysctl.conf
}