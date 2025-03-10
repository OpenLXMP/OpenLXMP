#!/usr/bin/env bash

Get_Distro_Info()
{
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_Name=${ID}
        OS_Version=${VERSION_ID}
    fi

    case ${OS_Name} in
        "debian")
            DISTRO='Debian'
            PM='apt'
            ;;
        "ubuntu")
            DISTRO='Ubuntu'
            PM='apt'
            ;;
        "raspbian")
            DISTRO='Raspbian'
            PM='apt'
            ;;
        "kali")
            DISTRO='Kali'
            PM='apt'
            ;;
        "linuxmint")
            DISTRO='Mint'
            PM='apt'
            ;;
        "centos")
            DISTRO='CentOS'
            PM='yum'
            ;;
        "almalinux")
            DISTRO='Alma'
            PM='yum'
            ;;
        "rocky")
            DISTRO='Rocky'
            PM='yum'
            ;;
        "fedora")
            DISTRO='Fedora'
            PM='yum'
            ;;
        "rhel")
            DISTRO='RHEL'
            PM='yum'
            ;;
        "ol")
            DISTRO='Oracle'
            PM='yum'
            ;;
        "openEuler")
            DISTRO='openEuler'
            PM='yum'
            ;;
        "euleros")
            DISTRO='EulerOS'
            PM='yum'
            ;;
        "anolis")
            DISTRO='Anolis'
            PM='yum'
            ;;
        "alinux")
            DISTRO='Alibaba'
            PM='yum'
            ;;
        "opencloudos")
            DISTRO='OpenCloudOS'
            PM='yum'
            ;;
        "kylin")
            DISTRO='Kylin'
            command -v apt >/dev/null 2>&1 && PM='apt' || PM='yum'
            ;;
        "Deepin")
            DISTRO='Deepin'
            command -v apt >/dev/null 2>&1 && PM='apt' || PM='yum'
            ;;
        "uos")
            DISTRO='UOS'
            command -v apt >/dev/null 2>&1 && PM='apt' || PM='yum'
            ;;
        *)
            echo "Unsupported Linux distribution: ${OS_Name} ${OS_Version}"
            exit 1
            ;;
    esac

    eval "${DISTRO}_VERSION=\$OS_Version"

    local architecture=$(uname -m)
    case $architecture in
        "i386" | "i686")
            ARCH='i686'
            GLIBC_VER='2.12'
            ;;
        "x86_64")
            ARCH='x86_64'
            GLIBC_VER='2.12'
            ;;
        "aarch64")
            ARCH='aarch64'
            GLIBC_VER='2.28'
            ;;
        "armv6" | "armv7l")
            ARCH='arm'
            ;;
    esac
}

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
cyan="\e[36m"
reset="\e[0m"

Echo_Red()
{
  echo -e "\\033[31m$*\\033[m"
}

Echo_Yellow()
{
  echo -e "\\033[33m$*\\033[m"
}

Echo_Blue()
{
  echo -e "\\033[34m$*\\033[m"
}

Echo_Green() {
  echo -e "\\033[32m$*\\033[m"
}

Echo_Cyan() {
    echo -e "\\033[36m$*\\033[m"
}

