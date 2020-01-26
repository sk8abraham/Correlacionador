# Configurar X-Pack

Lo primero que tenemos que hacer es definir las contraseñas para los usuarios con los que vamos a estar trabajando para esto basta con ejecutar el siguiente comando:

#### Si queremos que se asignen contraseñas automáticamente
```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
```
#### Si queremos que se nos pregunte que contraseñas queremos definir
```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
```

Salida del modo `interactive`:

```apacheconf
Initiating the setup of passwords for reserved users elastic,apm_system,kibana,logstash_system,beats_system,remote_monitoring_user.
You will be prompted to enter passwords as the process progresses.
Please confirm that you would like to continue [y/N]y

Enter password for [elastic]: 
Reenter password for [elastic]: 
Enter password for [apm_system]: 
Reenter password for [apm_system]: 
Enter password for [kibana]: 
Reenter password for [kibana]: 
Enter password for [logstash_system]: 
Reenter password for [logstash_system]: 
Enter password for [beats_system]: 
Reenter password for [beats_system]: 
Enter password for [remote_monitoring_user]: 
Reenter password for [remote_monitoring_user]: 
Changed password for user [apm_system]
Changed password for user [kibana]
Changed password for user [logstash_system]
Changed password for user [beats_system]
Changed password for user [remote_monitoring_user]
Changed password for user [elastic]
```
## Configurar Autenticación Basic en Elasticsearch Cluster y Kibana -----------

#### Elasticsearch 01

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch01
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.1
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
xpack.security.enabled: true
```

#### Elasticsearch 02

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch02
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.2
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
xpack.security.enabled: true
```

#### Kibana 01

```apacheconf
server.host: "172.16.100.3"
server.name: "kibana01"
elasticsearch.hosts: ["http://172.16.100.1:9200", "http://172.16.100.2:9200"]
kibana.index: ".kibana"
elasticsearch.username: "kibana"
elasticsearch.password: "kibana"
```

***NOTA: Asegurarse de reiniciar los servicios una vez efectuados los cambios

## ----------------------------------------------------------------------------

## Configurar Cifrado de Nodo a Nodo en el Cluster de Elasticsearch + HTTPS + Comunicación Cifrada Elastic-Kibana + HTTPS Frontend

### 1.- Generacion de Llaves

Este comando generara un zip en donde se encontraran las llaves formato pkcs12 de la ca y los nodos de elasticsearch.

```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --in instances.yml --keep-ca-key
```

La estructura del archivo instances.yml que se esta utilizando se muestra a continuación:

#### instances.yml

```apacheconf
instances:
  - name: "elasticsearch01"
    ip:
      - "172.16.100.1"
    dns:
      - "elasticsearch01.becarios.local"
  - name: "elasticsearch02"
    ip:
      - "172.16.100.2"
    dns:
      - "elasticsearch02.becarios.local"
```

***NOTA: Se genera un .zip con todas las llaves en /usr/share/elasticsearch/

Con las llaves de la ca en formato pkcs12 se debe obtener una llave en formato .pem que se va a utilizar posteriormente en la configuracion de kibana y logstash. Para formar la llave .pem a partir de la llave .p12 se ejecuta el siguiente comando:

```apacheconfig
openssl pkcs12 -in ca.p12 -clcerts -nokeys -chain -out ca.pem
```

## Generar Llaves para el Frontend de Kibana

```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca ca.p12 --pem --name kibana01 --dns kibana01.becarios.local --ip 172.16.100.3
```

***NOTA: Por razones geopoliticas que no entendemos el archivo ca.p12 (Llaves Pública y Privada de la ca) se debe encontrar en la ruta /usr/share/elasticsearch/

Una vez que se tienen las llaves se tienen que colocar en cada uno de los servidores y se tienen que actualizar los archivos de configuración de elasticsearch.yml y kibana.yml. Los archivos quedan de la siguiente manera:

#### Elasticsearch 01

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch01
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.1
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch01.p12 
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch01.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch01.p12
xpack.security.http.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch01.p12
```

#### Elasticsearch 02

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch02
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.2
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2"]
cluster.initial_master_nodes: ["elasticsearch01", "elasticsearch02"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch02.p12
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch02.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch02.p12
xpack.security.http.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch02.p12
```

#### Kibana 01

```apacheconf
server.host: "172.16.100.3"
server.name: "kibana01"
elasticsearch.hosts: ["https://172.16.100.1:9200", "https://172.16.100.2:9200"]
kibana.index: ".kibana"
elasticsearch.username: "kibana"
elasticsearch.password: "kibana"
server.ssl.enabled: true
server.ssl.certificate: /etc/kibana/certs/kibana01.crt
server.ssl.key: /etc/kibana/certs/kibana01.key
elasticsearch.ssl.certificateAuthorities: [ "/etc/kibana/certs/ca.pem" ]
```

***NOTA: Asegurarse de reiniciar los servicios una vez efectuados los cambios

## Referencias

https://www.elastic.co/guide/en/x-pack/6.2/ssl-tls.html

https://www.elastic.co/guide/en/kibana/7.5/security-settings-kb.html

https://www.elastic.co/guide/en/elasticsearch/reference/7.x/certutil.html

https://arnaudloos.com/2019/enable-x-pack-security/