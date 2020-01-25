# Instalación de Kibana

## Linea Base para la Pila BELK

Para instalar un cluster de elasticsearch es necesario primero en todos los nodos ejecutar los comandos que se muestran a continuación, estos comandos añaden la llave PGP necesaria para confiar el los paquetes de elasticsearch, ademas se añade el repositorio oficial de elastic y una vez que se instala dicho repositorio se tiene que
actualizar la lista de paquetes disponibles para que los paquetes de la pila BELK se encuentren disponibles para poder instalarse.

```apacheconf
sudo apt install gnupg -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add 
sudo apt install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install kibana
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
```

Configurar el servidor kibana resulta ser bastante sencillo solo basta con especificar la ip que va a tener el servidor, el nombre de host, las urls de los servidores de elasticsearch con los cuales se va a estar comunicando y el índice de kibana.

```apacheconf
server.host: "172.16.100.3"
server.name: "kibana01"
elasticsearch.hosts: ["http://172.16.100.1:9200", "http://172.16.100.2:9200"]
kibana.index: ".kibana"
```

## Configuración X-Pack

/usr/share/logstash/bin/kibana-plugin install x-pack