import json

class Humano:

  def __init__( self ):

    try:
      with open( "/home/jeipi/throttle_period.json", "rb" ) as throttle_period:
        self.throttle_period_dict = json.loads( throttle_period.read() )
        print( json.dumps( self.throttle_period_dict, indent = 2 ), type( self.throttle_period_dict ) )
    except FileNotFoundError:
      self.throttle_period_dict = {}
  
  def dump( self ):

    for key in self.throttle_period_dict.keys():
      self.throttle_period_dict[key] = 1000
    print( json.dumps( self.throttle_period_dict, indent = 2 ), type( self.throttle_period_dict ) )
    
    with open( "/home/jeipi/throttle_period.json", "w" ) as throttle_period:
      throttle_period.write( json.dumps( self.throttle_period_dict, indent = 2 ) )

humano = Humano()
humano.dump()