Print_Sys_Info()
{
    Echo_Blue "OS: ${DISTRO} ${DISTRO_VERSION}"
    CPUModel=$(awk -F':' '/model name/ {print $2}' /proc/cpuinfo | uniq | sed 's/^ *//')
    CPUCores=$(awk '/processor/ {count++} END {print count}' /proc/cpuinfo)
    MemTotal=$(awk '/MemTotal/ {printf "%.0f\n", $2/1024}' /proc/meminfo)
    MemAvailable=$(awk '/MemAvailable/ {printf "%.0f\n", $2/1024}' /proc/meminfo)
    SwapTotal=$(awk '/SwapTotal/ {printf "%.0f\n", $2/1024}' /proc/meminfo)
    Echo_Blue "CPU Model: ${CPUModel}"
    Echo_Blue "CPU Cores: ${CPUCores}"
    Echo_Blue "Total Memory: ${MemTotal}"
    Echo_Blue "Available Memory: ${MemAvailable}"
    Echo_Blue "Total Swap: ${SwapTotal}"
    cat /etc/issue
    cat /etc/*-release
    uname -a
    df -h
    uptime
}

Print_Install_Info()
{
    Echo_Blue "List install information..."
    Echo_Blue "OpenLXMP Ver: ${LXMP_Ver}"
    Echo_Blue "Stack: ${STACK}"
    Echo_Blue "Nginx addition module: ${Nginx_Modules_Options}"
    Echo_Blue "PHP addition extension: ${PHP_Modules_Options}"
    Echo_Blue "Default Website dir: ${Default_Website_Dir}"
    Echo_Blue "Default MySQL data dir: ${Default_MySQL_Data_Dir}"
    Echo_Blue "PHP extension fileinfo: ${Enable_PHP_Fileinfo}"
    Echo_Blue "PHP extension ldap: ${Enable_PHP_LDAP}"
    Echo_Blue "PHP extension fileinfo: ${Enable_PHP_Bz2}"
    Echo_Blue "PHP extension sodium: ${Enable_PHP_Sodium}"
    Echo_Blue "PHP extension imap: ${Enable_PHP_Imap}"
    Echo_Blue "Timezone: ${TimeZone}"
    if [[ "${STACK}" == "lnmp" ]]; then
        Echo_Blue "${Nginx_Ver}"
    elif [[ "${STACK}" == "lamp" ]]; then
        Echo_Blue "${Apache_Ver}"
    fi
    Echo_Blue "${PHP_Ver}"
}

Press_Start()
{
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel."
    read -n 1 -s
    Start_Time=$SECONDS
}

Download()
{
    local urls=($1)
    local filename="$2"
    local success=0

    if [ -s "${filename}" ]; then
        echo "${filename} [found]"
        return 0
    else
        echo "Downloading ${filename}..."
        for url in "${urls[@]}"; do
            if [[ -n "${filename}" ]]; then
                wget --progress=dot -e dotbytes=10M -c --no-check-certificate -O "${filename}" "${url}"
            else
                wget --progress=dot -e dotbytes=10M -c --no-check-certificate "${url}"
            fi

            if [ $? -eq 0 ]; then
                success=1
                break
            else
                echo "Failed to download from ${url}, trying next URL..."
            fi
        done

        if [ $success -eq 0 ]; then
            echo "Failed to download ${filename} from all provided URLs."
            return 1
        else
            echo "Successfully downloaded ${filename}."
            return 0
        fi
    fi
}

Tar_Cd()
{
    local filename="$1"
    local dirname="$2"
    cd ${CUR_DIR}/src
    [[ -d "${dirname}" ]] && rm -rf ${dirname}
    echo "Uncompress ${filename}..."
    tar xf "${filename}"
    if [[ -n "${dirname}" ]]; then
        echo "cd ${dirname}..."
        cd ${dirname}
    fi
}

Cmd_Exists()
{
    local cmd="$1"

    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    ret="$?"
    return $ret
}

Make_Mycnf()
{
    cat >~/.my.cnf<<EOF
[client]
user=root
password='$1'
EOF
    chmod 600 ~/.my.cnf
}

Do_Query()
{
    echo "$1" >/tmp/.mysql.query
    /usr/local/mysql/bin/mysql --defaults-file=~/.my.cnf </tmp/.mysql.query
    ret="$?"
    rm -f /tmp/.mysql.query
    return $ret
}

Del_Mycnf()
{
    rm -f ~/.my.cnf
}

Verify_MySQL_Password()
{
    status=1
    while [ $status -eq 1 ]; do
        read -s -p "Enter current root password of MySQL (Password not displayed): " DBRootPasswd
        Make_Mycnf "${DBRootPasswd}"
        Do_Query ""
        status=$?
    done
    echo "OK, MySQL root password correct."
}

Check_Systemd()
{
    if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
        return 0
    fi

    if command -v systemctl >/dev/null 2>&1 && systemctl list-units --type=service >/dev/null 2>&1; then
        return 0
    fi

    if [ -d "/run/systemd/system" ]; then
        return 0
    fi

    return 1
}

Enable_Startup()
{
    local service_name="$1"
    Echo_Blue "Enable ${service_name} to start on boot..."
    if Check_Systemd && [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl daemon-reload
        systemctl enable ${service_name}.service
    else
        if [[ "${PM}" == "yum" ]]; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        elif [[ "${PM}" == "apt" ]]; then
            update-rc.d -f ${service_name} defaults
        fi
    fi
}

Disable_Startup()
{
    local service_name="$1"
    Echo_Blue "Disable ${service_name} from starting on boot..."
    if Check_Systemd && [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl daemon-reload
        systemctl disable ${service_name}.service
    else
        if [[ "${PM}" == "yum" ]]; then
            chkconfig ${service_name} off
            chkconfig --del ${service_name}
        elif [[ "${PM}" == "apt" ]]; then
            update-rc.d -f ${service_name} remove
        fi
    fi
}

Start()
{
    local service_name="$1"
    Echo_Blue "Start ${service_name} ..."
    if Check_Systemd && [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl start ${service_name}.service
    else
        /etc/init.d/${service_name} start
    fi
}

Stop()
{
    local service_name="$1"
    Echo_Blue "Stop ${service_name} ..."
    if Check_Systemd && [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl stop ${service_name}.service
    else
        /etc/init.d/${service_name} stop
    fi
}

Check_Stack()
{
    if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/nginx/sbin/nginx ]]; then
        STACK='lnmp'
    elif [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/conf/httpd.conf ]]; then
        STACK='lamp'
    else
        STACK='unknown'
    fi
}

Get_Ext_Dir()
{
    if [[ -s /usr/local/php/bin/php-config ]]; then
        php_ext_dir=$(/usr/local/php/bin/php-config --extension-dir)
        cur_php_ver=$(/usr/local/php/bin/php-config --version)
    else
        echo "php-config not found."
        exit 1
    fi
}