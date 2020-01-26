# Añadir un Nuevo Nodo de Elasticsearch

Para añadir un nuevo nodo se debe de instalar un nuevo servidor Debian y realizar las configuraciones necesarias para que se pueda instalar elasticsearch por paquetes. Una vez que se ha instalado elasticsearch ahora solo es tema de configuración, en este caso como ya se ha configurado el cluster para trabajar de manera cifrada tenemos que generar un certificado para el nuevo cluster.

## Generación de Certificado para el Nuevo Nodo

Para generar el certificado del nuevo nodo debemos utilizar la misma autoridad certificadora que nos firmó los certificados para los primeros nodos, en este caso basta con tener el archivo .p12 (pkcs12) de la ca y generar un nuevo certificado. Para llevar a cabo dicha tarea haremos uso de la herramienta `elasticsearch-certutil`.

Nos basta con ejecutar el siguiente comando:

```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca ca.p12 --name elasticsearch03 --dns elasticsearch03.becarios.local --ip 172.16.100.5
```

Ahora hay que crear la carpeta /etc/elasticsearch/certs/ y copiar nuestro certificado a dicha carpeta, ojo esta carpeta debe ser creada en el nuevo servidor.

Ahora solo resta configurar el nuevo servidor y realizar un cambio en los otros servidores del cluster y en en servidor kibana.

#### Elasticsearch03 - elasticsearch.yml

La configuración en el nuevo nodo queda de la siguiente manera:

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch03
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.5
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2", "172.16.100.5"]
#cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch03.p12 
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch03.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch03.p12
xpack.security.http.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch03.p12
```

#### Comentar linea en los otros nodos y añadir ip de nuevo nodo

La siguiente línea debera ser comentada en los arhivos de configuracion de todos los servidores del cluster ya que solo se utiliza en una instalación totalmente nueva de un cluster, en este caso como el cluster ya esta en funcionamiento y solo se esta añadiendo un nuevo nodo no hace falta. Ademas se debera indicar la ip del nuevo nodo para que los nodos puedan identificarse entre si en la red.

```apacheconf
#cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2", "172.16.100.5"]
```

#### Añadir el Nuevo Nodo a Kibana

En el archivo de configuracion de kibana (kibana.yml) tenemos que colocar la url de nuestro nuevo nodo.

```apacheconf
elasticsearch.hosts: ["https://172.16.100.1:9200", "https://172.16.100.2:9200", "https://172.16.100.5:9200"]
```

Una vez realizado todo lo anterior se deberan reiniciar todos los nodos del cluster así como el servidor kibana.

#### Problemas con Sincronizacion de los Nodos

Al momento de agregarse un nuevo nodo al cluster debemos asegurarnos que la version de elasticsearch de este sea la misma que la de los demas nodos ya que de no ser así se generaran problemas al momento de indexar la información, en este caso el nuevo nodo tenía elastic 7.5.2 y los otros nodos tenían elastic 7.5.1 por lo que se tuvieron que actualizar para que funcionran bien.