#!/bin/bash

##############
## CentOS 7 ##
##############
if   [[ `rpm -qa '(oraclelinux|sl|redhat|centos)-release(|-server)'|cut -d"-" -f3` == "7" ]]; then
echo -e "    \e[32mAplicando politicas de Hardening en un sistema:"
#echo -e "\e[32mEs un sistema:" 
cat /etc/system-release

echo -e "\e[32mActualizando repositorios y sistema"
yum update -y 1> /dev/null 2> error.txt

echo -e "\e[32mDetener servicio de postfix"
systemctl disable postfix 1> /dev/null 2>> error.txt 
if [ $? -ne 0 ]; then
systemctl stop postfix 1> /dev/null 2>> error.txt 
else
echo -e "\e[32mPostfix no esta instalado"
fi


echo -e "\e[32mDeshabilitar cuentas de usuario"
# Obtener el numero maximo de UID
uid=$(grep "^UID_MIN" /etc/login.defs)
# Imprimir Usuarios:
awk -F':' -v "limit=${uid##UID_MIN}" '{ if ( $3 >= limit ) print $1}' /etc/passwd > users.txt
for user in `more users.txt`
do
usermod --shell /usr/sbin/nologin "$user" 1> /dev/null 2>> error.txt 
done

echo -e "\e[32mCambiando las Politicas de contraseñas"
echo -e "\e[32mCreando respaldo de politicas de passwords"
cp /etc/security/pwquality.conf /etc/security/pwquality.conf.original
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.original
authconfig --enablereqlower --enablerequpper --enablereqdigit --enablereqother --passminlen=8 --passmaxrepeat=3 --update 1> /dev/null 2>> error.txt 
sed -i 's/authtok_type=/authtok_type= enforce_for_root/' /etc/pam.d/system-auth

# LogWatch
echo -e "\e[32mInstalando y Configurando LogWatch"
yum install -y logwatch 1> /dev/null 2>> error.txt 
# Configurar servicio.
logwatch --detail Medium --mailto admin@kibanosos.net --service ALL --range today 1> /dev/null 2>> error.txt 

# LogCheck
echo -e "\e[32mInstalando y Configurando LogCheck"
#yum install -y epel-release logcheck 1> /dev/null 2>> error.txt 
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 1> /dev/null 2>> error.txt
yum install -y logcheck 1> /dev/null 2>> error.txt
# Respaldo de archivos de configuracion
cp /etc/logcheck/logcheck.conf{,.back} 1> /dev/null 2>> error.txt 
cp /etc/logcheck/logcheck.logfiles{,.back} 1> /dev/null 2>> error.txt 
sed -i 's/"logcheck"/="admin@kibanosos.net"/' /etc/logcheck/logcheck.conf 1> /dev/null 2>> error.txt 
cat <<EOF >>/etc/logcheck/logcheck.logfiles
/var/log/boot.log
/var/log/maillog
/var/log/firewalld
/var/log/syslog
/var/log/auth.log
/var/log/apache2/error.log
/var/log/clamav/clamav.log
/var/log/deamon.log
/var/log/mail.err
/var/log/mail.warn
EOF

# fail2ban
echo -e "\e[32mInstalando Fail2ban"
yum makecache fast  1> /dev/null 2> error.txt 
yum install -y fail2ban fail2ban-firewalld fail2ban-systemd mariadb-server 1> /dev/null 2>> error.txt 
echo -e "\e[32mConfigurando Fail2ban"
# Habilitando y iniciando el servicio
systemctl enable fail2ban.service 1> /dev/null 2>> error.txt 
systemctl start fail2ban.service 1> /dev/null 2>> error.txt  
# Creamos una copia de seguridad de los archivos de configuracion
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local 1> /dev/null 2>> error.txt 
# Configurando SSH
sed -i "/^\[sshd\]/a\\enabled=true" /etc/fail2ban/jail.local 1> /dev/null 2>> error.txt 
# Configurando APACHE
sed -i "/^\[apache-auth\]/a\\enabled=true" /etc/fail2ban/jail.local 1> /dev/null 2>> error.txt 
# Configurando NGINX
sed -i "/^\[nginx-http-auth\]/a\\enabled=true" /etc/fail2ban/jail.local 1> /dev/null 2>> error.txt 
# Configurando MariaDB
sed -i "/^\[mysqld-auth\]/a\\enabled=true" /etc/fail2ban/jail.local 1> /dev/null 2>> error.txt 
sed -i "/^\[mysqld\]/a\\log-warnings=2" /etc/my.cnf 1> /dev/null 2>> error.txt 
systemctl restart mariadb.service
systemctl restart fail2ban.service

# HIDS (OSSEC)

