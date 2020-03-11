### Configuración de servidor losgtash.

Se puede utilizar el script llamado ```install-logstash.sh``` esta diseñado para trabajar con servidores basados en Debian.

```
#!/bin/bash

#
#  Instalador de logstash
#
if [ `id -u` -ne 0 ]; then
    echo "Deberias ejecutar el script como root"
else
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
# Variables:
myname=$HOSTNAME
myip=$(hostname -I)
# Modificacion de archivo host para localizar los nodos se deben cambiar las IPs de a corde a los servidores Elasticsearch.
cat > /etc/hosts << EOF
127.0.0.1 localhost
192.168.15.221 es-node-1
192.168.15.222 es-node-2
EOF
# Instalacion de dependencias necesarias
# java
echo "Instalando JAVA"
#add-apt-repository -y ppa:webupd8team/java
apt-get update && apt-get upgrade -y
apt-get -y install default-jdk
# ----
echo "Instalando Logstash"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get update && apt-get install logstash

echo  "Inciar y iniciar al arrancar"
systemctl enable logstash
systemctl start logstash

fi
```

Una vez instalado explicamos un poco de como trabaja lostash.

- __input__: En donde se toma sus datos, puede ser syslog, apache o NGINX. En nuestro caso puede ser de un servidor linux como Zimbra.
- __filter__: Una transformación que se aplicaría a los datos; a veces se desea trasformar sus datos, o para quitar algunos campos de la salida final.
- __output__: Donde va a enviar sus datos, la mayor parte a elasticsearch, pero puede ser modificado para enviar una amplia variedad de fuentes diferentes.

