# Instalación de Logstash

## Linea Base para la Pila BELK

Para instalar un cluster de elasticsearch es necesario primero en todos los nodos ejecutar los comandos que se muestran a continuación, estos comandos añaden la llave PGP necesaria para confiar el los paquetes de elasticsearch, ademas se añade el repositorio oficial de elastic y una vez que se instala dicho repositorio se tiene que
actualizar la lista de paquetes disponibles para que los paquetes de la pila BELK se encuentren disponibles para poder instalarse.

```apacheconf
sudo apt install gnupg -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add 
sudo apt install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update

```

Antes de realizar la instalación de logstash por paquetes es necesario tener instalado java en el servidor para que funcione correctamente y se pueda llevar a cabo el preprocesado de la información antes de indexarla en el cluster de elasticsearch.

## Instalación de JAVA

Para instalar java simplemente lo instalamos por paquete de la siguiente manera:
```apacheconf
sudo apt install openjdk-11-jre
```
## /etc/environment

Para que el servicio funcione de manera correcta se tiene que definir una variable de entorno que donde se encuentra instalado java para esto es necesario escribir la siguiente linea en el archivo `/etc/enviroment`

```apacheconf
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
```
Una vez definida la variable de entorno en el archivo se necesita recargar el archivo para que se ejecuten los cambios. Una vez definida la variable de entorno se puede proceder a instalar logstash y configuralo para que se ejecute en el arranque del equipo.

```apacheconf
source /etc/environment
sudo apt install logstash
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
```

## Prueba Logstash

Para probar que logstash este funcionando se puede ejecutar el siguiente comando que simplemente redirige todo lo que se escribe en la entrada estandar hacia la salida estandar.

```apacheconf
/usr/share/logstash/bin/logstash -e 'input { stdin {} } output { stdout {} }
```