# Configuración para enviar Alertas con Slack

Lo primero que se tiene que hacer es crear una cuenta de slack y habilitar un Incoming Webhook para lograr hacer esto se puede seguir la guia del link numero 1 de el apartado de referencias.

Posteriormente una vez que se ha creado el webhook se puede probar enviando una peticion utilizando curl como se muestra en el link numero 2 del apartado de referencias.

Una vez que tenemos el webhook y que sabemos que funciona vamos a modificar los archivos de configuracion elasticsearch.yml para habilitar el envio con alertas desde slak. El archivo de configuracion queda de la siguiente manera:

```apacheconf
xpack.notification.slack:
  account:
    monitoring:
      message_defaults:
        from: X-Pack
        to: belk
        attachment:
          fallback: "X-Pack Notification"
          color: "#36a64f"
          title: "X-Pack Notification"
          title_link: "https://www.elastic.co/guide/en/x-pack/current/index.html"
          text: "One of your watches generated this notification."
          mrkdwn_in: "pretext, text"
```

Ya que se tienen todos los nodos del cluster configurados de la misma manera lo que se tiene que hacer ahora es proporcionar la Webhook URL de manera segura, para esto hacemos uso del binario especial que viene con elasticsearch para guardar contrseñas llamado `elasticsearch-keystore`, entonces ejecutamos el siguiente comnando y a continuación proporcionamos la URL que obtuvimos al momento de crear la App, esta URL debe ser super secreta y no compartirse y que da la autoridad de publicar mensajes en el canal de slack. una vez que dicha URL ha sido almacenada se reinician todos los nodos del cluster de elastic y las alertas por slack habran quedado habilitadas.

## Ejemplo de Alerta Slack

```apacheconf
"notify-slack" : {
      "throttle_period" : "1m",
      "slack" : {
        "message" : {
          "to" : [ "#belk" ], 
          "text" : "Este es Slack Diciendo que hay un Error" 
        }
      }
    }
```

## Referencias

1. https://api.slack.com/messaging/webhooks
2. https://api.slack.com/apps/AT3JU84R1/incoming-webhooks?success=1
3. https://www.elastic.co/guide/en/elasticsearch/reference/7.5/actions-slack.html
4. https://www.elastic.co/guide/en/elasticsearch/reference/7.5/actions-slack.html#configuring-slack
5. https://www.elastic.co/guide/en/elasticsearch/reference/7.5/notification-settings.html#slack-account-attributes