# Archivo de configuración de filebeat
Debido a que se necesitaba que filebeat enviará logs por logstash, se debían tener dos instancias de filebeat. uno que enviara a elastic y otro a logstash. Para ello uno se instaló por paquetes y otro se compiló.  
En el archivo "hardening_beats.md" se muestra la configuración para enviar a elastic en una instalación por paquetes, este archivo es para el envio de logs a logstash y en este caso, la configuración de OSSEC para generar logs que se puedan normalizar más facilmente:  

Primero se debe habilitar salidas de alerta json en ossec.conf:  
```apacheconf
<global>
  <jsonout_output>yes</jsonout_output>
</global>
```
Configuración de filebeat para leer alertas del archivo alerts.json
```apacheconf
filebeat.inputs:
- type: log
  enabled: true
  paths:
##########################################
    - /var/ossec/logs/alerts/alerts.json
  json.keys_under_root: true
  fields: {log_type: osseclogs}
##########################################
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
output.logstash:
  hosts: ["172.16.100.4:5044"]
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
Configuración en logstash:  
```apacheconf
input {
  beats {
    id => "beats_test"
    port => 9001
    type => "ossec"
  }
}

filter {
  if([fields][log_type] == "osseclogs") {
    mutate {
      replace => {
        "[type]" => "osseclogs"
      }
    }
  }
}

output {
  elasticsearch { 
	    hosts => ["https://172.16.100.1:9200","https://172.16.100.2:9200","https://172.16.100.5:9200"]
            ssl => true
            cacert => "/etc/logstash/ca.pem"
            user => "elastic"
            password => "elastic"
            index => "ossec-%{+YYYY.MM.dd}"
  }
```
## Referencias:  
https://www.ossec.net/docs/cookbooks/recipes/elasticstack.html
