#!/bin/bash
echo -e "#################################################"
echo -e "#### Instalacion de elementos de seguridad  ####"
echo -e "#################################################\n\n"
sleep 1
echo -e "#################################################"
echo -e "###########   Instalando sudo   ###############\n"
sleep 1
apt install -y sudo
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "###########   Instalando mod-security   #########\n"
sleep 1
apt install -y libapache2-mod-security2

if [ $? -eq 0 ]; then
	echo -e "####### Configurando modsecurity ########'\n"
	sleep 1
	2enmod security2
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
sleep 1
apt install -y libpam-pwquality cracklib-runtime
cp archivos/common-password /etc/pam.d/common-password
echo -e "#################################################\n\n"


echo -e "#################################################"
echo -e "########   Instalando OSSEC IDS    ##############\n"
sleep 1
apt install -y inotify-tools gcc zlib1g-dev build-essential
wget https://github.com/ossec/ossec-hids/archive/3.3.0.tar.gz
tar xzf 3.3.0.tar.gz -C /tmp/
wget https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz
tar zxf pcre2-10.32.tar.gz -C /tmp/ossec-hids-3.3.0/src/external/
cd /tmp/ossec-hids-3.3.0/
echo -e "\n\nlocal\n\nn\n\n\n\n\n\n\n" | ./install.sh
/var/ossec/bin/ossec-control start
cd -
rm 3.3.0.tar.gz pcre2-10.32.tar.gz

echo -e "#################################################\n\n"


echo -e "#################################################"
echo -e "##########    Instalando Fail2ban    ############\n"
sleep 1
apt install -y fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "##########    Instalando Logwatch    ############\n"
sleep 1
apt install -y logwatch
/usr/sbin/logwatch --mailto root
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "##########    Instalando Logcheck    ############\n"
sleep 1
apt install -y logcheck
su -s /bin/bash -c "/usr/sbin/logcheck -m logcheck" logcheck
echo -e "#################################################\n\n"

echo -e "#################################################"
echo -e "#########    Usuarios y privilegios    ##########\n"
echo -e "Configurando permisos para los archivos de cron\n"
sleep 2
PATHS_CRON=("/var/spool/cron/crontabs" "/etc/anacrontab" "/etc/crontab" "/etc/cro.*")
for CRON_FILE in ${CRON_PATHS[@]}; do
	if [[ -e "$CRON_FILE" ]]; then
		chown root:root $CRON_FILE
		chmod go-rwx $CRON_FILE
	fi
done

echo -e "Configurando permisos 644 o 600 con dueño root:root para los archivos /etc/passwd /etc/group /etc/shadow /etc/gshadow\n"
sleep 1
FILES=("/etc/passwd" "/etc/group" "/etc/shadow" "/etc/gshadow")
for FILE in ${FILES[@]}; do
	if [[ $FILE = "/etc/passwd" ]] || [[ $FILE="/etc/group" ]]; then
		UGO="644";
	else 
		UGO="600"; 
	fi
	chmod $UGO $FILE
	chown root:root $FILE
done

echo -e "#################################################"
echo -e "###   Deshabilitando servicios por defecto   ####\n"
sleep 1
SERVICIOS_INSTALADOS="fail2ban.* logcheck.* logwatch.* ssh.* apache.* postgresql.* open-vm-tools.*"
SERVICIOS_SISTEMA="console.* cron.* d-bus.* keyboard.* network.* r*sync.* r*sys.* syslog.* system.*"
TODOS="${SERVICIOS_SISTEMA} ${SERVICIOS_INSTALADOS}"
SERVICIOS_POR_DEFECTO=$(systemctl list-unit-files --state=enabled --type=service | grep enabled | cut -f1 -d" " | tr '\n' ' ')
for SERVICIO in $SERVICIOS_POR_DEFECTO; do
	FLG=1
	for NO_DESHABILITAR in $TODOS; do
		if [[ "$SERVICIO" =~ $NO_DESHABILITAR ]]; then
			FLG=0
			break
		fi
		done
	if [[ $FLG -eq 1 ]]; then
		systemctl disable $SERVICIO
		echo -e "---------------------"
	fi
done
echo -e "#################################################\n\n"

