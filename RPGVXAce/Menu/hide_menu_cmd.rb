#==============================================================================
# Hide Main Menu Commands
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 27/04/2025
#
# Allows to control by swicthes which menus are displayed
# Note that it does not add new menus, you must first add the menu commands 
# by another script
# This script will just filter the added menu commands.
#
# Term of uses: free for non-commercial and commercial, credit is not mandatory
#==============================================================================

module HideMenuCommands
  CONTROL_SWICTHES = {
    #command_symbol => control_swicth_id
    :item => 1,      #$game_swicth 1 must be true for this command to be displayed
    :skill => 0,     #putting 0 means the command is always displayed
    :equip => 1,
    :status => 1,
    :formation => 1,
    :save => 1,
    #:game_end => 0, #you can comment or remove commands that you always show
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
# Window_MenuCommand
#==============================================================================
class Window_MenuCommand < Window_Command
  #--------------------------------------------------------------------------
  # alias method: add_command
  #--------------------------------------------------------------------------
  alias hmc_add_command add_command
  def add_command(name, symbol, enabled = true, ext = nil)
    hmc_add_command(name,symbol,enabled,ext) if HideMenuCommands.reveal_command?(symbol)
  end
end #Window_MenuCommand