mkdir /tmp/OSSEC && cd /tmp/OSSEC
echo -e "\e[32mInstalacion y configuracion de OSSEC"
# descarga
yum install -y zlib-devel gcc inotify-tools wget 1> /dev/null 2>> error.txt 
wget -N https://github.com/ossec/ossec-hids/archive/3.3.0.tar.gz 1> /dev/null 2>> error.txt 
tar xf 3.3.0.tar.gz -C /tmp/OSSEC  1> /dev/null 2>> error.txt 
wget -N https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz --no-check-certificate  1> /dev/null 2>> error.txt 
tar zxf pcre2-10.32.tar.gz -C /tmp/OSSEC/ossec-hids-3.3.0/src/external/   1> /dev/null 2>> error.txt 
cd /tmp/OSSEC/ossec-hids-3.3.0
# Instalacion
echo -e "\n\nlocal\n\nn\n\n\n\n\n\n\n" | ./install.sh 1> /dev/null 2>> error.txt 
echo -e "\e[32mCambiando correo a admin@kibanosos.net en configuracion de ossec"
# sed -i "s/<email_notification>no<\/email_notification>/<email_notification>yes<\/email_notification>/" /var/ossec/etc/ossec.conf
#<global>
#    <email_notification>yes</email_notification>
#    <smtp_server>localhost</smtp_server>
#    <email_from>wazuhtest@testserver.com</email_from>
#    <email_to>destinationMail@testserver1.com</email_to>
#    <email_maxperhour>12</email_maxperhour>
#  </global>

# Ejecutar servicio
/var/ossec/bin/ossec-control start

#### Sudo
echo -e "\e[32mInstalando sudo"
yum install -y sudo 1> /dev/null 2>> error.txt
grep "Politicas nuevas" /etc/sudoers
if [ $? -ne 0 ]; then
echo -e "\e[32mConfigurando politicas de sudo:"
cat << EOF >> /etc/sudoers
# Politicas nuevas
Defaults	log_host, log_year, logfile="/var/log/sudo.log"
Defaults	lecture="always" 
Defaults	badpass_message="La contraseña es incorrecta, esto sera reportado"
Defaults	passwd_tries=5 
Defaults    passwd_timeout=5
EOF
else
echo -e "\e[32mLas politicas ya fueron aplicadas"
fi

##############
## CentOS 6 ##
##############
elif [[ `rpm -qa '(oraclelinux|sl|redhat|centos)-release(|-server)'|cut -d"-" -f3` == "6" ]]; then
echo -e "    \e[32mAplicando politicas de Hardening en un sistema:"
#echo -e "\e[32mEs un sistema:" 
cat /etc/system-release

cho -e "\e[32mActualizando repositorios y sistema"
yum update -y 1> /dev/null 2> error.txt

echo -e "\e[32mDetener servicio de postfix"
chkconfig postfix off
if [ $? -ne 0 ]; then
postfix stop
else
echo -e "\e[32mpostfix no esta instalado"
fi

echo -e "\e[32mDeshabilitar cuentas de usuario"
# Obtener el numero maximo de UID
uid=$(grep "^UID_MIN" /etc/login.defs)
# Imprimir Usuarios:
awk -F':' -v "limit=${uid##UID_MIN}" '{ if ( $3 >= limit ) print $1}' /etc/passwd > users.txt
for user in `more users.txt`
do
usermod --shell /sbin/nologin "$user" 1> /dev/null 2>> error.txt
done

echo -e "\e[32mCambiando las Politicas de contraseñas"
echo -e "\e[32mCreando respaldo de politicas de passwords"
#cp /etc/security/pwquality.conf /etc/security/pwquality.conf.original
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.original
cp /etc/pam.d/password-auth /etc/pam.d/password-auth.original
# Utilizar Mayusculas, Minusculas, Digitos y Cararcteres
sed -i 's/type=/type= minlen=8 dcredit=-2 ucredit=-1 lcredit=-1 ocredit=-1/' /etc/pam.d/system-auth
# Negando la utilización de contraseñas
sed -i 's/use_authtok /use_authtok remember=5/' /etc/pam.d/system-auth
# Denegar el acceso despues de colocar erroneamente la contraseña
sed -i 's/type=/type= minlen=8 dcredit=-2 ucredit=-1 lcredit=-1 ocredit=-1/' /etc/pam.d/password-auth
sed -i 's/pam_env.so/&\nauth       required        pam_tally2.so deny=5/g' /etc/pam.d/password-auth
sed -i 's/required      pam_unix.so/&\naccount     required      pam_tally2.so/g' /etc/pam.d/password-auth

# LogWatch
echo -e "\e[32mInstalando y Configurando LogWatch"
yum install -y logwatch 1> /dev/null 2>> error.txt
# Configurar servicio.
logwatch --detail Medium --mailto admin@kibanosos.net --service ALL --range today 1> /dev/null 2>> error.txt

# LogCheck
echo -e "\e[32mInstalando y Configurando LogCheck"
yum install -y epel-release logcheck 1> /dev/null 2>> error.txt
# Respaldo de archivos de configuracion
cp /etc/logcheck/logcheck.conf{,.back}
cp /etc/logcheck/logcheck.logfiles{,.back}
sed -i 's/"logcheck"/="admin@kibanosos.net"/' /etc/logcheck/logcheck.conf
cat <<EOF >>/etc/logcheck/logcheck.logfiles
/var/log/boot.log
/var/log/maillog
/var/log/firewalld
/var/log/syslog
/var/log/auth.log
/var/log/apache2/error.log
/var/log/clamav/clamav.log
/var/log/deamon.log
/var/log/mail.err
/var/log/mail.warn
EOF

