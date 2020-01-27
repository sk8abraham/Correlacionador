# Alertas por Correo Elasticsearch

## 1.- Configuración de Cuenta de Correo

En este caso utilizamos una cuenta de correo de gmail para poder enviar las alertas por correo, dicha cuenta de correo debe tener habilitada la función de autenticación de dos factores para que se permita la creación de contraseñas de aplicaciones. Se deberá crear una nueva aplicación y obtener la contraseña de la misma.

Para nuestro caso creamos la aplicación llamada belk_project y automáticamente se genera una contraseña con el siguiente formato `aaaa bbbb cccc dddd`. Esta contraseña habra de ser utilizada posteriormente para poder permitir
el envio de correos.

## 2.- Configurando elasticsearch.yml

Una vez se tiene la App (Aplicación) y la App Password (Contraseña de Aplicación generada automáticamente) se tienen que añadir lineas de configuración a los archivos elasticsearch.yml de todos los nodos del cluster. La configuración para el nodo elasticsearch01 queda de la siguiente manera:

```apacheconf
cluster.name: elasticsearch-cluster
node.name: elasticsearch01
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.16.100.1
http.port: 9200
discovery.seed_hosts: ["172.16.100.1", "172.16.100.2", "172.16.100.5"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch01.p12 
xpack.security.transport.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch01.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/certs/elasticsearch01.p12
xpack.security.http.ssl.truststore.path: /etc/elasticsearch/certs/elasticsearch01.p12
xpack.notification.email.account:
    gmail_account:
        profile: gmail
        email_defaults:
            from: 'belk.project.unam.cert@gmail.com'
        smtp:
            auth: true
            starttls.enable: true
            host: smtp.gmail.com
            port: 587
            user: belk.project.unam.cert@gmail.com
```
## 3.- Ingresar App Password

En versiones de elasticsearch >= 7.0 se debe de proporcionar la contraseña haciendo uso de una utilería del propio elasticsearch para almacenar la contraseña de manera segura, para almacenar dicha contraseña de manera segura se ejecuta el siguiente comando:

```apacheconf
/usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.notification.email.account.gmail_account.smtp.secure_password
```

Una vez que se ejecuta se deberá de proporcionar la contraseña obtenida en el Paso 1 omitiendo los espacios en blanco, es decir, si se genero la contraseña `aaaa bbbb cccc dddd` lo que tenemos que tendriamos que ingresar es `aaaabbbbccccdddd`.

## 4.- Crear un Watcher que Envie Correos

```apacheconf
PUT _watcher/watch/pokemon_name
{
  "trigger" : {
    "schedule" : { "interval" : "1h" } 
  },
  "input" : {
    "search" : {
      "request" : {
        "indices" : [ "pokemones" ],
        "body" : {
          "query" : {
            "match" : { "message": "Arbok" }
          }
        }
      }
    }
  },
  "actions" : {
    "log_error" : {
      "logging" : {
        "text" : "Esto es un texto de prueba que se enviara a la bitacora del cluster"
      }
    },
    "send_email" : { 
    "email" : { 
      "to" : "johnny_sins@mail.com", 
      "subject" : "Watcher Notification", 
      "body" : "Probando Email" 
    }
  }
  }
}
```

Una vez que tenemos todo configurado resulta sencillo hacer un Watcher que envie correos en este caso la condicion del watcher siempre es verdadera por lo tanto siempre se estará enviando la alerta, ademas tambien se esta configurando que se envie información a los los esto resulta bastante útil cuando se desea realizar debugg.

# Debuggin

## Indexado de Datos por API

--------> ISO 8601 <--------

```apacheconf
python3 -c 'import time; print(time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime()) + ".613Z")'
```

```apacheconf
POST  /pokemones/event
{
  "timestamp" : "2020-01-26T21:15:56",
  "message" : "Ekans",
}
```
## Forzar Ejecución de un Watcher

```apacheconf
POST _watcher/watch/pokemon_name/_execute
```
## En los tres nodos de elastic colocar:

```apacheconf
tail -f /var/log/elasticsearch/elasticsearch-cluster.log
```
# Referencias

https://support.google.com/accounts/answer/185833?hl=en
https://discuss.elastic.co/t/failed-to-configure-email-alerts-with-gmail/180316
https://www.elastic.co/guide/en/elasticsearch/reference/7.5/how-watcher-works.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.5/watcher-getting-started.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.5/actions-email.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.5/actions-email.html#actions-email