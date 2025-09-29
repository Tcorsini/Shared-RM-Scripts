#==============================================================================
# Hide Title Menu Commands
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 28/04/2025
#
# requires: Tsukihime's Preserve Data to use switches from a save file.
#
# Allows to control by switches which commands are displayed in the title menu.
# Note that it does not add new commands, you must first add them with another
# script. This script will just filter the added commands.
#
# Term of uses: free for non-commercial and commercial, credit is not mandatory
#==============================================================================

module HideTitleMenuCommands
  CONTROL_SWICTHES = {
    #command_symbol => control_swicth_id
    :continue => 1,      #$game_swicth 1 must be true for this command to be displayed
    :new_game => 0,     #putting 0 means the command is always displayed
    #:shutdown => 0, #you can comment or remove commands that you always show
  } #don't remove
 
  #--------------------------------------------------------------------------
  # method: reveal_command? -> return true iff the command can be shown
  # By default, the command will be hidden if the swicth provided is false
  # If no swicth is provided (<= 0) or no entry, then show the command
  #--------------------------------------------------------------------------
  def self.reveal_command?(symbol)
    s_id = CONTROL_SWICTHES[symbol]
    return $game_switches[s_id] if s_id && s_id > 0
    return true #don't hide it
  end
end #HideMenuCommands

#==============================================================================
# Window_TitleCommand
#==============================================================================
class Window_TitleCommand < Window_Command
  #--------------------------------------------------------------------------
  # alias method: add_command
  #--------------------------------------------------------------------------
  alias htmc_add_command add_command
  def add_command(name, symbol, enabled = true, ext = nil)
    htmc_add_command(name,symbol,enabled,ext) if HideTitleMenuCommands.reveal_command?(symbol)
  end
end #Window_MenuCommand

#===============================================================================
# Scene_Title
#===============================================================================
class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: start -> asks the DataManager to load the switches
  #--------------------------------------------------------------------------
  alias htmc_scene_title_start start
  def start
    DataManager.load_preserved_switches
    htmc_scene_title_start
  end
end #Scene_Title

#===============================================================================
# DataManager -> deals with loading preserved switches
#===============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: init
  #--------------------------------------------------------------------------
  class <<self; alias htmc_data_manager_init init; end
  def self.init
    htmc_data_manager_init
    @last_savefile_index = latest_savefile_index #make sure that the last save file is most recent one at start
  end
  #--------------------------------------------------------------------------
  # new method: load_preserved_switches
  #--------------------------------------------------------------------------
  def self.load_preserved_switches
    $game_temp.preserving_data = true
    $game_switches = Game_Switches.new unless $game_switches
    filename = make_filename(last_savefile_index)
    return unless File.exist?(filename)
    header = {}
    contents = {}
    File.open(make_filename(last_savefile_index), "rb") do |file|
      header = Marshal.load(file)
      contents = Marshal.load(file)
    end
    # Update switches data
    TH::Preserve_Data::Switches.each {|id|
      $game_switches[id] = contents[:switches][id]
    }
    $game_temp.preserving_data = false
  end
end #DataManager