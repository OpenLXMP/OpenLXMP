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

Press_Start()
{
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel."
    read -n 1 -s
}

Download()
{
    local url="$1"
    local filename="$2"
    if [ -s "${filename}" ]; then
        echo "${filename} [found]"
    else
        echo "Downloading ${filename}..."
        if [[ -n "${filename}" ]]; then
            wget --progress=dot -e dotbytes=10M -c --no-check-certificate -O "$filename" "$url"
        else
            wget --progress=dot -e dotbytes=10M -c --no-check-certificate "$url"
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

Enable_Startup()
{
    local service_name="$1"
    if [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl daemon-reload
        systemctl enable ${service_name}.service
    fi
}

Disable_Startup()
{
    local service_name="$1"
    if [[ -s /etc/systemd/system/${service_name}.service ]]; then
        systemctl daemon-reload
        systemctl disable ${service_name}.service
    fi
}