#!/usr/bin/env bash

Backup_MySQL()
{
    Echo_Blue "Backup MySQL Databases..."
    /usr/local/mysql/bin/mysqldump --defaults-file=~/.my.cnf --add-drop-table --all-databases > /root/mysql_all_backup${Upgrade_Date}.sql
    if [[ $? -eq 0 ]]; then
        Echo_Blue "MySQL databases has been successfully backup to /root/mysql_all_backup${Upgrade_Date}.sql"
    else
        Echo_Red "MySQL databases backup failed."
    fi

    Echo_Blue "Backup MySQL files before upgrade..."
    mv /usr/local/mysql /usr/local/backup_mysql_${Upgrade_Date}
    mv /etc/init.d/mysql /usr/local/backup_mysql_${Upgrade_Date}/mysql_init.d
    mv /etc/my.cnf /usr/local/backup_mysql_${Upgrade_Date}/my.cnf.backup
    if [[ "${Default_MySQL_Data_Dir}" != "/usr/local/mysql/var" ]]; then
        mv ${Default_MySQL_Data_Dir} ${MySQL_Data_Dir}${Upgrade_Date}
    fi
}

MySQL_Init_Upgrade()
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
        if [[ $mysql_ver =~ ^(5\.5|5\.6) ]]; then
            Do_Query "UPDATE mysql.user SET Password=PASSWORD('${DBRootPasswd}') WHERE User='root';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
            Do_Query "FLUSH PRIVILEGES;"
            [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "Failed to FLUSH PRIVILEGES!"
        elif [[ $mysql_ver =~ ^5\.7 ]]; then
            Do_Query "UPDATE mysql.user SET authentication_string=PASSWORD('${DBRootPasswd}') WHERE User='root';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
            Do_Query "FLUSH PRIVILEGES;"
            [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "Failed to FLUSH PRIVILEGES!"
        elif [[ ! $mysql_ver =~ ^(8\.0|8\.2) ]]; then
            Do_Query "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DBRootPasswd}';"
            [ $? -eq 0 ] && echo "MySQL root password set Sucessfully." || echo "Failed to set MySQL root password!"
        fi
    fi

    echo "Restore backup databases..."
    /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf < /root/mysql_all_backup${Upgrade_Date}.sql
    echo "Repair databases..."
    if echo "${mysql_ver}" | grep -qE '^8\.0\.1[6-9]|[2-9][0-9]+$'; then
        /etc/init.d/mysql stop
        echo "Upgring MySQL..."
        /usr/local/mysql/bin/mysqld --user=mysql --upgrade=FORCE &
        echo "Waiting for upgrade to start..."
        sleep 180
        /usr/local/mysql/bin/mysqladmin --defaults-file=~/.my.cnf shutdown
    else
        /usr/local/mysql/bin/mysql_upgrade -u root -p${DBRootPasswd}
    fi

    /etc/init.d/mysql restart
    cd ${SRC_DIR}
}

Upgrade_MySQL()
{
    Cur_MySQL_Ver=$(/usr/local/mysql/bin/mysql_config --version)
    mysql_ver=''
    MySQL_Ver=''
    Get_Distro_Info

    Verify_MySQL_Password
    Echo_Cyan "Current MySQL Version: ${Cur_MySQL_Ver}"
    Echo_Cyan "Please get the MySQL version number from https://dev.mysql.com/downloads/mysql/"
    while [[ -z ${mysql_ver} ]]; do
        read -p "Please enter MySQL version, (example: 8.0.35): " mysql_ver
    done
    if [[ ${mysql_ver} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        Echo_Cyan "The MySQL version that you have entered: ${mysql_ver}"
    else
        Echo_Red "Error: Invalid MySQL version format."
        exit 1
    fi

    if [[ ! $mysql_ver =~ ^(5\.5|5\.6|5\.7|8\.0|8\.2) ]]; then
        Echo_Red "Error: MySQL ${mysql_ver} is not supported."
        exit 1
    fi

    MySQL_Ver="mysql-${mysql_ver}"

    if [[ $mysql_ver =~ ^(5\.5|5\.6|5\.7) ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "i686" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *)
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    elif [[ $mysql_ver =~ ^(8\.0) ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "i686" || "${ARCH}" == "aarch64" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *)
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    elif [[ $mysql_ver =~ ^(8\.2) ]] && [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
        read -p "Use Generic Binaries [y/n]: " Bin
        case ${Bin} in
            y|Y)
                Echo_Blue "Install MySQL use Generic Binaries"
                Bin="y"
                if [[ "${ARCH}" == "aarch64" ]]; then
                    GLIBC_VER='2.17'
                fi
                ;;
            n|N)
                Echo_Blue "Install MySQL use Source Code"
                Bin="n"
                ;;
            *)
                Echo_Red "Invalid input, Default use Generic Binaries"
                Bin='y'
                ;;
        esac
    else
        Bin="n"
    fi

    Press_Start
    Print_Sys_Info
    Backup_MySQL
    /etc/init.d/mysql stop
    cd ${SRC_DIR}
    case "${mysql_ver}" in
        5.5.*) Upgrade_MySQL_55 ;;
        5.6.*) Upgrade_MySQL_56 ;;
        5.7.*) Upgrade_MySQL_57 ;;
        8.0.*) Upgrade_MySQL_80 ;;
        8.2.*) Upgrade_MySQL_82 ;;
        *) Echo_Red "Error: MySQL ${mysql_ver} is not supported."; exit 1 ;;
    esac
}

