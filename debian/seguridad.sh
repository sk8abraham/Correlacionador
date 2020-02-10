#!/bin/bash
LOG='seguridad_log.txt'


SERVICIOS_INSTALADOS="fail2ban.* logcheck.* logwatch.* ssh.* apache.* postgresql.* open-vm-tools.*"
SERVICIOS_SISTEMA="console.* cron.* d-bus.* keyboard.* network.* r*sync.* r*sys.* syslog.* system.*"



echo "" > $LOG
escribe_log()
{
	$1
	if [[ $?  -ne 0 ]]; then
		echo "[`date +"%F %X"`]:$1     [ERROR]" | tee -a $LOG
		return 0
	else
		echo "[`date +"%F %X"`]:$1     [OK]" | tee -a $LOG
		return 1
	fi
}

echo "#### Instalacion de elementos de seguridad  ####" | tee -a $LOG
sleep 1
echo "###########   Instalando sudo   ###############" | tee -a $LOG
sleep 1 
cmd='apt install -y sudo'
escribe_log "$cmd"

echo "###########   Instalando mod-security   #########" | tee -a $LOG
sleep 1
cmd='apt install -y libapache2-mod-security2'
tmp=escribe_log $cmd

if [[ $tmp -eq 0 ]]; then
	echo "####### Configurando modsecurity ########" | tee -a $LOG
	sleep 1
	cmd="a2enmod security2"
	escribe_log "$cmd"
	cmd="git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git"
	escribe_log "$cmd"
	cmd="cp -r owasp-modsecurity-crs/rules /etc/modsecurity/"
	escribe_log "$cmd"
	cmd="cp -r owasp-modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf"
	escribe_log "$cmd"
	cmd="rm -rf owasp-modsecurity-crs"
	escribe_log "$cmd"
	cmd="cp -r archivos/security2.conf /etc/apache2/mods-enabled/security2.conf"
	escribe_log "$cmd"
	cat /etc/apache2/sites-enabled/000-default.conf | sed "/<\/VirtualHost>/ i\SecRuleEngine On" > tmp.txt
	cat tmp.txt > /etc/apache2/sites-enabled/000-default.conf
	cmd="rm -rf tmp.txt"
	escribe_log "$cmd"
	cmd='echo "Reiniciando apache"'
	cmd="systemctl restart apache2"
	escribe_log "$cmd"
fi
echo "#########   Instalando libpam  ##############" | tee -a $LOG
sleep 1
cmd='apt install -y libpam-pwquality cracklib-runtime'
escribe_log "$cmd"
cmd='cp archivos/common-password /etc/pam.d/common-password'
escribe_log "$cmd"

echo "########   Instalando OSSEC IDS    ##############" | tee -a $LOG
sleep 1
cmd='apt install -y inotify-tools gcc zlib1g-dev build-essential'
escribe_log "$cmd"
cmd='wget https://github.com/ossec/ossec-hids/archive/3.3.0.tar.gz'
escribe_log "$cmd"
cmd='tar xzf 3.3.0.tar.gz -C /tmp/'
escribe_log "$cmd"
cmd='wget https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz'
escribe_log "$cmd"
cmd='tar zxf pcre2-10.32.tar.gz -C /tmp/ossec-hids-3.3.0/src/external/'
escribe_log "$cmd"
cmd='cd /tmp/ossec-hids-3.3.0/'
escribe_log "$cmd"
echo -e "\n\nlocal\n\nn\n\n\n\n\n\n\n" | ./install.sh
cmd='/var/ossec/bin/ossec-control start'
escribe_log "$cmd"
cmd='cd -'
escribe_log "$cmd"
cmd='rm 3.3.0.tar.gz pcre2-10.32.tar.gz'
escribe_log "$cmd"

echo "##########    Instalando Fail2ban    ############" | tee -a $LOG
sleep 1
cmd='apt install -y fail2ban'
escribe_log "$cmd"
cmd='cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local'
escribe_log "$cmd"

echo "##########    Instalando Logwatch    ############" | tee -a $LOG
sleep 1
cmd='apt install -y logwatch'
escribe_log "$cmd"
cmd='/usr/sbin/logwatch --mailto root'
escribe_log "$cmd"

echo "##########    Instalando Logcheck    ############\n"
sleep 1
cmd='apt install -y logcheck'
escribe_log "$cmd"
cmd='su -s /bin/bash -c "/usr/sbin/logcheck -m logcheck" logcheck'
escribe_log "$cmd"

echo "#########    Usuarios y privilegios    ##########\n"
echo "Configurando permisos para los archivos de cron\n"
sleep 2
PATHS_CRON=("/var/spool/cron/crontabs" "/etc/anacrontab" "/etc/crontab" "/etc/cro.*")
for CRON_FILE in ${CRON_PATHS[@]}; do
	if [[ -e "$CRON_FILE" ]]; then
		cmd='chown root:root $CRON_FILE'
		escribe_log "$cmd"
		cmd='chmod go-rwx $CRON_FILE'
		escribe_log "$cmd"
	fi
done

echo "Configurando permisos 644 o 600 con dueño root:root para los archivos /etc/passwd /etc/group /etc/shadow /etc/gshadow" | tee -a $LOG
sleep 1
FILES=("/etc/passwd" "/etc/group" "/etc/shadow" "/etc/gshadow")
for FILE in ${FILES[@]}; do
	if [[ $FILE = "/etc/passwd" ]] || [[ $FILE="/etc/group" ]]; then
		UGO="644";
	else 
		UGO="600"; 
	fi
	cmd="chmod $UGO $FILE"
	escribe_log "$cmd"
	cmd="chown root:root $FILE"
	escribe_log "$cmd"
done
echo "Listo" | tee -a $LOG

echo "###   Deshabilitando servicios por defecto   ####" | tee -a $LOG
sleep 1
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
		cmd="systemctl disable $SERVICIO"
		escribe_log "$cmd"
		echo -e "---------------------"
	fi
done


#poc
