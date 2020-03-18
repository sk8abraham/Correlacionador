# Plantillas personalizadas
Debido a que habían campos que no estaban normalizados, se crearon plantillas en las cuales se puede cambiar el tipo de mapeado de los datos para asignar de manera adecuada el nombre o el tipo de dato del campo que se requiera cambiar.  
La plantilla que hicimos fue para modificar el nombre del campo de la dirección IP que provenian de filebeat el cual enviaba datos de OSSEC:  
```apacheconf
{
  "ossec" : {
    "order" : 1,
    "index_patterns" : [
      "ossec*"
    ],
    "settings" : { },
    "mappings" : {
      "_routing" : {
        "required" : false
      },
      "numeric_detection" : false,
      "dynamic_date_formats" : [
        "strict_date_optional_time",
        "yyyy/MM/dd HH:mm:ss Z||yyyy/MM/dd Z"
      ],
      "_meta" : { },
      "_source" : {
        "excludes" : [ ],
        "includes" : [ ],
        "enabled" : true
      },
      "dynamic" : true,
      "dynamic_templates" : [ ],
      "date_detection" : true,
      "properties" : {
        "source" : {
          "type" : "object",
          "properties" : {
            "address" : {
              "eager_global_ordinals" : false,
              "norms" : false,
              "index" : true,
              "store" : false,
              "type" : "keyword",
              "split_queries_on_whitespace" : false,
              "index_options" : "docs",
              "doc_values" : true
            },
            "ip" : {
              "index" : true,
              "store" : false,
              "type" : "ip",
              "doc_values" : true
            }
          }
        }
      }
    },
    "aliases" : { }
  }
```
# Referencias  
https://www.elastic.co/guide/en/elasticsearch/reference/master/indices-templates.html
