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




