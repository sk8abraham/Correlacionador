#!/bin/bash

if [ $# -eq 4 ] ;then

echo ""
echo "Respaldando y Asignando la IP Estatica"
echo ""

cp /etc/sysconfig/network-scripts/ifcfg-$1 /etc/sysconfig/network-scripts/$1.bk

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$1

DEVICE=$1
BOOTPROTO=static
IPADDR=$2.$3
NETMASK=255.255.255.0
GATEWAY=$2.$4
ONBOOT=yes
EOF

echo ""
echo "Reiniciando servicio de red"
echo ""

service network restart

else

echo "Usa: ip.sh <interface> <baseip> <ipaddress> <ipaddress_gw>"
echo "Ejemplo: ip.sh eth0 192.168.1 15 1"

fi