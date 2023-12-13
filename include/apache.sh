#!/usr/bin/env bash

Install_Apache()
{
    Echo_Blue "Installing ${Apache_Ver}..."
    Echo_Blue "Installing Dependecy for ${Apache_Ver}..."
    if [[ "${PM}" == "yum" ]]; then
        yum install libnghttp2-devel -y
        if [[ "${CentOS_VERSION}" =~ ^9 || "${Alma_VERSION}" =~ ^9 || "${Rocky_VERSION}" =~ ^9 ]]; then
            dnf --enablerepo=crb install libnghttp2-devel -y
        fi
        if yum list installed | grep -q libnghttp2-devel; then
            echo "libnghttp2-devel installed."
            apache_with_nghttp2='--with-nghttp2'
        else
            Install_Nghttp2
        fi
    elif [[ "${PM}" == "apt" ]]; then
        apt-get install libnghttp2-dev -y
         if dpkg -l | grep -q libnghttp2-dev; then
            echo "llibnghttp2-dev installed."
            apache_with_nghttp2='--with-nghttp2'
         else
            Install_Nghttp2
         fi
    fi

    apache_with_ssl='--with-ssl'
    if openssl version | awk '{print $2}' | grep -Eq '^(0.9\.|1\.0\.([01]|0))'; then
        Install_Openssl
        apache_with_ssl='--with-ssl=/usr/local/openssl1.1.1'
    fi

    cd ${SRC_DIR}
    Tar_Cd ${APR_Ver}.tar.bz2
    Tar_Cd ${APR_Util_Ver}.tar.bz2
    Tar_Cd ${Apache_Ver}.tar.bz2 ${Apache_Ver}
    mv ${SRC_DIR}/${APR_Ver} srclib/apr
    mv ${SRC_DIR}/${APR_Util_Ver} srclib/apr-util
    ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --enable-ssl ${apache_with_ssl} --enable-deflate --with-pcre --with-included-apr --with-apr-util --enable-mpms-shared=all --enable-remoteip --enable-http2 ${apache_with_nghttp2}

    Make_And_Install

    \cp ${CUR_DIR}/conf/httpd.conf /usr/local/apache/conf/httpd.conf
    \cp ${CUR_DIR}/conf/httpd-default.conf /usr/local/apache/conf/extra/httpd-default.conf
    \cp ${CUR_DIR}/conf/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
    \cp ${CUR_DIR}/conf/httpd-vhosts.conf /usr/local/apache/conf/extra/httpd-vhosts.conf

    id -g www &>/dev/null || groupadd www
    id -u www &>/dev/null || useradd -r -M -s /sbin/nologin -g www www

    mkdir -p ${Default_Website_Dir}
    chmod +w ${Default_Website_Dir}
    mkdir -p /home/wwwlogs
    chmod 777 /home/wwwlogs

    chown -R www:www ${Default_Website_Dir}

    mkdir /usr/local/apache/conf/vhost

    cd ${CUR_DIR}
    rm -rf src/${Apache_Ver}
}