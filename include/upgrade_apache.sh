#!/usr/bin/env bash

Upgrade_Apache()
{
    Cur_Apache_Ver=$(/usr/local/apache/bin/httpd -v | awk 'NR==1{print $3}' | sed 's/Apache\///')
    apache_ver=''
    Apache_Ver=''

    Echo_Cyan "Current Apache Version: ${Cur_Apache_Ver}"
    Echo_Cyan "Please get the Apache version number from https://httpd.apache.org"
    while [[ -z ${apache_ver} ]]; do
        read -p "Please enter Apache version, (example: 2.4.58): " apache_ver
    done
    if [[ ${apache_ver} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        Echo_Cyan "The Apache version that you have entered: ${apache_ver}"
    else
        Echo_Red "Error: Invalid Apache version format."
        exit 1
    fi

    Press_Start
    Print_Sys_Info
    Apache_Ver="httpd-${apache_ver}"
    cd ${SRC_DIR}

    Echo_Blue "Backup Apache..."
    systemctl stop httpd
    cp -ra /usr/local/apache /usr/local/backup_apache_${Upgrade_Date}

    Echo_Blue "Upgrading ${Apache_Ver}..."
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
    Download "${APR_URL}" "${APR_Ver}.tar.bz2"
    Download "${APR_Util_URL}" "${APR_Util_Ver}.tar.bz2"
    Download "https://dlcdn.apache.org/httpd/${Apache_Ver}.tar.bz2" "${Apache_Ver}.tar.bz2"
    if [ $? -ne 0 ]; then
        Download "http://archive.apache.org/dist/httpd/${Apache_Ver}.tar.bz2" "${Apache_Ver}.tar.bz2"
    fi
    Tar_Cd ${APR_Ver}.tar.bz2
    Tar_Cd ${APR_Util_Ver}.tar.bz2
    Tar_Cd ${Apache_Ver}.tar.bz2 ${Apache_Ver}
    mv ${SRC_DIR}/${APR_Ver} srclib/apr
    mv ${SRC_DIR}/${APR_Util_Ver} srclib/apr-util
    ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-headers --enable-mime-magic --enable-proxy --enable-so --enable-rewrite --enable-ssl ${apache_with_ssl} --enable-deflate --with-pcre --with-included-apr --with-apr-util --enable-mpms-shared=all --enable-remoteip --enable-http2 ${apache_with_nghttp2}

    Make_And_Install

    cd ${SRC_DIR}
    rm -rf ${Apache_Ver}

    if [[ -s /usr/local/apache/bin/httpd ]]; then
        systemctl start httpd
        Echo_Green "Apache has been successfully upgraded to the version: ${apache_ver}."
    else
        Echo_Red "Apache upgrade failed."
    fi
}