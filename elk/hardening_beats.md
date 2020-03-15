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

## Winlogbeat

```apacheconf
winlogbeat.event_logs:
  - name: Application
    ignore_older: 72h
  - name: System
  - name: Security
    processors:
      - drop_event.when.not.or:
        - equals.winlog.event_id: 1000
        - equals.winlog.event_id: 1001
        - equals.winlog.event_id: 1002
        - equals.winlog.event_id: 1005
        - equals.winlog.event_id: 1006
        - equals.winlog.event_id: 1007
        - equals.winlog.event_id: 1008
        - equals.winlog.event_id: 1009
        - equals.winlog.event_id: 1015
        - equals.winlog.event_id: 1116
        - equals.winlog.event_id: 1117
        - equals.winlog.event_id: 1118
        - equals.winlog.event_id: 1119
        - equals.winlog.event_id: 1100
        - equals.winlog.event_id: 1102
        - equals.winlog.event_id: 1104
        - equals.winlog.event_id: 2001
        - equals.winlog.event_id: 2005
        - equals.winlog.event_id: 2007
        - equals.winlog.event_id: 3002
        - equals.winlog.event_id: 3007
        - equals.winlog.event_id: 4616
        - equals.winlog.event_id: 4649
        - equals.winlog.event_id: 4672
        - equals.winlog.event_id: 4670
        - equals.winlog.event_id: 4674
        - equals.winlog.event_id: 4697
        - equals.winlog.event_id: 4698
        - equals.winlog.event_id: 4699
        - equals.winlog.event_id: 4700
        - equals.winlog.event_id: 4701
        - equals.winlog.event_id: 4702
        - equals.winlog.event_id: 4964
        - equals.winlog.event_id: 4720
        - equals.winlog.event_id: 4722
        - equals.winlog.event_id: 4723
        - equals.winlog.event_id: 4724
        - equals.winlog.event_id: 4726
        - equals.winlog.event_id: 4728
        - equals.winlog.event_id: 4729
        - equals.winlog.event_id: 4731
        - equals.winlog.event_id: 4732
        - equals.winlog.event_id: 4735
        - equals.winlog.event_id: 4738
        - equals.winlog.event_id: 4741
        - equals.winlog.event_id: 4742
        - equals.winlog.event_id: 4749
        - equals.winlog.event_id: 4756
        - equals.winlog.event_id: 4759
        - equals.winlog.event_id: 4767
        - equals.winlog.event_id: 4781
        - equals.winlog.event_id: 4794
        - equals.winlog.event_id: 4825
        - equals.winlog.event_id: 4886
        - equals.winlog.event_id: 4887
        - equals.winlog.event_id: 4888
        - equals.winlog.event_id: 5000
        - equals.winlog.event_id: 5001
        - equals.winlog.event_id: 5004
        - equals.winlog.event_id: 5008
        - equals.winlog.event_id: 5010
        - equals.winlog.event_id: 5012
        - equals.winlog.event_id: 5024
        - equals.winlog.event_id: 5025
        - equals.winlog.event_id: 5030
        - equals.winlog.event_id: 5442
        - equals.winlog.event_id: 5149
        - equals.winlog.event_id: 5416
        - equals.winlog.event_id: 4624
        - equals.winlog.event_id: 4634
  - name: Microsoft-Windows-Sysmon/Operational
  - name: Microsoft-Windows-Windows Firewall With Advanced Security/Firewall
  - name: Microsoft-Windows-Windows Firewall With Advanced Security/FirewallDiagnostics
setup.template.settings:
  index.number_of_shards: 1
output.elasticsearch:
  hosts: ["https://172.16.100.1:9200", "https://172.16.100.2:9200", "https://172.16.100.5:9200"]
  username: "winlogbeat_writer"
  password: "hola123.,"
  ssl.certificate_authorities: ["C:\\Program Files\\Winlogbeat\\certs\\ca.pem"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
```

## Filebeat
Configuración general de filebeat instalado por paquetes:  

```apacheconf
filebeat.inputs:
- type: log
  enabled: false
  paths:
    - /var/log/proftpd/proftpd.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "172.16.100.3:5601"
output.elasticsearch:
  hosts: ["https://172.16.100.1:9200","https://172.16.100.2:9200","https://172.16.100.5:9200"]
  username: "filebeat_writer"
  password: "filebeat_writer"
  ssl.certificate_authorities: ["/etc/ssl/certs/ca.pem"]
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat2
  keepfiles: 3
  permissions: 0644
```
## Referencias

https://www.elastic.co/guide/en/beats/metricbeat/current/securing-beats.html
https://www.elastic.co/guide/en/beats/heartbeat/current/securing-beats.html
https://www.elastic.co/guide/en/beats/winlogbeat/current/securing-beats.html
https://www.elastic.co/guide/en/beats/filebeat/current/securing-beats.html
