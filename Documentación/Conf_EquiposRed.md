### Configuración de dispositivos de red.
#### Cisco
Ejemplo de topografia.

![Selection_002_23_06.jpg](https://www.gns3.com/api/v2/assets/photo/5b2e6d67f0c61a128add5194/Selection_002_23_06.jpg)

#### Configuración Router Cisco
```
configure terminal
no ip domain-lookup
clock timezone CST -6 
ip route 0.0.0.0 0.0.0.0 f0/0
logging host 172.16.200.220 transport udp port 5614
```
#### Configuración Router Switch
```
configure terminal
no ip domain-lookup
clock timezone CST -6 
logging host 172.16.200.220 transport udp port 5614
```

#### Configuración de SSH para router.
```
configure terminal
ip domain-name kibanosos.net
crypto key generate rsa
2048
ip ssh version 2
line vty 0 4
transport input ssh
login local
username admin password my_password
```

[How to configure SSH on Cisco IOS \| NetworkLessons.com](https://networklessons.com/cisco/ccna-200-301/configure-ssh-cisco-ios)

[Enable SSH in Cisco IOS Router](https://www.mustbegeek.com/enable-ssh-in-cisco-ios-router/#.Xjn04i2ZPOQ)

[Logstash: Processing Cisco Logs · GitHub](https://gist.github.com/justinjahn/85305bc7b7df9a6412baedce5f1a0ece)

#### Configuraciñon de FortiGate IOS v5.x

Configuración inicial.
- Usuario default: admin
- Password default: vacio
```
config system interface
edit port1
set mode static
set ip 172.16.200.201 255.255.0.0
set allowaccess ping https ssh 
end
execute reboot
```

Comprobamos tener acceso a la red y conexion con nuestro Logstash
```
execute ping 172.16.200.220
```

#### Configurar FortiGate para enviar log a Logstash
![xfortigate-logging-flow-elasticsearch.png.pagespeed.ic.rkIWmcbHTp.png](https://conetix.com.au/wp-content/uploads/2014/10/29/xfortigate-logging-flow-elasticsearch.png.pagespeed.ic.rkIWmcbHTp.png)
```
config log syslogd setting
    set status enable
    set server "172.16.200.220"
    set port 5514
end
config log syslogd filter
    set severity error
end
```
#### Topologia implementada para ELK
![7d502365.png](:storage/fbae03fa-e5e7-476e-90bf-a4e58f037969/7d502365.png)


- [Conetix Network Operations Centre Build Part 3 - Metrics and Monitoring • Conetix](https://conetix.com.au/blog/conetix-network-operations-centre-build-part-3/)
- [GitHub - darioajr/ELK: NOC ELK + FORTINET LOG](https://github.com/darioajr/ELK)
 - [Fortigate FortiOS 5.2 (and 5.2.2) Logstash Grok patterns · GitHub](https://gist.github.com/timbutler/ecab50967075b150d47b)