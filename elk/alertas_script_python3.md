# Alertas Script python3

Trabajar con el indexado y consulta de datos con el elastic stack resulta ser algo facil de manejar, sin embargo al momento de tratar de hacer alertas utilizando los datos recopilados no resulta ser algo trivial.

Si se cuenta con una licencia se puede acceder al los modulos de alerting, realizar las configuraciones necesarias en el cluster y empezar a realizar las alertas con los watcher, sin embargo si no se desea gastar un solo centavo podemos optar por herramientas libres que permiten enviar alertas de manera mas o menos intiutiva como lo son `sdfasdfa`. Sin embargo si lo que se desea es tener un mejor control de los datos lo que se puede hacer es implementar un script que se encargue de realizar las consultas y enviar las alertas ahí es donde entra python en acción, dado que elasticsearch trabaja con una API REST un script de python se puede comunicar facilmente con el cluster a traves del modulo requests haciendo peticiones https de tipo json preguntando por información relevante y recibiendo la respuesta en formato json se puede realizar la conversion de dicha respuesta en un diccionario que posteriormente resulta muy sencillo de manipularse dentro del programa.

Para poder realizar las alertas se realizó un script que es ejecutado por el servicio crontab cada minuto.

La configuración de crontab se muestra a continuación:

```
* * * * *
```

## Archivos Externos al Script

El script tabaja con diversos archivos a la vez para poder llevar control de las credenciales empleadas, correos, urls y pausas en la ejecucion de alertas a continuacion se describen estos archivos y su función.

### `throttle_period.json`

Este archivo es el encargado de controlar cuanto tiempo (en minutos) se debe dejar de enviar una alerta despúes de que esta haya sido exitosa, esto con el proposito de evitar el envio masivo de alertas, es decir una vez que una alerta fue enviada se entiende que esta ya ha notificado al administrador del sistema entonces no es necesario estar enviando la alerta cada minuto que pasa si no que se define un tiempo (throttle_period) que es lo suficientemente grande como para que el administrador tome accion sobre la alerta una vez que se vence dicho tiempo la alerta sera enviada nuevamente. Un ejemplo de este archivo luce de la siguiente manera:

```
insert throttle_period
```

### `credentials.json`

En este archivo se encuentran las contraseñas del cluster de elasticsearch, la url del canal de slack y el email al cual se estan enviando las alertas hard coded, esto con el objetivo de que no se encuentren a simple vista en el script principal ya que no es una buena practica de programacíon y ademas si por alguna razón se encuentra la url del canal de slack hard coded y se realiza un push a un repositorio publico el canal se invalida automáticamente. El archivo luce de la siguiente manera:

```

```

### `alerts.log`

Es el archivo bitácora del programa, en el podemos encontrar información util sobre que es lo que esta pasando con el script, ya que este va a estar siendo ejecutado por un crontab no podemos ver errores o información de debugeo del programa en la salida estandar por eso la necesidad de ver dicha informacion en el log. El archivo luce de la siguente manera:

```

```

### `Funcionamiento General del Script`

El funcionamiento del script es bastante sencillo, se tienen dos objetos Alert y Alert_Master, el objeto Alert es el encargado de definir cada una de las alertas, es decir que por cada alerta que se tenga vamos a tener su correspondiente objeto Alert, en sete objeto se guarda toda la informacion referente a la alerta.

El objeto Alert_Master contiene las funciones que hacen posibles las consultas al cluster, la validacion de la respuesta obtenida de las mismas y en caso de que se encuentre que se tiene que enviar una alerta se cuenta con un metodo que sera el encargado de enviar dicha alerta al medio que se especifique.

Para que el script funcione primero necesitamos definir ciertas cosas, un diccionario de alertas donde la llave de cada elemento sera el nombre de la alerta y el valor sera un objeto de tipo Alerta es ahi donde se construyen todos los objetos de tipo Alert, un diccionario de funciones donde cada llave de cada elemento es el nombre de la alerta y cada elemento es una funcion asociada a dicha alerta, un objeto de tipo Alert_Master al que se le pasa como argumentos los diccionarios de alertas y de funciones asi como la url del cluster de elasticsearch y la ruta absoluta del archivo que contiene las credenciales.

Una vez que se tiene el objeto de tipo Alert_Master lo unico que se tiene que hacer es ejecutar los metodos que existen dentro de el:

- enrich_alerts_dict: Se encarga de realizar la petición que corresponde a cada alerta, recibir la respuesta, evaluarla, ejecutar la función asociada a cada una de las alertas y decide si se debe de disparar la alerta de acuerdo con ciertos factores como si la alerta esta activada o si el throttle_period es el adecuado para disparar la alerta.

- send_alerts: Se encarga de enviar las alertas por los medios indicados de las alertas que cumplen con los requisitos para que se envie una alerta.

- update_throttle_period: Se encarga de actualizar los valores de throttle_period del archivo throttle_period.json de manera tal que se controle que alertas deben ser evaluadas y cuales no en la siguiente ejecucion del script.

### Creación de una Nueva Alerta

1. Definir un nombre de alerta: Este `nombre_alerta` será muy importante ya que se usa en varias partes del script para referirse a dicha alerta.
2. Crear un archivo json que contenga la consulta que se va a devolver la información necesaria para poder evaluar alguna condición que nos permita emitir alguna alerta de interés, dicho archivo se llamará `nombre_alerta.json`. Ejemplo: 
```
{
    "query": {
        "bool": {
            "must": [
                {
                    "term": {
                        "event.code": "4624"
                    }
                },
                {
                    "terms": {
                        "winlog.event_data.TargetUserName": [
                            "Administrator",
                            "jesus.pacheco",
                            "pedro.rodriguez",
                            "abraham.manzano"
                        ]
                    }
                }
            ],
            "filter": {
                "range": {
                    "@timestamp": {
                        "gte": "now-1m",
                        "lt": "now"
                    }
                }
            }
        }
    },
    "aggs": {
        "search": {
            "terms": {
                "field": "winlog.event_data.TargetUserName"
            }
        }
    }
}
```
3. Añadir al diccionario `alerts_dict` el par llave,valor donde llave será `nombre_alerta` y valor sera un objeto tipo Alerta, al instanciar este objeto se definiran características importantes de la alerta que influyen a lo largo de la ejecución del programa, el constructor del objeto alerta luce de la siguiente manera: `Alert ( name, index, throttle_period, active, status_code, match, message, media, response )`

4. Crear una función llamada `alert_name` la cual debera de regresar una tupla de dos elementos siempre. Dicha función siempre recibira un diccionario con la respuesta obtenida de ejecutar la consulta con `alert_name.json`, entonces se debera buscar dentro del diccionario la condición de la alerta en caso de que se encuentre con que la condición coincidio se debera regresar una tupla de la forma (True, mensaje a enviar), en caso de que la condición no se manifieste se deberá regresar la tupla (False, ''), añadir el par llave,valor (`alert_name, función`) al diccionario alerts_functions_dict.

5. Añadir al archivo throttle_period.json la llave,valor `alert_name,throttle_period` para que no se genere un error al momento de llevar el control de los throttle_period. Nota todos los throttle_period deberán estar en 1 al inicio de la ejecucion del script por primera vez.