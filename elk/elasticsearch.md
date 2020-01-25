# Instalación de Elasticsearch Cluster

## Linea Base para la Pila BELK

Para instalar un cluster de elasticsearch es necesario primero en todos los nodos ejecutar los comandos que se muestran a continuación, estos comandos añaden la llave PGP necesaria para confiar el los paquetes de elasticsearch, ademas se añade el repositorio oficial de elastic y una vez que se instala dicho repositorio se tiene que
actualizar la lista de paquetes disponibles para que los paquetes de la pila BELK se encuentren disponibles para poder instalarse.

```apacheconf
sudo apt install gnupg -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add 
sudo apt install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
```

## `Configuración Elasticsearch Cluster`

Para configurar un cluster de elasticsearch es necesario realizar cambios en varios archivos de configuración, a continuación se describe los cambios a realizar en cada uno de los archivos de configuración.


### `/etc/elasticsearch/elasticsearch.yml`

En este archivo basta con habilitar una directiva asignando el valor true que indicara que se reservara memoria RAM especial para el servicio de elasticsearch para asegurarse de que no se quede sin memoria.

```apacheconf
bootstrap.memory_lock: true
```
### `/etc/elasticsearch/jvm.options`

En este archivo se especifican los limites inferiores y superiores de memoria RAM que debe tener la maquina virtual de java para funcionar correctamente en este caso es suficiente con 1 GB de memoria RAM

```apacheconf
-Xms1g
-Xmx1g
```

### `/etc/fstab`

Es recomendable comentar la linea que tenga la palabra swap en este archivo ya que de esta manera se lograra desactivar el swap para que no se haga uso de almacenamiento secundario como memoria principal para no afectar el rendimiento de los servidores.

```apacheconf
#UUID=...swap...
```

## `Cluster Configuration`

Para configurar un cluster se debe definir un nombre de cluster, cada servidor debe tener su nombre de host único, además se debe especificar rutas para logs y datos, ip, puerto y una lista de todas las ips de los servidores que van a formar parte del cluster asi como una lista de todos los nombres de host de todos los nodos que son candidatos a ser master nodes.

### `/etc/elasticsearch/elasticsearch.yml`

#### Server: elasticsearch01

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch01
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.1
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
```

#### Server: elasticsearch02

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch02
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.2
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
```

## X-Pack

/usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack

*** En la versión actual de elasticsearch el modulo de x-pack viene instalado por defecto

/usr/share/elasticsearch/bin/elasticsearch-syskeygen

Storing generated key in [/etc/elasticsearch/system_key]...

Copiar dicha clave a todos los nodos de elastic, en este caso a la ruta /etc/elasticsearch/

```apacheconf
Please enter the desired output file [certificate-bundle.zip]: 
Enter instance name: elasticsearch01
Enter name for directories and files [elasticsearch01]: 
Enter IP Addresses for instance (comma-separated if more than one) []: 172.16.100.1
Enter DNS names for instance (comma-separated if more than one) []: elasticsearch01.becarios.local
Would you like to specify another instance? Press 'y' to continue entering instance information: y
Enter instance name: elasticsearch02
Enter name for directories and files [elasticsearch02]: 
Enter IP Addresses for instance (comma-separated if more than one) []: 172.16.100.2
Enter DNS names for instance (comma-separated if more than one) []: elasticsearch02.becarios.local
Would you like to specify another instance? Press 'y' to continue entering instance information: y
Enter instance name: elasticsearch03
Enter name for directories and files [elasticsearch03]: 
Enter IP Addresses for instance (comma-separated if more than one) []: 172.16.100.5
Enter DNS names for instance (comma-separated if more than one) []: elasticsearch03.becarios.local
Would you like to specify another instance? Press 'y' to continue entering instance information: n
Certificates written to /usr/share/elasticsearch/certificate-bundle.zip

This file should be properly secured as it contains the private keys for all
instances and the certificate authority.

After unzipping the file, there will be a directory for each instance containing
the certificate and private key. Copy the certificate, key, and CA certificate
to the configuration directory of the Elastic product that they will be used for
and follow the SSL configuration instructions in the product guide.

For client applications, you may only need to copy the CA certificate and
configure the client to trust this certificate.
```

Una vez que se generan las llaves de la ca y de cada uno de los servers de elasticsearch se debe colocar el certificado de la ca y la llave
y certificado de cada servidor en donde corresponde, para esto se creó una nueva carpeta en /etc/elasticsearch/certs y en cada uno de los 
servidores debemos tener una estructura como la siguiente: 

```apacheconf
/etc/elasticsearch/certs/
  ├── ca.crt
  ├── elasticsearch01.crt
  └── elasticsearch01.key
```

Ademas se deben añadir las lineas correspondientes a elasticsearch.yml para habilitar el modulo de seguridad, la autenticación en los servidores y 
las comunicaciones cifradas en todo el cluster, para esto necesitamos añadir estas lineas en el archivo elasticsearch.yml

https://www.elastic.co/guide/en/elasticsearch/reference/7.x/ssl-tls.html

```apacheconf
xpack.security.audit.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /etc/elasticsearch/certs/elasticsearch01.key
xpack.security.transport.ssl.certificate: /etc/elasticsearch/certs/elasticsearch01.crt
xpack.security.transport.ssl.certificate_authorities: [ "/etc/elasticsearch/certs/ca.crt" ]
```

### `Guia de Consultas para el Cluster`

curl -XGET "http://172.16.100.1:9200"    
curl -XGET "http://172.16.100.1:9200/_cluster/health?pretty"  
curl -X GET "http://172.16.100.1:9200/_nodes/process?pretty"  
curl -X GET "http://172.16.100.1:9200/_nodes/_all/process?pretty"  
curl -X GET "http://172.16.100.1:9200/_nodes/nodeId1,nodeId2/jvm,process?pretty"   
curl -X GET "http://172.16.100.1:9200/_nodes/nodeId1,nodeId2/info/jvm,process?pretty"  
curl -X GET "http://172.16.100.1:9200/_nodes/nodeId1,nodeId2/_all?pretty"  
curl -X PUT "http://172.16.100.1:9200/customer/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "John Doe"
}
'

# Reference

+ https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html
- https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html
* https://www.elastic.co/guide/index.html

* https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html




