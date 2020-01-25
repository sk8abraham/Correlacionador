# Configuración X-Pack

X-Pack es ...

Lo primero que tenemos que hacer es definir las contraseñas para los usuarios con los que vamos a estar trabajando para esto basta con ejecutar el siguiente comando:

/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto # Si queremos que se asignen contraseñas automáticamente
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive # Si queremos que se nos pregunte que contraseñas queremos definir

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

## Referencias

https://www.elastic.co/guide/en/x-pack/6.2/ssl-tls.html


https://www.elastic.co/guide/en/elasticsearch/reference/6.8/get-started-enable-security.html
https://www.elastic.co/guide/en/x-pack/current/setting-up-authentication.html#set-built-in-user-passwords