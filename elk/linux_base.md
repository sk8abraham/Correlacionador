# Base System

Debian 10.2.0 (Buster)

Partitioned 

- Para crear el disco base se instalo el sistema en Hyper-V creando una maquina de generacion 1 ya que la de generacion 2 generaba problemas al momento de intentar crear discos diferenciales.

- Las maquinas virtuales creadas usando discos diferenciales a partir del disco base creado son de generacion 1.

## Disable `IPv6`

### `/etc/sysctl.conf`

```apacheconf
net.ipv6.conf.all.disable_ipv6 = 1  
net.ipv6.conf.default.disable_ipv6 = 1  
net.ipv6.conf.lo.disable_ipv6 = 1  
```
## Packages
```apacheconf
apt install vim tree tcpdump network-manager lolcat iptables-persistent sudo curl
```


