#!/usr/bin/env bash

Install_MySQL_55()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Installing ${MySQL55_Ver} use use Generic Binaries..."
        Download "${MySQL55_Bin_URL}" "${MySQL55_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        Tar_Cd ${MySQL55_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL55_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Installing ${MySQL55_Ver} use use Source cdoe..."
        Download "${MySQL55_URL}" "${MySQL55_Ver}.tar.gz"
        Tar_Cd ${MySQL55_Ver}.tar.gz ${MySQL55_Ver}
        if [[ ${ARCH} == "aarch64" || ${ARCH} == "arm" ]]; then
            patch -p1 < ${SRC_DIR}/patch/mysql-5.5-fix-arm-client_plugin.patch
        fi
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_READLINE=1 \
        -DWITH_EMBEDDED_SERVER=1 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_SSL=bundled

        Make_And_Install
    fi

    id -g mysql &>/dev/null || groupadd mysql
    id -u mysql &>/dev/null || useradd -r -M -s /sbin/nologin -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${Default_MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M

#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

default_storage_engine = InnoDB
#innodb_file_per_table = 1
#innodb_data_home_dir = ${Default_MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${Default_MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_additional_mem_pool_size = 2M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF
    if [ "${EnableInnoDB}" == "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\default_storage_engine = MyISAM\nloose-skip-innodb' /etc/my.cnf
    fi

    chown -R mysql:mysql /usr/local/mysql
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --user=mysql --datadir=${Default_MySQL_Data_Dir}
    MySQL_Init
}

Install_MySQL_56()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Installing ${MySQL56_Ver} use use Generic Binaries..."
        Download "${MySQL56_Bin_URL}" "${MySQL56_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        Tar_Cd ${MySQL56_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL56_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Installing ${MySQL56_Ver} use use Source cdoe..."
        Download "${MySQL56_URL}" "${MySQL56_Ver}.tar.gz"
        if [[ "${isOpenSSL3}" == "y" ]]; then
            Install_Openssl
            MySQL_WITH_SSL='-DWITH_SSL=/usr/local/openssl1.1.1'
        else
            MySQL_WITH_SSL='-DWITH_SSL=system'
        fi
        Tar_Cd ${MySQL56_Ver}.tar.gz ${MySQL56_Ver}
        if  g++ -dM -E -x c++ /dev/null | grep -F __cplusplus | cut -d' ' -f3 | grep -Eqi "^2017|202[0-9]"; then
            sed -i '1s/^/set(CMAKE_CXX_STANDARD 11)\n/' CMakeLists.txt
        fi
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_READLINE=1 \
        -DWITH_EMBEDDED_SERVER=1 \
        -DENABLED_LOCAL_INFILE=1 \
        ${MySQL_WITH_SSL}

        Make_And_Install
    fi

    id -g mysql &>/dev/null || groupadd mysql
    id -u mysql &>/dev/null || useradd -r -M -s /sbin/nologin -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${Default_MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

#loose-innodb-trx=0
#loose-innodb-locks=0
#loose-innodb-lock-waits=0
#loose-innodb-cmp=0
#loose-innodb-cmp-per-index=0
#loose-innodb-cmp-per-index-reset=0
#loose-innodb-cmp-reset=0
#loose-innodb-cmpmem=0
#loose-innodb-cmpmem-reset=0
#loose-innodb-buffer-page=0
#loose-innodb-buffer-page-lru=0
#loose-innodb-buffer-pool-stats=0
#loose-innodb-metrics=0
#loose-innodb-ft-default-stopword=0
#loose-innodb-ft-inserted=0
#loose-innodb-ft-deleted=0
#loose-innodb-ft-being-deleted=0
#loose-innodb-ft-config=0
#loose-innodb-ft-index-cache=0
#loose-innodb-ft-index-table=0
#loose-innodb-sys-tables=0
#loose-innodb-sys-tablestats=0
#loose-innodb-sys-indexes=0
#loose-innodb-sys-columns=0
#loose-innodb-sys-fields=0
#loose-innodb-sys-foreign=0
#loose-innodb-sys-foreign-cols=0

default_storage_engine = InnoDB
#innodb_file_per_table = 1
#innodb_data_home_dir = ${Default_MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${Default_MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF
    if [ "${EnableInnoDB}" == "y" ]; then
        sed -i 's/^#innodb/innodb/g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\innodb=OFF\nignore-builtin-innodb\nskip-innodb\ndefault_storage_engine = MyISAM\ndefault_tmp_storage_engine = MyISAM' /etc/my.cnf
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
    fi

    chown -R mysql:mysql /usr/local/mysql
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --user=mysql --datadir=${Default_MySQL_Data_Dir}
    MySQL_Init
}

Install_MySQL_57()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Installing ${MySQL57_Ver} use use Generic Binaries..."
        Download "${MySQL57_Bin_URL}" "${MySQL57_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        Tar_Cd ${MySQL57_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL57_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Installing ${MySQL57_Ver} use use Source cdoe..."
        Download "${MySQL57_URL}" "${MySQL57_Ver}.tar.gz"
        Tar_Cd ${MySQL57_Ver}.tar.gz ${MySQL57_Ver}
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_EMBEDDED_SERVER=1 \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_BOOST=boost \
        -DWITH_SSL=system

        Make_And_Install
    fi

    id -g mysql &>/dev/null || groupadd mysql
    id -u mysql &>/dev/null || useradd -r -M -s /sbin/nologin -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${Default_MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_data_home_dir = ${Default_MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${Default_MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout
EOF

    chown -R mysql:mysql /usr/local/mysql
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --user=mysql --datadir=${Default_MySQL_Data_Dir}
    MySQL_Init
}

Install_MySQL_80()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Installing ${MySQL80_Ver} use use Generic Binaries..."
        Download "${MySQL80_Bin_URL}" "${MySQL80_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz"
        Tar_Cd ${MySQL80_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL80_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Installing ${MySQL80_Ver} use use Source cdoe..."
        Download "${MySQL80_URL}" "${MySQL80_Ver}.tar.gz"
        Tar_Cd ${MySQL80_Ver}.tar.gz ${MySQL80_Ver}
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_BOOST=../boost \
        -DWITH_SSL=system

        Make_And_Install
    fi

    id -g mysql &>/dev/null || groupadd mysql
    id -u mysql &>/dev/null || useradd -r -M -s /sbin/nologin -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${Default_MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535
default_authentication_plugin = mysql_native_password

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
binlog_expire_logs_seconds = 864000
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_data_home_dir = ${Default_MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${Default_MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout
EOF

    chown -R mysql:mysql /usr/local/mysql
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --user=mysql --datadir=${Default_MySQL_Data_Dir}
    MySQL_Init
}

Install_MySQL_82()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Installing ${MySQL80_Ver} use use Generic Binaries..."
        Download "${MySQL82_Bin_URL}" "${MySQL82_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz"
        Tar_Cd ${MySQL82_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL82_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Installing ${MySQL82_Ver} use use Source cdoe..."
        Download "${MySQL82_URL}" "${MySQL82_Ver}.tar.gz"
        Tar_Cd ${MySQL82_Ver}.tar.gz ${MySQL82_Ver}
        mkdir build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        -DSYSCONFDIR=/etc \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DENABLED_LOCAL_INFILE=1 \
        -DWITH_BOOST=../boost \
        -DWITH_SSL=system

        Make_And_Install
    fi

    id -g mysql &>/dev/null || groupadd mysql
    id -u mysql &>/dev/null || useradd -r -M -s /sbin/nologin -g mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${Default_MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535
default_authentication_plugin = mysql_native_password

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
binlog_expire_logs_seconds = 864000
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_data_home_dir = ${Default_MySQL_Data_Dir}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = ${Default_MySQL_Data_Dir}
innodb_buffer_pool_size = 16M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M

[mysqlhotcopy]
interactive-timeout
EOF

    chown -R mysql:mysql /usr/local/mysql
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --user=mysql --datadir=${Default_MySQL_Data_Dir}
    MySQL_Init
}

MySQL_Init()
{
    chown -R mysql:mysql ${Default_MySQL_Data_Dir}
    \cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
    \cp ${CUR_DIR}/init.d/mysql.service /etc/systemd/system/mysql.service
    chmod 755 /etc/init.d/mysql
    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
    ldconfig
    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
    /etc/init.d/mysql start
    sleep 5
    /usr/local/mysql/bin/mysqladmin -u root password "${DBRootPasswd}"
    if [ $? -ne 0 ]; then
        Echo_Red "Failed to set MySQL root password, trying alternative methods."
        /etc/init.d/mysql restart
        Make_Mycnf
        if [[ "${DBSelect}" == "1" ]] || [[ "${DBSelect}" == "2" ]]; then
            Do_Query "UPDATE mysql.user SET Password=PASSWORD('${DBRootPasswd}') WHERE User='root';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
            Do_Query "FLUSH PRIVILEGES;"
            [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "Failed to FLUSH PRIVILEGES!"
        elif [[ "${DBSelect}" == "3" ]]; then
            Do_Query "UPDATE mysql.user SET authentication_string=PASSWORD('${DBRootPasswd}') WHERE User='root';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
            Do_Query "FLUSH PRIVILEGES;"
            [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "Failed to FLUSH PRIVILEGES!"
        elif [[ "${DBSelect}" == "4" ]] || [[ "${DBSelect}" == "5" ]]; then
            Do_Query "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DBRootPasswd}';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
        fi
        rm -f ~/.emptymy.cnf
    fi

    ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql
    ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
    ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
    ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
    ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck

    /etc/init.d/mysql restart
    /etc/init.d/mysql stop
    cd ${SRC_DIR}
}