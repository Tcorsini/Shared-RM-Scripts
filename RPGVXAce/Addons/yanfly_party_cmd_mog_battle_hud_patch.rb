#==============================================================================
# YEA Command Party + MOG Battle Hud EX patch
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 05/06/2025
# Requires: Yanfly Command Party and Moghunter Battle Hud Ex
#==============================================================================
# Installation: put it below the required scripts
#==============================================================================

#==============================================================================
# Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # alias method: command_party
  #--------------------------------------------------------------------------
  alias patch_mog_hud_command_party command_party
  def command_party
    patch_mog_hud_command_party
    @spriteset.refresh_battle_hud
  end
end #Scene_Battle