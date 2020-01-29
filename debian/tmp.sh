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

echo -e "Configurando permisos 700 con dueño root:root para los archivos /etc/passwd /etc/group /etc/shadow /etc/gshadow\n"
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

