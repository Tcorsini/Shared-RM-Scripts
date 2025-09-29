#==============================================================================
# Camera Offset
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 26/09/2025
#==============================================================================
# Allow the screen on the map to be reduced to a smaller window with offset X,Y
# width WIDTH and height HEIGHT
#==============================================================================

module CameraOffset
  X = 10 #offset in pixels
  Y = 0 #offset in pixels
  WIDTH = Graphics.width - 100 #window's width in pixels
  HEIGHT = Graphics.height - 40 #window's height in pixels
  
  TILE_SIZE = 32.0 #a constant to not modify
end #CamCenter

#============================================================================
# Game_Player
#============================================================================
class Game_Player
  #you can modify these values mid game but you'll have to refresh the scene
  attr_accessor :cam_x, :cam_y, :cam_w, :cam_h
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tim_camera_initialize initialize
  def initialize
    tim_camera_initialize
    @cam_x = CameraOffset::X
    @cam_y = CameraOffset::Y
    @cam_w = CameraOffset::WIDTH
    @cam_h = CameraOffset::HEIGHT
  end
  #--------------------------------------------------------------------------
  # overwrite method: center_x
  #--------------------------------------------------------------------------
  def center_x
    ((@cam_w) / CameraOffset::TILE_SIZE - 1) / 2.0
  end
  #--------------------------------------------------------------------------
  # overwrite method: center_y
  #--------------------------------------------------------------------------
  def center_y
    ((@cam_h) / CameraOffset::TILE_SIZE - 1) / 2.0
  end
end #Game_Player

#============================================================================
# Game_Map
#============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # overwrite method: screen_tile_x
  #--------------------------------------------------------------------------
  def screen_tile_x
    $game_player.cam_w / CameraOffset::TILE_SIZE
  end
  #--------------------------------------------------------------------------
  # overwrite method: screen_tile_y
  #--------------------------------------------------------------------------
  def screen_tile_y
    $game_player.cam_h / CameraOffset::TILE_SIZE
  end
end #Game_Map

#============================================================================
# Spriteset_Map
#============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # overwrite method: create_viewports
  #--------------------------------------------------------------------------
  def create_viewports
    @viewport1 = Viewport.new($game_player.cam_x,$game_player.cam_y,$game_player.cam_w,$game_player.cam_h)
    @viewport2 = Viewport.new($game_player.cam_x,$game_player.cam_y,$game_player.cam_w,$game_player.cam_h)
    @viewport3 = Viewport.new($game_player.cam_x,$game_player.cam_y,$game_player.cam_w,$game_player.cam_h)
    @viewport2.z = 50
    @viewport3.z = 100
  end
end #Spriteset_Map