# fail2ban
yum install -y fail2ban 1> /dev/null 2>> error.txt
echo -e "\e[32mInstalando y Configurando Fail2ban"
# Habilitando y iniciando el servicio
chkconfig --level 23 fail2ban on 1> /dev/null 2>> error.txt
service fail2ban start 1> /dev/null 2>> error.txt
# Creamos una copia de seguridad de los archivos de configuracion
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Configurando SSH, ftpd, postfix
cat <<EOF >> /etc/fail2ban/jail.local
[ssh-iptables]

enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
#           sendmail-whois[name=SSH, dest=admin@kibanosos.net, sender=fail2ban@kibanosos.net]
logpath  = /var/log/secure
maxretry = 5

[proftpd-iptables]

enabled  = false
filter   = proftpd
action   = iptables[name=ProFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=ProFTPD, dest=admin@kibanosos.net, sender=fail2ban@kibanosos.net]
logpath  = /var/log/proftpd/proftpd.log
maxretry = 6

[postfix-iptables]

enabled = true
filter = postfix
action = iptables[name=Postfix, port=smtp, protocol=tcp]
sendmail-whois[name=Postfix, dest=user@yourdomain.com, sender=fail2ban@yourdomain.com]
logpath = /usr/local/psa/var/log/maillog
maxretry = 6
EOF
service fail2ban start

# HIDS (OSSEC)
mkdir /tmp/OSSEC && cd /tmp/OSSEC
echo -e "\e[32mInstalacion y configuracion de OSSEC"
# descarga
yum install -y zlib-devel gcc inotify-tools wget  1> /dev/null 2>> error.txt
wget -N https://github.com/ossec/ossec-hids/archive/3.3.0.tar.gz    1> /dev/null 2>> error.txt
tar xf 3.3.0.tar.gz -C /tmp/OSSEC   1> /dev/null 2>> error.txt
wget -N https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz  --no-check-certificate 1> /dev/null 2>> error.txt
tar zxf pcre2-10.32.tar.gz -C /tmp/OSSEC/ossec-hids-3.3.0/src/external/   1> /dev/null 2>> error.txt
cd /tmp/OSSEC/ossec-hids-3.3.0
# Instalacion
echo -e "\n\nlocal\n\nn\n\n\n\n\n\n\n" | ./install.sh   1> /dev/null 2>> error.txt
echo -e "\e[32mCambiando correo a admin@kibanosos.net en configuracion de ossec"
sed -i "s/<email_notification>no<\/email_notification>/<email_notification>admin@kibanosos.net<\/email_notification>/" /var/ossec/etc/ossec.conf
# Ejecutar servicio
/var/ossec/bin/ossec-control start   1> /dev/null 2>> error.txt

#### Sudo
echo -e "\e[32mInstalando sudo"
yum install -y sudo
grep "Politicas nuevas" /etc/sudoers
if [ $? -ne 0 ]; then
echo -e "\e[32mConfigurando politicas de sudo:"
cat << EOF >> /etc/sudoers
# Politicas nuevas
Defaults	log_host, log_year, logfile="/var/log/sudo.log"
Defaults	lecture="always" 
Defaults	badpass_message="La contraseña es incorrecta, esto sera reportado"
Defaults	passwd_tries=5 
Defaults    passwd_timeout=5
EOF
else
echo -e "\e[32mLas politicas ya fueron aplicadas"
fi

else 
echo -e "\e[31mNo es un sistema basado en RedHat"
fi

# Fuentes:
# https://www.tecmint.com/remove-unwanted-services-in-centos-7/
# https://www.2daygeek.com/linux-passwd-chpasswd-command-set-update-change-users-password-in-linux-using-shell-script/
# https://www.tecmint.com/change-a-users-default-shell-in-linux/
# https://www.cyberciti.biz/faq/linux-list-users-command/
# https://linuxconfig.org/how-to-disable-user-accounts-in-linux
# https://linoxide.com/tools/monitor-system-log-activity/
# https://scottlinux.com/2013/03/11/logwatch-how-to-for-centos-or-red-hat/
# https://kifarunix.com/enforce-password-complexity-policy-on-centos-7-rhel-derivatives/
# https://ahmermansoor.blogspot.com/2019/06/install-fail2ban-to-secure-centos-7-servers.html
# https://shaunfreeman.name/blog/install-fail2ban-on-centos-6-with-plesk
# https://ahmermansoor.blogspot.com/2019/06/install-fail2ban-to-secure-centos-7-servers.html
# https://www.digitalocean.com/community/tutorials/how-to-set-password-policy-on-a-centos-6-vps
# https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server
# https://www.tecmint.com/sudoers-configurations-for-setting-sudo-in-linux/
# https://francescoboffa.com/linux-server-hardening
