#!/usr/bin/python3 -W ignore
# -*- coding: utf-8 -*-

import datetime, json, requests

class Alert():

    def __init__( self, name, index, active, status_code, match, message, media, response ):
        
        self.name = name
        self.index = index
        self.active = active
        self.status_code = status_code
        self.match = match
        self.message = message
        self.media = media
        self.response = response
    
    def __str__(self):

        message = self.message.replace("\n\t", "")

        return f'\tName: {self.name}\n\tIndex: {self.index}\n\tActive: {self.active}\n\tStatus-Code: {self.status_code}\n\tMatch: {self.match}\n\tMessage: {message}\n\tResponse: {str(self.response)[:100]} ...'

class Alert_Master():

    def __init__( self, alerts_dict, alerts_functions_dict, elastic_url, credentials_file_name ):
        
        self.alerts_dict = alerts_dict
        self.alerts_functions_dict = alerts_functions_dict
        self.elastic_url = elastic_url

        with open( credentials_file_name, 'r' ) as credentials:
            self.credentials = json.loads( credentials.read() )        
    
    def enrich_alerts_dict( self ):

        '''
            Description: This function updates status_code and response
        '''

        for alert_name in self.alerts_dict.keys():
            if self.alerts_dict[alert_name].active:
                with open(self.alerts_dict[alert_name].name, 'r') as alert_search:

                    response = requests.get( self.elastic_url + self.alerts_dict[alert_name].index + '/_search',
                                                headers = { "Content-type" : "application/json" },
                                                json = json.loads(alert_search.read()),
                                                auth = requests.auth.HTTPBasicAuth( self.credentials["elastic_user"], self.credentials["elastic_password"] ),
                                                verify = False )

                    self.alerts_dict[alert_name].status_code = response.status_code 

                    if response.status_code == 200:
                        self.alerts_dict[alert_name].response = json.loads(response.content)
                    #print( response.content.decode('utf-8') ) ##### DEBUG #####
            else:
                print( f'La alerta {alert_name} no esta activada' ) ##### DEBUG #####
                        
    def verify_alerts( self ):

        '''
            Description: This funciton updates match and message fields from alert objects.
        '''

        for alert_name in self.alerts_dict.keys():
            if self.alerts_dict[alert_name].active:
                self.alerts_dict[alert_name].match, self.alerts_dict[alert_name].message = self.alerts_functions_dict[alert_name]( self.alerts_dict[alert_name].response )
                #print( self.alerts_dict[alert_name] ) ##### DEBUG #####
            else:
                print( f'La alerta {alert_name} no esta activada' ) ##### DEBUG #####

    def send_alerts( self ):

        for alert_name in self.alerts_dict.keys():
            if self.alerts_dict[alert_name].match:
                if 'slack' in self.alerts_dict[alert_name].media:
                    response = requests.post( self.credentials["slack_url"],
                                                headers = { "Content-type" : "application/json" },
                                                json = { "text" : self.alerts_dict[alert_name].message },
                                                verify = False )
            else:
                print( f'La alerta {alert_name} no arrojo resultados' ) ##### DEBUG #####

##### Alerts Dictionary #####

alerts_dict = { 'windows_iis_basic_auth_bruteforce' :  Alert( 'windows_iis_basic_auth_bruteforce.json', 'filebeat*', True, None, False, '', ['slack'], None ),
                'windows_login_admin_logins' :  Alert( 'windows_login_admin_logins.json', 'winlogbeat*', True, None, False, '', ['slack'], None ) }

##### Alerts' Functions Dictionary [They parse the response to genreate the message to send] #####

def windows_iis_basic_auth_bruteforce( response ):

    if response["aggregations"]["search"]["buckets"]:

        attack_ip = response["aggregations"]["search"]["buckets"][0]["key"]
        attempts_number = response["aggregations"]["search"]["buckets"][0]["doc_count"]

        if attempts_number > 20:
            write_log( f'windows_iis_basic_auth_bruteforce::IP: {attack_ip}::Intentos: {attempts_number}\n' )
            return ( True, f'Ataque de Fuerza Bruta a Autenticación Basic Detectada\n\tEquipo: IIS-WS2019\n\tIP Atacante: {attack_ip}\n\tNúmero de Intentos: {attempts_number}' )
        
    return ( False, '' )

def windows_login_admin_logins( response ):

    if response["aggregations"]["search"]["buckets"]:

        admin_logins = ''

        for admin_login in response["aggregations"]["search"]["buckets"]:
            admin_logins += f'\tEl usuario { admin_login["key"] } inició sesión { admin_login["doc_count"] } veces\n'
        
        write_log( f'SE DETECTARON LOS SIGUIENTES INICIOS DE SESIÓN DE USUARIOS ADMINISTRADORES\n{ admin_logins }'.replace("\n", "") + '\n' ) ##### DEBUG #####

        return ( True, f'SE DETECTARON LOS SIGUIENTES INICIOS DE SESIÓN DE USUARIOS ADMINISTRADORES\n{ admin_logins }'.rstrip() )

    return ( False, '' )

alerts_functions_dict = { 'windows_iis_basic_auth_bruteforce' : windows_iis_basic_auth_bruteforce,
                            'windows_login_admin_logins' : windows_login_admin_logins }

def write_log( string ):
    with open('/home/jeipi/alerts.log', 'a') as alerts_log:
        alerts_log.write(f'{(datetime.datetime.utcnow()).replace(tzinfo=datetime.timezone.utc).astimezone().replace(microsecond=0).isoformat()} {string}\n')

poc = Alert_Master( alerts_dict, alerts_functions_dict, 'https://172.16.100.1:9200/', '/home/jeipi/credentials.json' )
poc.enrich_alerts_dict()
poc.verify_alerts()
#poc.send_alerts()

#import subprocess
#commando = subprocess.run(["curl", "-X", "POST", "-H", "'Content-type: aplication/json'", "--data", "{'text':'Prueba'}", slack_channel], capture_output=True)

### Polish Request ###

    # if alert_name == 'windows_login_admin_logins':

    #     date = datetime.datetime.utcnow()
    #     lte = date.replace(tzinfo=datetime.timezone.utc).astimezone().replace(microsecond=0).isoformat()
    #     gte = (date - datetime.timedelta( minutes =15 )).replace(tzinfo=datetime.timezone.utc).astimezone().replace(microsecond=0).isoformat()

    #     data["query"]["bool"]["filter"]["range"]["@timestamp"]["gte"] = gte
    #     data["query"]["bool"]["filter"]["range"]["@timestamp"]["lte"] = lte