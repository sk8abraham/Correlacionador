#!/bin/bash

#####################
#####   Apache   ####
#####################
if [ `id -u` -eq 0 ]; then
    yum install gcc make libxml2 libxml2-devel httpd-devel pcre-devel curl-devel -y
    cd /usr/src/
    wget http://www.modsecurity.org/download/modsecurity-apache_2.6.7.tar.gz
    tar xzvf modsecurity-apache_2.6.7.tar.gz
    cd modsecurity-apache_2.6.7
    ./configure
    make install
    cp modsecurity.conf-recommended /opt/zimbra/conf/mod_security.conf
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /opt/zimbra/conf/mod_security.conf

cat <<EOF >>/opt/zimbra/conf/httpd.conf
<IfModule mod_security2.c>
    SecRuleEngine On
</IfModule>
EOF
# Reinciar Apache2
su - zimbra -c 'zmapachectl restart'

#####################
#####   Nginx   #####
#####################
yum groupinstall -y "Development Tools"
yum install -y httpd httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel
cd /usr/src/
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install

git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
wget http://nginx.org/download/nginx-1.13.7.tar.gz 
tar zxvf nginx-1.13.7.tar.gz 
cd nginx-1.13.7
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /opt/zimbra/conf/nginx/modules
sed -i 's/nginx.conf.web;/&\nload_module \/opt\/zimbra\/conf\/nginx\/modules\/ngx_http_modsecurity_module.so;/' /opt/zimbra/conf/nginx.conf 
mkdir /opt/zimbra/conf/nginx/modsec
wget -P /opt/zimbra/conf/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
wget -P /opt/zimbra/conf/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping
mv /opt/zimbra/conf/nginx/modsec/modsecurity.conf-recommended /opt/zimbra/conf/nginx/modsec/modsecurity.conf

sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /opt/zimbra/conf/nginx/modsec/modsecurity.conf
cat <<EOF > /opt/zimbra/conf/nginx/modsec/main.conf
Include "/opt/zimbra/conf/nginx/modsec/modsecurity.conf"
# Regla de prueba
SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403"
EOF
sed -i 's/nginx.conf.docs.common;/&\nmodsecurity on;\nmodsecurity_rules_file \/opt\/zimbra\/conf\/nginx\/modsec\/main\.conf;/' /opt/zimbra/conf/nginx/includes/nginx.conf.web.https.default

else
    echo "Deberias ejecutar el script como root"
fi


##### Fuentes #####
# https://malware.expert/howto/how-to-install-nginx-with-modsecurity-v3-0/
# http://www.servermom.org/how-to-install-modsecurity-with-owasp-on-apache-server/ 
# https://serverfault.com/questions/777978/install-mod-security-for-nginx-without-need-to-recompile  
# https://tecadmin.net/install-modsecurity-with-apache-on-centos-rhel/
# https://webhostinggeeks.com/howto/how-to-install-mod_security-to-apache-http-server-on-centos-6-3/
# https://geekflare.com/install-modsecurity-on-nginx/
