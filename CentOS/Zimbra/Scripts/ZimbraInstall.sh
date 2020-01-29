#!/bin/bash
## Ejecutar como root
if [ $# -ge 3 ] ; then
if [ `id -u` -ne 0 ]; then
    echo "Deberiar ejecutar el script como root"
else
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)
HOSTNAME=$(hostname -s)
REVERSEIP=$(echo $2 | awk -F. '{print $3"."$2"."$1}')

 #Desabilitamos y detenemos postfix:
systemctl disable postfix
systemctl stop postfix
 #Instalacion de DNS Server
if [ "$4" == "bind" ]; then
    yum update -y && yum install -y bind bind-utils
    echo "Instalando Bind DNS Server"
    mv /etc/named.conf /etc/named.conf.original

cat <<EOF >>/etc/named.conf
options {
    listen-on port 53 { 127.0.0.1; $2; };
    listen-on-v6 port 53 { ::1; };
    directory 	"/var/named";
    dump-file 	"/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    recursing-file  "/var/named/data/named.recursing";
    secroots-file   "/var/named/data/named.secroots";
    allow-query     { any; };

    recursion yes;
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    dnssec-enable yes;
    dnssec-validation yes;

    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.root.key";

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
    };

    logging {
        channel default_debug {
        file "data/named.run";
        severity dynamic;
        };
    };

    zone "$1" IN {
        type master;
        file "$1.zone";
        allow-update { none; };	
    };

    zone "$REVERSEIP.in-addr.arpa" IN {
        type master;
        file "$1.rev";
        allow-update { none; };
    };

    zone "." IN {
        type hint;
        file "named.ca";
    };

    include "/etc/named.rfc1912.zones";
    include "/etc/named.root.key";
EOF
touch /var/named/$1.zone
SERIAL=$(date +%Y%m%d2)
cat <<EOF >/var/named/$1.zone
\$TTL 3H
@	IN SOA	$1 $HOSTNAME.$1. (
                1	; serial
                1D	; refresh
                1H	; retry
                1W	; expire
                3H )	; minimum
@	IN	NS	$1.
@	IN	A	$2
@	IN	MX 5	$HOSTNAME.$1.
$HOSTNAME	IN	    A	   $2
ns1     IN      A      $2
pop3    IN      A      $2
imap    IN      A      $2
imap4   IN      A      $2
smtp    IN      A      $2
EOF
touch /var/named/$1.rev
SERIAL=$(date +%Y%m%d2)
cat <<EOF >/var/named/$1.rev
\$TTL 1D
@	IN SOA	$1. $HOSTNAME.$1. (
                1	; serial
                1D	; refresh
                1H	; retry
                1W	; expire
                3H )	; minimum
@	IN	NS	$1.
@	IN	A	$2
32	IN	PTR	$HOSTNAME.$1.
EOF
chown root:named /var/named/$1.*
systemctl enable named && systemctl start named
cat <<EOF >/etc/resolv.conf 
nameserver 127.0.0.1
nameserver 8.8.8.8
EOF
fi
#Preparación de archivos de configuración para injectar al script de instalación de Zimbra
echo "Creando scripts"
mkdir /tmp/zcs && cd /tmp/zcs
touch /tmp/zcs/installZimbraScript
cat <<EOF >/tmp/zcs/installZimbraScript
AVDOMAIN="$1"
AVUSER="admin@$1"
CREATEADMIN="admin@$1"
CREATEADMINPASS="$3"
CREATEDOMAIN="$1"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$HOSTNAME.$1"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="$3"
LDAPPOSTPASS="$3"
LDAPROOTPASS="$3"
LDAPADMINPASS="$3"
LDAPREPPASS="$3"
LDAPBESSEARCHSET="set"
LDAPDEFAULTSLOADED="1"
LDAPHOST="$HOSTNAME.$1"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$1"
SMTPHOST="$HOSTNAME.$1"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$1"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$HOSTNAME.$1"
SPELLURL="http://$HOSTNAME.$1:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$1"
TRAINSASPAM="spam.$RANDOMSPAM@$1"
UIWEBAPPS="yes"
UPGRADE="yes"
USEKBSHORTCUTS="TRUE"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$1"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$3"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$3"
ldap_url="ldap://$HOSTNAME.$1:389"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$3"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/etc/java/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP=""
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraDefaultDomainName="$1"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $2/32 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="America/Los_Angeles"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@$1"
zimbraVersionCheckNotificationEmailFrom="admin@$1"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="$HOSTNAME.$1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF
touch /tmp/zcs/installZimbra-keystrokes
cat <<EOF >/tmp/zcs/installZimbra-keystrokes
y
y
y
y
y
y
y
y
y
y
y
y
y
y
y
y
EOF

if [[ `rpm -qa '(oraclelinux|sl|redhat|centos)-release(|-server)'|cut -d"." -f4` == "el7" ]]; then
    echo "Descargando Zimbra Collaboration 8.8.15 para CentOS/RedHat 7"
    curl -O -L https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.RHEL7_64.20190918004220.tgz
    tar xzvf zcs-*
    # Creando carpetas necesarias
    #mkdir -p /opt/zimbra/common/lib/jvm/java/jre/lib/security/
    echo "Instalando Zimbra Collaboration"
    cd /tmp/zcs/zcs-* && ./install.sh -s < /tmp/zcs/installZimbra-keystrokes
    #ln -s /opt/zimbra/common/etc/java/cacerts /opt/zimbra/common/lib/jvm/java/jre/lib/security
    echo "Instalando Zimbra Collaboration junto con los archivos de configuracion"
    /opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs/installZimbraScript
    # Habilitar ldap y ldaps
    su - zimbra -c 'zmlocalconfig -e ldap_bind_url="ldap://mail.kibanosos.net:389 ldaps://mail.kibanosos.net:636"'
    su - zimbra -c 'ldap stop'
    su - zimbra -c 'ldap start'
    echo "Reiniciando servicios"
    su - zimbra -c 'zmcontrol restart'
    
    ## Agregar reglas al firewall de Centos
    echo "Agregando reglas para Firewalld"
    firewall-cmd --permanent --add-port={25,80,110,143,443,465,587,993,995,5222,5223,9071,7071}/tcp
    firewall-cmd --zone=public --add-port=53/tcp --permanent
    firewall-cmd --zone=public --add-port=53/udp --permanent
    firewall-cmd --reload
    clear
    echo "Tu puedes acceder a Zimbra Collaboration Server"
    echo "Consola de administracion: https://"$2":7071"
    echo "Accesos para usuarios: https://"$2
fi
else
echo "Usa: ZimbraInstall.sh <dominio> <MailServerIP> <password> <bind>"
echo "Ejemplo: ZimbraInstall.sh kibanosos.net 192.168.1.10 hola123., bind"
fi
fi

##### Fuestes #####
# https://www.linuxtechi.com/install-opensource-zimbra-mailserver-centos-7/
# https://www.youtube.com/watch?v=67tbQnI-Ix4
# https://blog.zimbra.com/2007/06/making-zimbra-bind-work-together/
# https://www.zimbra.org/download/zimbra-collaboration
# https://www.itsupportwale.com/blog/how-to-install-open-source-zimbra-8-8-mail-server-zcs-8-8-12-on-ubuntu-16-04-lts/
# https://www.serverkaka.com/2019/05/install-and-configure-zimbra-mail-server-ubuntu-debian.html
# https://www.linuxtechi.com/install-opensource-zimbra-mailserver-centos-7/