![input-output-filter-1024x545.png](https://devconnected.com/wp-content/uploads/2019/07/input-output-filter-1024x545.png)

Estos tres campos pueden ir separados por en un archivo diferente o todos en un solo archivo dependiendo a las necesidades, en nuestro caso los campos estan juntos en solo archivo, pero se creo un archivo para cada tipo de servicio cisco, fortigate, zimbra, etc. Todos estos archivos estan  bajo la carpeta ```/etc/logstash/conf.d/```

```
root@logstash:conf.d$ ll
total 32
-rw-r--r-- 1 root root  1917 Feb  4 06:38 10-cisco.filter.conf
-rw-r--r-- 1 root root  3563 Feb  4 07:53 10-forti-filter.conf
-rw-r--r-- 1 root root 24331 Feb  8 22:26 10-zimbra-filter.conf
```
A continuación podemos ver el filtro de cisco, donde podemos ver los tres campos mencionados anteriormente input, filter y output.

10-cisco.filter.conf:
```
input {
  udp {
    port => "5614"
    type => "syslog-cisco"
  }
  tcp {
    port => "5614"
    type => "syslog-cisco"
  }
}

filter {
  if [type] == "syslog-cisco" {
    fingerprint {
      source              => [ "message" ]
      method              => "SHA1"
      key                 => "hola123.,"
      concatenate_sources => true
    }
    grok {
      patterns_dir => [ "/etc/logstash/patterns" ]
      match => [
        # IOS
        "message", "^<%{POSINT:syslog_pri}>(%{NUMBER:log_sequence}): \*%{CISCOTIMESTAMPTZ:log_date}: \%%{CISCO_REASON:facility}-%{INT:severity_level}-%{CISCO_REASON:facility_mnemonic}: %{GREEDYDATA:message}"
      ]
      overwrite => [ "message" ]
      add_tag => [ "cisco" ]
      remove_field => [ "syslog5424_pri", "@version" ]
     }
   }
   if "cisco" in [tags] {
      date {
         match => ["log_date", "MMM  dd HH:mm:ss.SSS"]
        remove_field => [ "log_date" , "year", "month", "day", "time", "date"]
      }
        mutate {
          gsub => [
            "severity_level", "0", "0 - Emergency",
            "severity_level", "1", "1 - Alert",
            "severity_level", "2", "2 - Critical",
            "severity_level", "3", "3 - Error",
            "severity_level", "4", "4 - Warning",
            "severity_level", "5", "5 - Notification",
            "severity_level", "6", "6 - Informational"
          ]
        }
      }
}

output {
 if "cisco" in [tags] {
        elasticsearch {
            hosts => ["https://172.16.100.1:9200","https://172.16.100.2:9200","https://172.16.100.5:9200" ]
            ssl => true
            cacert => "/etc/logstash/ca.pem"
            user => "elastic"
            password => "elastic"
            index => "cisco-%{+YYYY.MM.dd}"
        }
        stdout {
            codec => rubydebug
        }
     }
}
```

Como de puede ver en la configuracion anterior en la parte de filter podemos ver en el campo grok, un apartado importante llamado ```patterns_dir => [ "/etc/logstash/patterns" ]``` o ```patterns_dir => [ "/etc/logstash/patterns.d" ]``` en el cual tenemos nuestros patrones para cada tipo de servicio, los patrones no son mas que expresiones regulares para poder parsear cada mensaje que llega de un servicio en especial y al los cuales les creamos etiquetas, este proceso lo podemos llamar __normalizar__, esto nos ayuda para poder manejar los datos a través de elasticsearch posteriormente.

Archivos con patrones:
```
root@logstash:logstash$ ll -h patterns*
patterns:
total 60K
-rw-r--r-- 1 root root 1.4K Jan 28 13:32 amavis
-rw-r--r-- 1 root root  419 Feb  4 06:09 cisco
-rw-r--r-- 1 root root 1.5K Jan 30 23:11 forti
-rw-r--r-- 1 root root 5.5K Jan 28 13:54 grok-patterns
-rw-r--r-- 1 root root  294 Jan 28 14:37 nginx
-rw-r--r-- 1 root root  847 Jan 27 19:50 nginx_access
-rw-r--r-- 1 root root  197 Jan 26 20:11 nginx_error
-rw-r--r-- 1 root root  213 Jan 28 14:37 opendkim
-rw-r--r-- 1 root root   66 Jan 28 19:02 postfix
-rw-r--r-- 1 root root  314 Jan 28 14:38 sasl
-rw-r--r-- 1 root root 3.8K Jan 28 14:39 smtp
-rw-r--r-- 1 root root  460 Jan 28 14:39 zbox
-rw-r--r-- 1 root root 3.3K Jan 29 22:43 zimbra
-rw-r--r-- 1 root root  309 Feb  8 18:40 zimbra_mailbox

patterns.d:
total 12K
-rw-r--r-- 1 root root 12K Jan 28 17:14 postfix.grok
```

Ejemplo de archivos de patrones ```cisco```:
```
NEXUSTIMESTAMP %{YEAR} %{MONTH} %{MONTHDAY} %{TIME}( %{TZ})?
ISETIMESTAMP %{YEAR}-%{MONTHNUM}-%{MONTHDAY}[T ]%{HOUR}:?%{MINUTE}(?::?%{SECOND})? %{ISO8601_TIMEZONE}?
CISCOTIMESTAMPTZ %{CISCOTIMESTAMP}( %{TZ})?
CISCOTIMESTAMP %{MONTH} +%{MONTHDAY}(?: %{YEAR})? %{TIME}
CISCO_REASON Duplicate TCP SYN|Failed to locate egress interface|Invalid transport field|No matching connection|DNS Response|DNS Query|(?:%{WORD}\s*)*
```

ZIMBRA FILTROS.
- [GitHub - nxhack/logstash: Configurations of my logstash: logstash, filebeat, grok patterns: sshd, postfix, apache, sysdig, zimbra mailbox.log, zimbra zimbra.log, Datadog Dogstatsd, fail2ban](https://github.com/nxhack/logstash)
- [How to Extract Patterns with the Logstash Grok Filter](https://qbox.io/blog/logstash-grok-filter-tutorial-patterns)
- [elastic.rumen-lishkov.com \| 522: Connection timed out](https://elastic.rumen-lishkov.com/filter-postfix-logstash/)

CISCO FILTROS.
- [GNS3 \| The software that empowers network professionals](https://www.gns3.com/news/article/monitoring-network-infratsructur)
- [Logstash: Processing Cisco Logs · GitHub](https://gist.github.com/justinjahn/85305bc7b7df9a6412baedce5f1a0ece)

FORTIGATE FILTROS.
- [Fortigate FortiOS 5.2 (and 5.2.2) Logstash Grok patterns · GitHub](https://gist.github.com/timbutler/ecab50967075b150d47b)