Upgrade_MySQL_55()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Upgrading ${MySQL_Ver} use use Generic Binaries..."
        Download "https://dev.mysql.com/get/mysql-5.5/${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz" "${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        Tar_Cd ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Upgrading MySQL ${MySQL_Ver} use use Source cdoe..."
        Download "https://dev.mysql.com/get/mysql-5.5/${MySQL_Ver}.tar.gz" "${MySQL_Ver}.tar.gz"
        Tar_Cd ${MySQL_Ver}.tar.gz ${MySQL_Ver}
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

Upgrade_MySQL_56()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Upgrading ${MySQL_Ver} use use Generic Binaries..."
        Download "https://dev.mysql.com/get/mysql-5.6/${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz" "${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        Tar_Cd ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Upgrading MySQL ${MySQL_Ver} use use Source cdoe..."
        Download "https://dev.mysql.com/get/mysql-5.6/${MySQL_Ver}.tar.gz" "${MySQL_Ver}.tar.gz"
        if [[ "${isOpenSSL3}" == "y" ]]; then
            Install_Openssl
            MySQL_WITH_SSL='-DWITH_SSL=/usr/local/openssl1.1.1'
        else
            MySQL_WITH_SSL='-DWITH_SSL=system'
        fi
        Tar_Cd ${MySQL_Ver}.tar.gz ${MySQL_Ver}
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

Upgrade_MySQL_57()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Upgrading ${MySQL_Ver} use use Generic Binaries..."
        Download "https://dev.mysql.com/get/MySQL-5.7/${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz" "${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.gz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Upgrading MySQL ${MySQL_Ver} use use Source cdoe..."
        Download "https://dev.mysql.com/get/MySQL-5.7/mysql-boost-${mysql_ver}.tar.gz" "${MySQL_Ver}.tar.gz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL_Ver}.tar.gz ${MySQL_Ver}
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

Upgrade_MySQL_80()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Upgrading ${MySQL_Ver} use use Generic Binaries..."
        Download "https://dev.mysql.com/get/MySQL-8.0/${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz" "${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Upgrading MySQL ${MySQL_Ver} use use Source cdoe..."
        Download "https://dev.mysql.com/get/MySQL-8.0/mysql-boost-${mysql_ver}.tar.gz" "${MySQL_Ver}.tar.gz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL_Ver}.tar.gz ${MySQL_Ver}
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

Upgrade_MySQL_82()
{
    if [[ "${Bin}" == "y" ]]; then
        Echo_Blue "Upgrading MySQL ${MySQL80_Ver} use use Generic Binaries..."
        Download "https://dev.mysql.com/get/MySQL-8.2/${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz" "${MySQL_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL82_Ver}-linux-glibc${GLIBC_VER}-${ARCH}.tar.xz
        [ ! -d /usr/local/mysql ] && mkdir /usr/local/mysql
        mv ${MySQL82_Ver}-linux-glibc${GLIBC_VER}-${ARCH}/* /usr/local/mysql/
    else
        Echo_Blue "Upgrading MySQL ${MySQL82_Ver} use use Source cdoe..."
        Download "https://dev.mysql.com/get/MySQL-8.2/${MySQL_Ver}.tar.gz" "${MySQL_Ver}.tar.gz"
        if [ $? -ne 0 ]; then
            Echo_Red "Unable to download the MySQL installation file."
            exit 1
        fi
        Tar_Cd ${MySQL_Ver}.tar.gz ${MySQL_Ver}
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
    fi

    ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql
    ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
    ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
    ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
    ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck

    Echo_Blue "Restore backup databases from SQL file..."
    /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf < /root/mysql_all_backup${Upgrade_Date}.sql

    Echo_Blue "Upgrading databases..."
    if [[ "${mysql_ver}" == "8.0.16" || "${mysql_ver}" > "8.0.16" ]]; then
        /etc/init.d/mysql stop
        /usr/local/mysql/bin/mysqld --user=mysql --upgrade=FORCE &
        sleep 300
        /usr/local/mysql/bin/mysqladmin --defaults-file=~/.my.cnf shutdown
    else
        /usr/local/mysql/bin/mysql_upgrade -u root -p${DBRootPasswd}
    fi

    cd ${SRC_DIR}
    Del_Mycnf
    if [[ -s /usr/local/mysql/bin/mysql ]]; then
        /etc/init.d/mysql restart
        Echo_Green "MySQL has been successfully upgraded to the version: ${mysql_ver}."
    else
        Echo_Red "MySQL upgrade failed."
    fi
}