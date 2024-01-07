OpenLXMP是一个使用Bash shell编写的LNMP、LAMP环境的一键安装包，使用OpenLXMP可以方便快捷的安装配置LNMP、LAMP环境。

安装：
以安装LNMP环境为例：

`wget https://github.com/OpenLXMP/OpenLXMP/archive/main.zip && unzip main.zip && bash OpenLXMP-main/install.sh --lnmp`

如安装LAMP将--lnmp替换为--lamp。
另外还有--php_fileinfo、--php_ldap、--php_bz2、--php_sodium、--php_imap 参数可以加上，加上将会开启对应的PHP扩展。
同时也可以修改openlxmp.conf来添加Nginx、PHP自定义编译参数、修改默认网站目录、数据库目录等信息。