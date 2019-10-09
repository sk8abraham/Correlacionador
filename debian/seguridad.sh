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
	a2enmod security2
	#systemctl restart apache2
	git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
	cp -r owasp-modsecurity-crs/rules /etc/modsecurity/
	cp -r owasp-modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf
	rm -rf owasp-modsecurity-crs
	cp -r archivos/security2.conf /etc/apache2/mods-enabled/security2.conf
	cat /etc/apache2/sites-enabled/000-default.conf | sed '/<\/VirtualHost>\/ i\SecRuleEngine On'
	systemctl restart apache2
	
fi

: '
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "#########   Instalando libpam  ##############\n"
apt install -y 
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "########   Instalando ProFTP    #################\n"
apt install -y proftpd
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "##########    Instalando SSH    #################\n"
apt install -y openssh-server
echo -e "#################################################\n\n"
'
