#!/usr/bin/env bash

Install_Nginx()
{
    Echo_Blue "Installing ${Nginx_Ver}..."
    Tar_Cd ${OpenSSL_Ver}.tar.gz
    Tar_Cd ${Nginx_Ver}.tar.gz ${Nginx_Ver}
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

    Make_And_Install

    ln -sf /usr/local/nginx/sbin/nginx /bin/nginx

    \cp ${CUR_DIR}/conf/nginx.conf /usr/local/nginx/conf/nginx.conf
    \cp ${CUR_DIR}/conf/enable-php.conf /usr/local/nginx/conf/enable-php.conf
    \cp ${CUR_DIR}/conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php-pathinfo.conf

    id -g www &>/dev/null || groupadd www
    id -u www &>/dev/null || useradd -r -M -s /sbin/nologin -g www www

    mkdir -p ${Default_Website_Dir}
    chmod +w ${Default_Website_Dir}
    mkdir -p /home/wwwlogs
    chmod 777 /home/wwwlogs

    chown -R www:www ${Default_Website_Dir}

    mkdir /usr/local/nginx/conf/vhost

    \cp ${CUR_DIR}/init.d/nginx.service /etc/systemd/system/nginx.service
    \cp ${CUR_DIR}/init.d/init.d.nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx

    cd ${SRC_DIR}
    rm -rf ${Nginx_Ver}
}