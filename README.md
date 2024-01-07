OpenLXMP is a one-click installation package for LNMP and LAMP environments written in Bash shell. Using OpenLXMP, you can easily and quickly install and configure LNMP and LAMP environments.

Installation:

To install the LNMP environment as an example:

`wget https://github.com/OpenLXMP/OpenLXMP/archive/main.zip && unzip main.zip && bash OpenLXMP-main/install.sh --lnmp`

To install LAMP, replace --lnmp with --lamp.

Additionally, you can add the following parameters: --php_fileinfo, --php_ldap, --php_bz2, --php_sodium, --php_imap. Adding these parameters will enable the corresponding PHP extensions.

You can also modify the openlxmp.conf file to add custom Nginx and PHP compilation parameters, and to modify the default website directory, database directory, and other information.