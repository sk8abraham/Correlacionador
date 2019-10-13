#!/bin/bash
echo -e "#################################################"
echo -e "#### Instalacion de elementos de seguridad  ####"
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "###########   Instalando sudo   ###############\n"
apt install -y sudo
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "###########   Instalando mod-security   #########\n"
apt install -y libapache2-mod-security2

if [ $? -eq 0 ]; then
	echo -e "####### Configurando modsecurity ########'\n"
	sudo 2enmod security2
	#systemctl restart apache2
	git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
	cp -r owasp-modsecurity-crs/rules /etc/modsecurity/
	cp -r owasp-modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf
	rm -rf owasp-modsecurity-crs
	cp -r archivos/security2.conf /etc/apache2/mods-enabled/security2.conf
	cat /etc/apache2/sites-enabled/000-default.conf | sed '/<\/VirtualHost>/ i\SecRuleEngine On' > tmp.txt
	cat tmp.txt > /etc/apache2/sites-enabled/000-default.conf
	rm -rf tmp.txt
	echo "Reiniciando apache"
	systemctl restart apache2
fi
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "#########   Instalando libpam  ##############\n"
apt install -y libpam-pwquality cracklib-runtime
cp archivos/common-password /etc/pam.d/common-password
echo -e "#################################################\n\n"


echo -e "#################################################"
echo -e "########   Instalando OSSEC IDS    ##############\n"
apt install -y inotify-tools gcc zlib1g-dev build-essential
wget https://github.com/ossec/ossec-hids/archive/3.3.0.tar.gz
tar xzf 3.3.0.tar.gz -C /tmp/
wget https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz
tar zxf pcre2-10.32.tar.gz -C /tmp/ossec-hids-3.3.0/src/external/
cd /tmp/ossec-hids-3.3.0/
echo -e "\n\nlocal\n\nn\n\n\n\n\n\n\n" | ./install.sh
sudo /var/ossec/bin/ossec-control start
cd -
sudo rm 3.3.0.tar.gz pcre2-10.32.tar.gz

echo -e "#################################################\n\n"


echo -e "#################################################"
echo -e "##########    Instalando Fail2ban    ############\n"
apt install -y fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "##########    Instalando Logwatch    ############\n"
apt install -y logwatch
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "##########    Instalando Logcheck    ############\n"
apt install -y logcheck
echo -e "#################################################\n\n"
