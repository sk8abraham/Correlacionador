# Instalación de Cerebro [Elasticsearch Web Admin Tool]

Para poder utilizar cerebro lo primero que tenemos que hacer es asegurarnos de que tenemos instalado java en el equipo donde se va a instalar cerebro, para esto basta cone ejecutar el siguiente comando:

```apacheconf
java -version
```

Si no se tiene java hay que instalarlo con el siguiente comando:

```apacheconf
apt install openjdk-11-jre
```

Una vez que se esta seguro de que se tiene java instalado se puede proceder con la descarga de cerebro, para esto nos dirijimos al repositorio oficial de cerebro en GitHub y se accede a la seccion de Releases https://github.com/lmenezes/cerebro/releases, y se procede a descargar la versión estable mas reciente en este caso se va a instalar cerebro en una maquina Debian por lo que se descargara el paquete .deb.

Una vez se tiene el paquete en la maquina en donde se instalará cerebro basta con ejecutar el siguiente comando para instalarlo:

```apacheconf
dpkg -i cerebro_0.8.5_all.deb
```

# Configuración de Cerebro

El archivo de configuración de cerebro es /etc/cerebro/application.conf, en este caso lo que nos interesa es visualizar información sobre el cluster de elastic por lo que no hay que realizar ya que por defecto cerebro nos muestra toda esa información de manera predeterminada, lo único que se tiene que realizar es especificar la ruta hacia el certificado de la CA root del cluster ya que todo el cluster se encuentra configurado para trabajar con certificados, para lograr dicha configuracion simplemente añadimos al final del archivo las siguientes lineas:

```apacheconf
##### Setting up a root CA #####

play.ws.ssl {
  trustManager = {
    stores = [
      { type = "PEM", path = "/etc/cerebro/certs/ca.pem" }
    ]
  }
}

##### Disabling Certificate Validation #####

#play.ws.ssl.loose.acceptAnyCertificate=true
```

En caso de que se deseara que se pueda ingresar directamente a cerebro sin necesidad de autenticación se puede realizar la siguiente configuracion:

```apacheconf
hosts = [
  {
    host = "https://172.16.100.1:9200"
    name = "elasticsearch-cluster"
    auth = {
      username = "elastic"
      password = "elastic"
    }
  }
]
```

Cerebro por defecto corre en el puerto 9000/TCP para cambiar dicho puerto basta con colocar la siguiente linea en el archivo de configuracion:

```apacheconf
http.port = 55555
```

Finalmente la configuracion completa se ve de la siguiente manera:

```apacheconf
secret = "ki:s:[[@=Ag?QI`W2jMwkY:eqvrJ]JqoJyi2axj3ZvOv^/KavOT4ViJSv?6YY4[N"
basePath = "/"
pidfile.path=/dev/null
rest.history.size = 50 // defaults to 50 if not specified
data.path = "./cerebro.db"
es = {
  gzip = true
}
auth = {
  type: ${?AUTH_TYPE}
  settings {
    url = ${?LDAP_URL}
    base-dn = ${?LDAP_BASE_DN}
    method = ${?LDAP_METHOD}
    user-template = ${?LDAP_USER_TEMPLATE}
    // User identifier that can perform searches
    bind-dn = ${?LDAP_BIND_DN}
    bind-pw = ${?LDAP_BIND_PWD}
    group-search {
      // If left unset parent's base-dn will be used
      base-dn = ${?LDAP_GROUP_BASE_DN}
      // Attribute that represent the user, for example uid or mail
      user-attr = ${?LDAP_USER_ATTR}
      // Define a separate template for user-attr
      // If left unset parent's user-template will be used
      user-attr-template = ${?LDAP_USER_ATTR_TEMPLATE}
      // Filter that tests membership of the group. If this property is empty then there is no group membership check
      // AD example => memberOf=CN=mygroup,ou=ouofthegroup,DC=domain,DC=com
      // OpenLDAP example => CN=mygroup
      group = ${?LDAP_GROUP}
    }
    username = ${?BASIC_AUTH_USER}
    password = ${?BASIC_AUTH_PWD}
  }
}
hosts = [
]
http.port = 55555
play.ws.ssl {
  trustManager = {
    stores = [
      { type = "PEM", path = "/etc/cerebro/certs/ca.pem" }
    ]
  }
}
```

Para iniciar cerebro ejecutamos:

```apacheconf
systemctl start cerebro.service
```

## Referencias

https://github.com/lmenezes/cerebro  
https://github.com/lmenezes/cerebro/releases  
https://docs.search-guard.com/latest/elasticsearch-cerebro-search-guard  
