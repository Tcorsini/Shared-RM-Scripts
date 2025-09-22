#==============================================================================
# Yanfly Save Engine with rpg maker original save menu - galv confirm patch
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 05/08/2025
# Requires: Tim's Original save menu and its requirements and Galv's confirm addon
# to Yanfly's save engine
#==============================================================================
# Installation: put it below the required scripts
#==============================================================================

#==============================================================================
# Scene_File
#==============================================================================
class Scene_File < Scene_MenuBase
  #--------------------------------------------------------------------------
  # alias method: create_all_windows
  #--------------------------------------------------------------------------
  alias tim_ysom_galv_create_all_windows create_all_windows
  def create_all_windows
    tim_ysom_galv_create_all_windows
    create_confirm_window
  end
  #--------------------------------------------------------------------------
  # alias method: cursor_movable?
  #--------------------------------------------------------------------------
  alias tim_ysom_galv_cursor_movable? cursor_movable?
  def cursor_movable?
    tim_ysom_galv_cursor_movable? && !@confirm_window.active
  end
end #Scene_File