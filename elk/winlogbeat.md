# Archivo de Configuración para Winlogbeat

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