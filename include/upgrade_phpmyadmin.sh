#!/usr/bin/env bash

Upgrade_phpMyAdmin()
{
    phpmyadmin_ver=''
    Cur_PHPMyAdmin_Ver=$(grep "VERSION = '.*'" ${Default_Website_Dir}/phpmyadmin/libraries/classes/Version.php | awk -F"[ ']" '{print $10}')
    Echo_Cyan "Current phpMyAdmin Version: ${Cur_PHPMyAdmin_Ver}"
    Echo_Cyan "Please get the phpMyAdmin version number from https://www.phpmyadmin.net/downloads/"
    while [[ -z ${phpmyadmin_ver} ]]; do
        read -p "Please enter phpMyAdmin version, (example: 5.2.1): " phpmyadmin_ver
    done
    if [[ ${phpmyadmin_ver} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        Echo_Cyan "The PHPMyAdmin version that you have entered: ${phpmyadmin_ver}"
    else
        Echo_Red "Error: Invalid PHPMyAdmin version format."
        exit 1
    fi

    Press_Start
    Echo_Blue "Upgrading phpMyadmin..."
    cd ${SRC_DIR}
    Echo_Blue "Backup phpMyAdmin..."
    mv "${Default_Website_Dir}/phpmyadmin" "${Default_Website_Dir}/backup_phpmyadmin_${Upgrade_Date}"

    Download "https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_ver}/phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.xz"
    Tar_Cd "phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.xz"
    mv "phpMyAdmin-${phpmyadmin_ver}-all-languages" "${Default_Website_Dir}/phpmyadmin"

    mkdir "${Default_Website_Dir}"/phpmyadmin/{upload,save}
    cp "${Default_Website_Dir}/phpmyadmin/config.sample.inc.php" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['blowfish_secret'\] = .*;@\$cfg\['blowfish_secret'\] = '$(tr -dc 'A-HJ-NP-Za-hj-km-np-z2-9' < /dev/urandom | head -c 32)';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['UploadDir'\] = .*;@\$cfg\['UploadDir'\] = 'upload';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    sed -i "s@\$cfg\['SaveDir'\] = .*;@\$cfg\['SaveDir'\] = 'save';@" "${Default_Website_Dir}/phpmyadmin/config.inc.php"
    chown www:www -R "${Default_Website_Dir}/phpmyadmin"

    Echo_Green "phpMyAdmin has been successfully upgraded to the version: ${phpmyadmin_ver}."
}