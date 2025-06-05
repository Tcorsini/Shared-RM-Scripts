#==============================================================================
# Passability for waterish things
#------------------------------------------------------------------------------
# Author : Timtrack
# date : 10/09/2024
#------------------------------------------------------------------------------
# Allow tiles other than regular water to let ship and boat 
# cross them if the right terrain tag is put
#==============================================================================


module BoatShipPassability
  TILETAG_WATER_PASSABLE = 1 #put this terrain tag on the right tileset for the boat/ship to cross them
end

class Game_Map
  #--------------------------------------------------------------------------
  # * Determine if Passable by boat
  #--------------------------------------------------------------------------
  alias water_boat_passable? boat_passable? 
  def boat_passable?(x, y)
    water_boat_passable?(x,y) or terrain_tag(x,y) == BoatShipPassability::TILETAG_WATER_PASSABLE
  end
  #--------------------------------------------------------------------------
  # * Determine if Passable by Ship
  #--------------------------------------------------------------------------
  alias water_ship_passable? ship_passable? 
  def ship_passable?(x, y)
    water_ship_passable?(x, y) or terrain_tag(x,y) == BoatShipPassability::TILETAG_WATER_PASSABLE
  end
end