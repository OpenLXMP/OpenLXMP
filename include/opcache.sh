#!/usr/bin/env bash

Install_Opcache()
{
    Echo_Blue "Installing Redis..."
    Press_Start
    Print_Sys_Info

    cd ${SRC_DIR}
    Get_Ext_Dir

    if [[ ${cur_php_ver} =~ ^[5-7]\. ]]; then
        cat >/usr/local/php/conf.d/opcache.ini<<EOF
[Zend Opcache]
zend_extension = "opcache.so"
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.use_cwd = 1
EOF
    elif [[ ${cur_php_ver} =~ ^8\. ]]; then
        cat >/usr/local/php/conf.d/opcache.ini<<EOF
[Zend Opcache]
zend_extension = "opcache.so"
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.use_cwd = 1

opcache.jit = 1255
opcache.jit_buffer_size = 64M
EOF
    fi

    if [[ -s "${php_ext_dir}/opcache.so" ]]; then
        Echo_Green "Opcache has been successfully installed."
    else
        Echo_Red "Opcache install failed."
    fi
}