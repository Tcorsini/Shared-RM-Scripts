#==============================================================================
# Yanfly Save Engine with rpg maker original save menu v1.1
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 17/07/2025
# Requires: Yanfly Save Engine
# Should be compatible with new game+ addon
#==============================================================================
# The menu will look like rpg maker original save menu with an help window with 
# one line and each save slot taking a fourth of the screen.
# When a save is selected, the action menu (save/load/delete) will be displayed
#==============================================================================
# 17/07/2025: original script
# 05/08/2025: v1.1 with compatibility prep for galv's confirm addon
#==============================================================================
# Installation: put it below yanfly's scripts, if you use Galv's confirm window,
# put this scripts below Galv's and put the small patch I made below this script
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YanflySave-OriginalMenu"] = true

if $imported["YEA-SaveEngine"] && $imported["TIM-YanflySave-OriginalMenu"]

#==============================================================================
# Scene_File
#==============================================================================
class Scene_File < Scene_MenuBase
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias tim_ysom_start start
  def start
    tim_ysom_start
    init_selection
  end
  #--------------------------------------------------------------------------
  # overwrite method: terminate -> restores the original scene behavior
  #--------------------------------------------------------------------------
  def terminate
    super
    @savefile_viewport.dispose
    @savefile_windows.each {|window| window.dispose }
  end
  #--------------------------------------------------------------------------
  # overwrite method: update
  #--------------------------------------------------------------------------
  def update
    super
    return unless cursor_movable? #disable cursor navigation
    @savefile_windows.each {|window| window.update }
    update_savefile_selection
  end
  #--------------------------------------------------------------------------
  # new method: cursor_movable?
  #--------------------------------------------------------------------------
  def cursor_movable?
    !@action_window.active
  end
  #--------------------------------------------------------------------------
  # alias method: update_cursor -> @file_window.index follows the scene index 
  # for compatibility with yanfly's save engine
  #--------------------------------------------------------------------------
  alias tim_ysom_update_cursor update_cursor
  def update_cursor
    tim_ysom_update_cursor
    @file_window.index = index
  end
  #--------------------------------------------------------------------------
  # overwrite method: on_savefile_ok -> calls the action menu
  #--------------------------------------------------------------------------
  def on_savefile_ok
    Sound.play_ok
    on_file_ok
  end
  #--------------------------------------------------------------------------
  # overwrite method: create_all_windows
  #--------------------------------------------------------------------------
  def create_all_windows
    create_help_window
    create_savefile_viewport
    create_savefile_windows
    create_file_window #yanfly's script
    create_action_window #yanfly's script
  end
  #--------------------------------------------------------------------------
  # overwrite method: refresh_windows
  #--------------------------------------------------------------------------
  def refresh_windows
    @action_window.refresh
    @savefile_windows[index].refresh
  end
  #--------------------------------------------------------------------------
  # overwrite method: create_help_window -> restores original line number 
  # along with yanfly's text
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new(1)
    @help_window.set_text(YEA::SAVE::SELECT_HELP)
  end
  #--------------------------------------------------------------------------
  # alias method: create_file_window -> hides the window
  #--------------------------------------------------------------------------
  alias tim_ysom_create_file_window create_file_window
  def create_file_window
    tim_ysom_create_file_window
    @file_window.deactivate
    @file_window.hide
  end
  #--------------------------------------------------------------------------
  # alias method: create_action_window -> centers the window and hide it
  #--------------------------------------------------------------------------
  alias tim_ysom_create_action_window create_action_window
  def create_action_window
    tim_ysom_create_action_window
    #@action_window.openness = 0 #hide it
    @action_window.hide
    #center the window:
    @action_window.x = (Graphics.width - @action_window.width) / 2
    @action_window.y = (Graphics.height - @action_window.height) / 2
  end
  #--------------------------------------------------------------------------
  # overwrite method: on_file_ok -> open the action window
  #--------------------------------------------------------------------------
  def on_file_ok
    i = SceneManager.scene_is?(Scene_Load) ? 0 : 1
    @action_window.select(i)
    @action_window.show
    @action_window.activate
  end
  #--------------------------------------------------------------------------
  # new method: on_action_cancel -> close the action window
  #--------------------------------------------------------------------------
  def on_action_cancel
    @action_window.hide
    @help_window.set_text(YEA::SAVE::SELECT_HELP)
  end
end # Scene_File

end #$imported["YEA-SaveEngine"] && $imported["TIM-YanflySave-OriginalMenu"]