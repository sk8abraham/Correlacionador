#!/usr/bin/python3 -W ignore
# -*- coding: utf-8 -*-

import datetime, json, requests

class Alert():

    def __init__( self, name, index, throttle_period, active, status_code, match, message, media, response ):
        
        self.name = name
        self.index = index
        self.throttle_period = throttle_period
        self.active = active
        self.status_code = status_code
        self.match = match
        self.message = message
        self.media = media
        self.response = response
    
    def __str__(self):

        message = self.message.replace("\n\t", "")

        return f'\n\tName: {self.name}\n\tIndex: {self.index}\n\tActive: {self.active}\n\tStatus-Code: {self.status_code}\n\tMatch: {self.match}\n\tMessage: {message}\n\tResponse: {str(self.response)[:100]} ...'

class Alert_Master():

    def __init__( self, alerts_dict, alerts_functions_dict, elastic_url, credentials_file_name ):
        
        self.alerts_dict = alerts_dict
        self.alerts_functions_dict = alerts_functions_dict
        self.elastic_url = elastic_url

        with open( credentials_file_name, "r" ) as credentials:
            self.credentials = json.loads( credentials.read() )

        ##### Aqui se esta cargando el archvo json que va a controlar si una alerta ya ha sido enviada, esta no se vuelva a enviar

        try:
            with open( "/home/jeipi/throttle_period.json", "r" ) as throttle_period:
                self.throttle_period_dict = json.loads( throttle_period.read() )
                ### print( json.dumps( self.throttle_period_dict, indent = 2 ), type( self.throttle_period_dict ) ) ##### DEBUG #####
        except FileNotFoundError:
            self.throttle_period_dict = {}

    def enrich_alerts_dict( self ):

        '''
            Description: This function updates status_code and response and discards alert if throttle_period is not zero
        '''

        for alert_name in self.alerts_dict.keys(): # For each alert within our alerts_dict

            if self.alerts_dict[alert_name].active and self.throttle_period_dict[alert_name] == 1: # If the alert has been enabled and throttle_period is One

                write_log( f' Ready 2 execute:: { alert_name } throttle_period:: { self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####

                with open( self.alerts_dict[alert_name].name, "r" ) as alert_search: # Open the json request that is going to be requested to elastic-cluster

                    response = requests.get( self.elastic_url + self.alerts_dict[alert_name].index + '/_search',
                                                headers = { "Content-type" : "application/json" },
                                                json = json.loads( alert_search.read() ),
                                                auth = requests.auth.HTTPBasicAuth( self.credentials["elastic_user"], self.credentials["elastic_password"] ),
                                                verify = False ) # Build the request and send it to elastic-cluster

                    self.alerts_dict[alert_name].status_code = response.status_code # Update the status_code of the current Alert object

                    if response.status_code == 200: # If a successful response has been recieved
                        self.alerts_dict[alert_name].response = json.loads( response.content ) # Update response of the current Alert object
                    
                    self.alerts_dict[ alert_name ].match, self.alerts_dict[ alert_name ].message = self.alerts_functions_dict[ alert_name ]( self.alerts_dict[ alert_name ].response )
                    
                    write_log( f'{ self.alerts_dict[ alert_name ] }' ) ##### DEBUG #####

            else:

                if not self.alerts_dict[alert_name].active:
                    write_log( f'Info,La alerta no esta activada,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####
                else:
                    write_log( f'Info,La alerta aun no debe ser enviada,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####

    def send_alerts( self ):

        for alert_name in self.alerts_dict.keys():
            if self.alerts_dict[alert_name].active and self.alerts_dict[ alert_name ].match and self.throttle_period_dict[ alert_name ] == 1:
                if 'slack' in self.alerts_dict[ alert_name ].media:
                    response = requests.post( self.credentials[ "slack_url" ],
                                                headers = { "Content-type" : "application/json" },
                                                json = { "text" : self.alerts_dict[ alert_name ].message },
                                                verify = False )

                    if response.status_code == 200:
                        write_log( f'Info,Alerta enviada a Slack,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####
            else:

                if not self.alerts_dict[alert_name].active:
                    write_log( f'Info,Alerta no enviada a Slack. La alerta no esta activada,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####
                elif not self.alerts_dict[ alert_name ].match:
                    write_log( f'Info,Alerta no enviada a Slack. No se cumplieron las condiciones de la busqueda,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####
                else:
                    write_log( f'Info,Alerta no enviada a Slack. La alerta aun no debe ser enviada,{ alert_name },{ self.throttle_period_dict[ alert_name ] }' ) ##### DEBUG #####
    
    def update_throttle_period( self ):

        for alert_name in self.alerts_dict.keys():
            if self.throttle_period_dict[ alert_name ] <= 1:
                self.throttle_period_dict[ alert_name ] = self.alerts_dict[ alert_name ].throttle_period
            else:
                self.throttle_period_dict[ alert_name ] -= 1

        with open( "/home/jeipi/throttle_period.json", "w" ) as throttle_period:
            throttle_period.write( json.dumps( self.throttle_period_dict, indent = 2 ) )

##### Alerts Dictionary #####

alerts_dict = { 'windows_iis_basic_auth_bruteforce' :  Alert( 'windows_iis_basic_auth_bruteforce.json', 'filebeat*', 10, False, None, False, '', ['slack'], None ),
                'windows_login_admin_logins' :  Alert( 'windows_login_admin_logins.json', 'winlogbeat*', 1, True, None, False, '', ['slack'], None ) }

##### Alerts' Functions Dictionary [They parse the response to genreate the message to send] #####

def windows_iis_basic_auth_bruteforce( response ):

    if response["aggregations"]["search"]["buckets"]:

        attack_ip = response["aggregations"]["search"]["buckets"][0]["key"]
        attempts_number = response["aggregations"]["search"]["buckets"][0]["doc_count"]

        if attempts_number > 20:
            #write_log( f'windows_iis_basic_auth_bruteforce::IP: {attack_ip}::Intentos: {attempts_number}\n' )
            return ( True, f'Ataque de Fuerza Bruta a Autenticación Basic Detectada\n\tEquipo: IIS-WS2019\n\tIP Atacante: {attack_ip}\n\tNúmero de Intentos: {attempts_number}' )
        
    return ( False, '' )

def windows_login_admin_logins( response ):

    if response["aggregations"]["search"]["buckets"]:

        admin_logins = ''

        # for admin_login in response["aggregations"]["search"]["buckets"]:
        #     admin_logins += f'\tEl usuario { admin_login["key"] } inició sesión { admin_login["doc_count"] } veces\n'

        for admin_login in response["aggregations"]["search"]["buckets"]:
            admin_logins += f'\tEl usuario { admin_login["key"] } inició sesión.\n'

        return ( True, f'SE DETECTARON LOS SIGUIENTES INICIOS DE SESIÓN DE USUARIOS ADMINISTRADORES\n{ admin_logins }'.rstrip() )

    return ( False, '' )

alerts_functions_dict = { 'windows_iis_basic_auth_bruteforce' : windows_iis_basic_auth_bruteforce,
                            'windows_login_admin_logins' : windows_login_admin_logins }

def write_log( string ):
    with open('/home/jeipi/alerts.log', 'a') as alerts_log:
        alerts_log.write( f'{ (datetime.datetime.utcnow()).replace(tzinfo=datetime.timezone.utc).astimezone().replace(microsecond=0).isoformat() },{ string }\n' )

poc = Alert_Master( alerts_dict, alerts_functions_dict, 'https://172.16.100.1:9200/', '/home/jeipi/credentials.json' )

poc.enrich_alerts_dict()
poc.send_alerts()
poc.update_throttle_period()

#import subprocess
#commando = subprocess.run(["curl", "-X", "POST", "-H", "'Content-type: aplication/json'", "--data", "{'text':'Prueba'}", slack_channel], capture_output=True)