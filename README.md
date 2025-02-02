OpenLXMP is a one-click installation package for LNMP and LAMP environments written in Bash shell. Using OpenLXMP, you can easily and quickly install and configure LNMP and LAMP environments.

Installation:

To install the LNMP environment as an example:

`wget https://github.com/OpenLXMP/OpenLXMP/archive/main.zip && unzip main.zip && bash OpenLXMP-main/install.sh --lnmp`

To install LAMP, replace --lnmp with --lamp. Additionally, you can replace --lnmp with --nginx to install only Nginx, or --mysql to install only MySQL.

There are also parameters like --php_fileinfo, --php_ldap, --php_bz2, --php_sodium, and --php_imap that can be added during installation to enable the corresponding PHP extensions.

You can also modify openlxmp.conf to add custom compilation parameters for Nginx and PHP, and to change the default website directory, database directory, and other information.

There is a virtual host management tool called LXMP that can be used to add virtual hosts, set domain names, directories, logs, SSL, database, and other information.

Additionally, you can use the addons.sh script to install modules such as Redis, Memcached, Opcache, Fileinfo, LDAP, BZ2, Sodium, and IMAP.