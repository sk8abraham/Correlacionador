## Obtener un Listado de Logs que nos Interesen

En un PowerShell ejecutar el siguiente comando:

```apacheconf
Get-WinEvent -Listlog * | ? { $_.LogName -match "DHCP" }
```

## Obtener los Registros de un Log en Especifico

```apacheconf
Get-WinEvent -LogName NombreDelLog
```

# SQL Server Logs

https://www.elastic.co/blog/monitoring-microsoft-sql-server-using-metricbeat-and-elasticsearch

# Referencias

Información sobre los eventos de los logs de Windows

- https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4722
- https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventID=4625