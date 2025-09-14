#!/usr/bin/env bash

Install_phpinfo()
{
    Echo_Blue "Create phpinfo..."
    cat >${Default_Website_Dir}/phpinfo.php<<EOF
<?php
phpinfo();
?>
EOF
}

Install_phpMyAdmin()
{
    Echo_Blue "Installing phpMyadmin..."
    cd ${SRC_DIR}
    if echo "${PHP_Ver}" | grep -Eq "^php-5.6.|php-7.[01]."; then
        Download "${phpMyAdmin4_URL}"
        Tar_Cd "${phpMyAdmin4_Ver}.tar.xz"
        mv "${phpMyAdmin4_Ver}" "${Default_Website_Dir}/phpmyadmin"
    elif echo "${PHP_Ver}" | grep -Eq "^php-7.[2-4]|php-8."; then
        Download "${phpMyAdmin5_URL}"
        Tar_Cd "${phpMyAdmin5_Ver}.tar.xz"
        mv "${phpMyAdmin5_Ver}" "${Default_Website_Dir}/phpmyadmin"
    fi

    mkdir "${Default_Website_Dir}"/phpmyadmin/{upload,save}
    cp "${Default_Website_Dir}/phpmyadmin/config.sample.inc.php" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['blowfish_secret'\] = .*;@\$cfg\['blowfish_secret'\] = '$(tr -dc 'A-HJ-NP-Za-hj-km-np-z2-9' < /dev/urandom | head -c 32)';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['UploadDir'\] = .*;@\$cfg\['UploadDir'\] = 'upload';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['SaveDir'\] = .*;@\$cfg\['SaveDir'\] = 'save';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    chown www:www -R "${Default_Website_Dir}/phpmyadmin"
}

Install_Adminer()
{
    Echo_Blue "Installing Adminer..."
    Download "${Adminer_URL}" "${Default_Website_Dir}/adminer.php"
    chown www:www -R "${Default_Website_Dir}/adminer.php"
}

Install_Default_Web()
{
    Echo_Blue "Copy defautl website index..."
    \cp "${SRC_DIR}/index.html" "${Default_Website_Dir}"
    Install_phpinfo
    Install_PHP_Probe
    if [[ "${DBSelect}" != "0" ]]; then
        Install_phpMyAdmin
        Install_Adminer
    fi
}


Install_PHP_Probe()
{
    Echo_Blue "Installing PHP Probe..."
    Download "${PHP_Probe_URL}" "${Default_Website_Dir}/p.php"
}