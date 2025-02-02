OpenLXMP是一个使用Bash shell编写的LNMP、LAMP环境的一键安装包，使用OpenLXMP可以方便快捷的安装配置LNMP、LAMP环境。

安装：
以安装LNMP环境为例：

`wget https://github.com/OpenLXMP/OpenLXMP/archive/main.zip && unzip main.zip && bash OpenLXMP-main/install.sh --lnmp`

如安装LAMP将 --lnmp 替换为 --lamp ，除此之外还可以将 --lnmp 替换为 --nginx 只安装nginx，--mysql 只安装MySQL。

另外还有--php_fileinfo、--php_ldap、--php_bz2、--php_sodium、--php_imap 参数可以在安装时加上，加上将会开启对应的PHP扩展。

同时也可以修改openlxmp.conf来添加Nginx、PHP自定义编译参数、修改默认网站目录、数据库目录等信息。

有虚拟主机管理工具 lxmp 可用使用该工具添加虚拟主机，设置域名、目录、日志、SSL、数据库等信息。

另外也可以使用 addons.sh 脚本来安装redis、memcached、opcache、fileinfo、ldap、bz2、sodium、imap模块组件。