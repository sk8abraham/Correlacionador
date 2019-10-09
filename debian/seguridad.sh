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
	echo -e "####### Configurando modsecurity ########"
	a2enmod security2
	sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
	


	
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
