#==============================================================================
# Centered equip slots
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 08/07/2025
#==============================================================================
# Alter tthe window equip menu to be centered when actors have less than 5 equip
# slots
#
# Use: modify the equipments in equip_slots method below
# You can add a small gap between equipments if GAP_MOD is true
#==============================================================================

module CenterEquipSlots
  GAP_MOD = true #set to true to have an even gap between each remaining equipment
end #CenterEquipSlots

#==============================================================================
# ** Game_Actor
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # overwrite method: equip_slots -> removed shield
  #--------------------------------------------------------------------------
  def equip_slots
    return [0,0,2,3,4] if dual_wield?       # Dual wield
    return [0,2,3,4]                        # Normal
  end
end #Game_Actor

#==============================================================================
# ** Window_EquipSlot
#==============================================================================
class Window_EquipSlot < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: refresh
  #--------------------------------------------------------------------------
  alias centered_refresh refresh
  def refresh
    if @actor
      gap = [0, visible_line_number - @actor.equip_slots.size].max
      @gap_y = 0
      if CenterEquipSlots::GAP_MOD && gap > 0
        @gap_y = (item_height*gap) / (@actor.equip_slots.size+1)#item_height / (gap+1)
        @offset_y = @gap_y / 2
      else
        @offset_y = gap * item_height / 2
      end
    end
    centered_refresh
  end
  #--------------------------------------------------------------------------
  # override method: item_rect
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = super(index)
    rect.y += @offset_y + index * @gap_y if @offset_y
    rect
  end
end #Window_EquipSlot