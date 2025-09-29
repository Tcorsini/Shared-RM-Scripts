#==============================================================================
# YBE vanilla menu switch addon
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 05/09/2025
# Requires: Yanfly Battle Engine with original character menu v1.1
#==============================================================================
# Use: put it below the required scripts, set YBE_VANILLA_MENU
# to the id of the switch you wish to use to swicth between the two interfaces
# You can try in debug mode in battle to press F9 to see how the menu swicthes
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YEA-ABE-OriginalMenu-switch-addon"] = true

if $imported["TIM-YEA-ABE-OriginalMenu-switch-addon"] && $imported["TIM-YEA-ABE-OriginalMenu"] && $imported["YEA-BattleEngine"]

#==============================================================================
# module
#==============================================================================
module TIM
  module SWITCH
    #id of the switch you want to trigger to switch between vanilla and
    #yanfly's menu:
    YBE_VANILLA_MENU = 1
   
    #Do not modify anything below:
    def self.ybe_vanilla_menu?
      $game_switches[YBE_VANILLA_MENU]
    end
   
    def self.ybe_vanilla_reverse_switch
      $game_switches[YBE_VANILLA_MENU] = !$game_switches[YBE_VANILLA_MENU]
    end
  end #SWITCH
end #TIM
 
#==============================================================================
# Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  alias tim_switch_ybe_update_debug update_debug
  def update_debug
    tim_switch_ybe_update_debug
    return unless $TEST || $BTEST
    TIM::SWITCH.ybe_vanilla_reverse_switch if Input.trigger?(:F9)
  end
end #Scene_Battle

#==============================================================================
# Window_BattleStatus
#==============================================================================
class Window_BattleStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias tim_switch_ybe_initialize initialize
  def initialize
    @vanilla_menu = TIM::SWITCH.ybe_vanilla_menu?
    tim_switch_ybe_initialize
  end
  #--------------------------------------------------------------------------
  # alias method: col_max
  #--------------------------------------------------------------------------
  alias tim_switch_ybe_col_max col_max
  def col_max
    vanilla_menu? ? tim_switch_ybe_col_max : ybe_wbstatus_col_max
  end
  #--------------------------------------------------------------------------
  # alias method: draw_item
  #--------------------------------------------------------------------------
  alias tim_switch_ybe_draw_item draw_item
  def draw_item(index)
    vanilla_menu? ? tim_switch_ybe_draw_item(index) : ybe_wbstatus_draw_item(index)
  end
  #--------------------------------------------------------------------------
  # alias method: item_rect
  #--------------------------------------------------------------------------
  alias tim_switch_ybe_item_rect item_rect
  def item_rect(index)
    vanilla_menu? ? tim_switch_ybe_item_rect(index) : ybe_wbstatus_item_rect(index)
  end
  #--------------------------------------------------------------------------
  # alias method: update
  #--------------------------------------------------------------------------
  alias tim_switch_ybe_update update
  def update
    tim_switch_ybe_update
    if TIM::SWITCH.ybe_vanilla_menu? != vanilla_menu?
      @vanilla_menu = TIM::SWITCH.ybe_vanilla_menu?
      refresh
      cursor_rect.set(item_rect(@index))
    end
  end
  #--------------------------------------------------------------------------
  # new method: vanilla_menu?
  #--------------------------------------------------------------------------
  def vanilla_menu?; @vanilla_menu; end
end #Window_BattleStatus

end #$imported["TIM-YEA-ABE-OriginalMenu-switch-addon"] && $imported["TIM-YEA-ABE-OriginalMenu"] && $imported["YEA-BattleEngine"]