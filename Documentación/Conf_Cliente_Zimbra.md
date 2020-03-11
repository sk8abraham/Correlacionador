### Configuración de servidor zimbra.

#### - Configuración de zimbra.

Se utiliza el script llamado ZimbraInstall.sh para poder tener un servidor de correo y con DNS si se desea.

Modo de uso:
```
ZimbraInstall.sh <dominio> <MailServerIP> <password> <bind>
ZimbraInstall.sh kibanosos.net 192.168.1.10 hola123., bind
```
#### Instalación de filebeat

Se puede utilizar el script llamado ```Install-beat.sh``` el cual esta diseñado para ser utilizado en ditribuciones basadas en Debian o RedHat. Al igual esta actualizado con los repositorios para trabajar con las ultimas versiones de ELK.

```
#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    # ------- #
    # DEBIAN  #
    # ------- #
    if [[ $OS == "Debian GNU/Linux" ]]; then
        echo "DEBIAN OS"
        echo "Instalando Beats"
        apt-get install wget apt-transport-https software-properties-common dirmngr lsb-release ca-certificates -y
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
        add-apt-repository "deb https://artifacts.elastic.co/packages/7.x/apt stable main"
        apt-get update
        # Instalacion
        apt-get install filebeat -y
        echo "Iniciando servicio:"
        # Iniciar servicio
        systemctl start filebeat
        # Arranque
        #systemctl enable filebeat
    # ------- #
    # CentOS  #
    # ------- #
    elif [[ $OS == "CentOS Linux" ]]; then
        echo "CentOS"
        # Download and install the public signing key:
        sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
        # Create a file with a .repo extension (for example, elastic.repo) in your /etc/yum.repos.d/ directory and add the following lines:
echo "
[elastic-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/elastic.repo
        # Instalacion
        yum install filebeat -y
        # Iniciar servicio
        systemctl start filebeat
        # Arranque
        systemctl enable filebeat
    fi
else 
OS=$(uname -s)
VER=$(uname -r)
# ------- #
#  OTROS  #
# ------- #
fi
```

#### Configuracion de filebeat

Utilizamos el archivo llamado ```filebeat.yml``` ubicado en la ruta ```/etc/filebeat/```.

Archivo de configuración:
```
filebeat.inputs:
- type: log
  enabled: true
  paths:
   - /var/log/zimbra.log
  fields: {log_type: zimbralog}

- type: log
  enabled: true
  paths:
   - /opt/zimbra/log/mailbox.log*
  fields: {log_type: mailbox}

- type: log
  enabled: true
  paths:
   - /var/log/maillog*
  fields: {log_type: postfix}

- type: log
  enabled: true
  paths:
   - /var/ossec/logs/alerts/alerts.json
  json.keys_under_root: true
  fields: {log_type: osseclogs}

filebeat.config.modules:
 path: ${path.config}/modules.d/*.yml
 reload.enabled: false

output.logstash:
  hosts: ["172.16.200.220:5044"]
```

Es importante dividir cada archivo de log y etiquetarlo con una categoria como lo podemos ver en ```fields: {log_type: postfix}``` ya que esto nos ayudara a filtrar cada uno de los archivos cuando estos lleguen a nuestro servidor losgtash.

Si se desea trabajar con modulos de filtos ya creados o predeterminados se tiene que instalar otra instancia separada, ya que a través de una sola instancia no se puede configurar la salida tanto a logstash como para elasticsearch (ocupado por los modulos predeterminados).



#### POSTFILX
[GitHub - whyscream/postfix-grok-patterns: Logstash configuration and grok patterns for parsing postfix logging](https://github.com/whyscream/postfix-grok-patterns)
