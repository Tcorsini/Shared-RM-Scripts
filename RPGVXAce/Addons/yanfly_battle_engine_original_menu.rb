#==============================================================================
# Yanfly Battle Engine with original character menu v1.1
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 05/09/2025
# Requires: Yanfly Engine Ace - Ace Battle Engine v1.22
#==============================================================================
# Update history:
# 14/07/2025: v1.0 - Initial release
# 05/09/2025: v1.1 - Added an alias for compatibility with menu swicth
#==============================================================================
# Installation: put it below the required scripts
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YEA-ABE-OriginalMenu"] = true

if $imported["TIM-YEA-ABE-OriginalMenu"] && $imported["YEA-BattleEngine"]

#==============================================================================
# Window_BattleStatus
#==============================================================================
class Window_BattleStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: col_max
  #--------------------------------------------------------------------------
  alias ybe_wbstatus_col_max col_max
  def col_max; return 1; end
  #--------------------------------------------------------------------------
  # alias method: draw_item
  #--------------------------------------------------------------------------
  alias ybe_wbstatus_draw_item draw_item
  def draw_item(index)
    return if index.nil? #nil case
    clear_item(index)
    actor = battle_members[index]
    return if actor.nil? #nil case
    draw_basic_area(basic_area_rect(index), actor)
    draw_gauge_area(gauge_area_rect(index), actor)
  end
  #--------------------------------------------------------------------------
  # overwrite method: item_rect
  #--------------------------------------------------------------------------
  alias ybe_wbstatus_item_rect item_rect
  def item_rect(index); super(index); end
end #Window_BattleStatus

#==============================================================================
# Window_BattleStatusAid
#==============================================================================
class Window_BattleStatusAid < Window_BattleStatus
  #--------------------------------------------------------------------------
  # restore aliased methods: col_max, draw_item
  #--------------------------------------------------------------------------
  def col_max; ybe_wbstatus_col_max; end
  def draw_item(index); ybe_wbstatus_draw_item(index); end
end #Window_BattleStatusAid
 
end #$imported["TIM-YEA-ABE-OriginalMenu"]