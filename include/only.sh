#!/usr/bin/env bash

Install_Nginx_Dependency()
{
    Echo_Blue "Install Nginx dependencies..."
    if [[ "${PM}" = "yum" ]]; then
        if yum list installed httpd > /dev/null 2>&1; then
            echo "Removing Apache package..."
            yum remove -y httpd
        else
            echo "Apache is not installed on this system."
        fi
        local YUM_INSTALL_PKGS='make gcc gcc-c++ gcc-g77 wget zlib zlib-devel openssl openssl-devel perl patch bzip2 initscripts xz gzip pcre-devel'
        local packages
        for packages in ${YUM_INSTALL_PKGS}
            do yum install $packages -y
        done
        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi
    elif [[ "${PM}" = "apt" ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        local APT_INSTALL_PKGS='debian-keyring debian-archive-keyring build-essential gcc g++ make autoconf automake wget openssl libssl-dev zlib1g zlib1g-dev bzip2 xz-utils gzip libpcre3-dev'
        local packages
        for packages in ${APT_INSTALL_PKGS}
            do apt-get --no-install-recommends install $packages -y
        done
    fi
}

Install_MySQL_Dependency()
{
    Echo_Blue "Install MySQL dependencies..."
    if [[ "${PM}" = "yum" ]]; then
        local packages=(mysql mysql-server mysql-common mariadb mariadb-server mariadb-common)
        for pkg in "${packages[@]}"; do
            if yum list installed "$pkg" > /dev/null 2>&1; then
                echo "Uninstalling $pkg ..."
                yum remove -y "$pkg"
            fi
        done
        local YUM_INSTALL_PKGS='make cmake gcc gcc-c++ gcc-g77 flex bison wget zlib zlib-devel openssl openssl-devel ncurses ncurses-devel libaio-devel rpcgen libtirpc-devel patch cyrus-sasl-devel pkg-config pcre-devel libxml2-devel hostname ncurses-libs numactl-devel libxcrypt gnutls-devel initscripts libxcrypt-compat perl xz gzip'
        local packages
        for packages in ${YUM_INSTALL_PKGS}
            do yum install $packages -y
        done
        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi

        if [[ "${CentOS_VERSION}" =~ ^8 || "${RHEL_VERSION}" =~ ^8 || "${Rocky_VERSION}" =~ ^8 || "${Alma_VERSION}" =~ ^8 || "${Anolis_VERSION}" =~ ^8 || "${OpenCloudOS_VERSION}" =~ ^8 ]]; then
            repo_id=$(yum repolist all|grep -Ei "PowerTools"|head -n 1|awk '{print $1}')
            dnf --enablerepo=${repo_id} install rpcgen -y
            dnf install libarchive -y

            dnf install gcc-toolset-10 -y
        fi

        if [[ "${Oracle_VERSION}" =~ ^8 ]]; then
            repo_id=$(yum repolist all|grep -Ei "CodeReady"|head -n 1|awk '{print $1}')
            dnf --enablerepo=${repo_id} install rpcgen re2c -y
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
    elif [[ "${PM}" = "apt" ]]; then
        local packages=(mysql-client mysql-common mysql-server mariadb-client mariadb-common mariadb-server)
        for pkg in "${packages[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                echo "Uninstalling $pkg ..."
                apt-get remove --purge -y "$pkg"
            fi
        done
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        local APT_INSTALL_PKGS='debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake wget openssl libssl-dev zlib1g zlib1g-dev libncurses5 libncurses5-dev bison libaio-dev libtirpc-dev libsasl2-dev pkg-config libpcre2-dev libxml2-dev libtinfo-dev libnuma-dev gnutls-dev xz-utils gzip'
        local packages
        for packages in ${APT_INSTALL_PKGS}
            do apt-get --no-install-recommends install $packages -y
        done
    fi
}

Only_Install_Nginx()
{
    echo "===================== Install Ningx ======================"
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel."
    read -n 1 -s
    Install_Nginx_Dependency
    cd ${SRC_DIR}
    Download "${OpenSSL_URL}" "${OpenSSL_Ver}.tar.gz"
    Download "${Nginx_URL}" "${Nginx_Ver}.tar.gz"
    Install_Nginx
    Check_Nginx
    if [[ "${Nginx_Install_Status}" == "y" ]]; then
        Enable_Startup nginx
        systemctl start nginx
        Echo_Green "Nginx has been successfully installed."
    else
        Echo_Red "Nginx install log: /root/openlxmp-nginx-install.log"
    fi
}

Only_Install_MySQL()
{
    MySQL_Select_Menu
    if [[ "${DBSelect}" != "0" ]]; then
        MySQL_Use_Bin
        MySQL_Innodb_Option
        Set_DB_Root_Password
    fi
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel."
    read -n 1 -s
    cd ${SRC_DIR}
    Install_MySQL_Dependency
    case "${DBSelect}" in
        1) Install_MySQL_55 ;;
        2) Install_MySQL_56 ;;
        3) Install_MySQL_57 ;;
        4) Install_MySQL_80 ;;
        5) Install_MySQL_84 ;;
    esac
    Check_MySQL
    if [[ "${MySQL_Install_Status}" == "y" ]]; then
        Enable_Startup mysql
        systemctl start mysql
        Echo_Green "MySQL has been successfully installed."
    else
        Echo_Red "MySQL install log: /root/openlxmp-mysql-install.log"
    fi
}