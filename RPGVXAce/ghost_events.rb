#==============================================================================
# Ghost Event v2
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 24/03/2025
#==============================================================================
# Allows some events to cross everything except the player
# To do so, put in the comment of the active event's page:
# <collide_with_player>
#
# Both the event and the player won't be able to cross each others
#==============================================================================

module GHOST_EVENT
  ACTIVE = "<collide_with_player>"
end #GHOST_EVENT

#==========================================================================
# Game_Map
#==========================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # alias method: setup
  #--------------------------------------------------------------------------
  alias tge_gm_setup setup
  def setup(map_id)
    tge_gm_setup(map_id)
    @events.each_value {|event|  event.read_collide}
  end
end #Game_Map

#==========================================================================
# Game_Event
#==========================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :collide_with_player
  #--------------------------------------------------------------------------
  # override method: passable?
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    x2 = $game_map.round_x_with_direction(x, d)
    y2 = $game_map.round_y_with_direction(y, d)
    return false if (@collide_with_player && $game_player.pos?(x2,y2))
    super(x,y,d)
  end
  #--------------------------------------------------------------------------
  # alias method: refresh
  #--------------------------------------------------------------------------
  alias tge_ge_refresh refresh
  def refresh
    tge_ge_refresh
    read_collide
  end
  #--------------------------------------------------------------------------
  # new method: read_collide
  #--------------------------------------------------------------------------
  def read_collide
    @collide_with_player = @list && @list.any? {|command| command.code == 108 && command.parameters[0].include?(GHOST_EVENT::ACTIVE)}
  end
end #Game_Event


#==========================================================================
# Game_Player
#==========================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # override method: passable?
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    x2 = $game_map.round_x_with_direction(x, d)
    y2 = $game_map.round_y_with_direction(y, d)
    return false if !(@through || debug_through?) && $game_map.events.values.any? {|event| event.pos?(x2,y2) && event.collide_with_player}
    super(x,y,d)
  end
end #Game_Player