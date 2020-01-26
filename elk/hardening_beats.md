# Configurando Conexiones Cifradas a los Beats

Para lograr que la comunicación entre los distintos beats y el cluster de elasticsearch se realice de manera cifrada se debe de realizar configuración adicional, en concreto se deben realizar tres pasos. Paso uno crear un nuevo rol y usuario con los permisos necesarios para indexar informacion en el cluster. Paso dos proporcionar las credenciales de dicho usuario en el archivo de configuración para que el beat se pueda conectar. Paso tres transferir el certificado de la ca del cluster a el host en donde esta corriendo el beat y especificar la ruta a dicho certificado dentro del archivo de configuracion del beat. Al final de todo se debe de reiniciar el servicio.

## Metricbeat

Para metricbeat se creo el usuario metricbeat_writer que tiene asignado un rol del mismo nombre el cual cuenta con los privilegios de monitor y read_lim a nivel de cluster y create_doc, view_index_metadata y create_index a nivel de indice para el indice metricbeat-*.

La configuración de un cliente metricbeat generica queda de la siguiente manera:

```apacheconf
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
output.elasticsearch:
  hosts: ["https://172.16.100.1:9200", "https://172.16.100.2:9200", "https://172.16.100.5:9200"]
  username: "metricbeat_writer"
  password: "hola123.,"
  ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
```

Lo importante a resaltar de aquí es que los hosts se especifican como una url completa con el protocolo https, ademas se proporciona el usuario y contraseña con el que se autenticara con el cluster para poder indexar la información y por último se creo toda la ruta y se añadio el certificado de la ca del cluster para poder lograr que la comunicación fuera cifrada.

## Referencias

https://www.elastic.co/guide/en/beats/metricbeat/current/securing-beats.html
https://www.elastic.co/guide/en/beats/heartbeat/current/securing-beats.html