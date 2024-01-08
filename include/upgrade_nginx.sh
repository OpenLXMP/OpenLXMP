#!/usr/bin/env bash

Upgrade_Nginx()
{
    Cur_Nginx_Ver=$(/usr/local/nginx/sbin/nginx -v 2>&1 | awk -F "/" '/nginx/{print $2}')
    Nginx_Ver=''

    Echo_Cyan "Current Nginx Version: ${Cur_Nginx_Ver}"
    Echo_Cyan "Please get the Nginx version number from http://nginx.org/en/download.html"
    while [[ -z ${Nginx_Ver} ]]; do
        read -p "Please enter nginx version, (example: 1.25.3): " Nginx_Ver
    done
    if [[ ${Nginx_Ver} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        Echo_Cyan "The Nginx version that you have entered: ${Nginx_Ver}"
    else
        Echo_Red "Error: Invalid Nginx version format."
        exit 1
    fi

    Press_Start
    Print_Sys_Info
    Echo_Blue "Upgrading Nginx ${Nginx_Ver}..."
    cd ${SRC_DIR}
    Download "${OpenSSL_URL}" "${OpenSSL_Ver}.tar.gz"
    Download "http://nginx.org/download/nginx-${Nginx_Ver}.tar.gz" "nginx-${Nginx_Ver}.tar.gz"
    Tar_Cd ${OpenSSL_Ver}.tar.gz
    Tar_Cd nginx-${Nginx_Ver}.tar.gz nginx-${Nginx_Ver}
    ./configure --user=www \
    --group=www \
    --prefix=/usr/local/nginx \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-http_sub_module --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_realip_module \
    --with-openssl=${SRC_DIR}/${OpenSSL_Ver} \
    ${Nginx_Modules_Options}

    make -j${CPUCores}
    if [[ $? -ne 0 ]]; then
        make
    fi

    mv /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx.${Upgrade_Date}
    \cp objs/nginx /usr/local/nginx/sbin/nginx

    make upgrade

    cd ${SRC_DIR}
    rm -rf ${Nginx_Ver}

    if [[ -s /usr/local/nginx/sbin/nginx ]]; then
        Echo_Green "Nginx has been successfully upgraded to the version: ${Nginx_Ver}."
    else
        Echo_Red "Nginx upgrade failed."
    fi
}