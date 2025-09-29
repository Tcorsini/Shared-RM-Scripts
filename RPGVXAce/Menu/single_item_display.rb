#==============================================================================
# Single item display
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 01/06/2025
#
# Items with multiple occurences are split into multiple entries in the item
# windows. They are still considered one item in the database.
#==============================================================================
# Installation: put this below scripts adding new inventory features, otherwise plug and play
# Works with Hime's Instance items, Actor inventory and Theo Allen's Limited Inventory
# If you use them along with my patch for them, put this script below the patch.
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM_SingleItems"] = true

module TIM
  module SingleItem
    DISPLAY_SINGLE_NUMBER = false #to not display anything if the item is not stackable
    
    module REGEXP
      SINGLE_EXCEPTION = /<stacked>/i #if you don't want the item to be splited, does not work with instance items as they are single items
    end #REGEXP
    
    #--------------------------------------------------------------------------
    # new method: stack_item?
    #--------------------------------------------------------------------------
    def self.stack_item?(obj)
      if $imported["TH_InstanceItems"] && InstanceManager.instance_enabled?(obj)
        false
      else
        obj.stackable
      end
    end
  end #SingleItem
end #TIM

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_single_items load_database; end
  def self.load_database
    load_database_single_items
    load_notetags_single_items
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_single_items
  #--------------------------------------------------------------------------
  def self.load_notetags_single_items
    groups = [$data_items,$data_armors,$data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_single_items
      end
    end
  end
end # DataManager

#============================================================================
# RPG::BaseItem
#============================================================================
class RPG::BaseItem
  attr_reader :stackable
  #--------------------------------------------------------------------------
  # common cache: load_notetags_single_items
  #--------------------------------------------------------------------------
  def load_notetags_single_items
    @stackable = false
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::SingleItem::REGEXP::SINGLE_EXCEPTION
        @stackable = true
      end
      #---
    } # self.note.split
    #---
  end
end # RPG::BaseItem


#==============================================================================
# Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
 
  #-----------------------------------------------------------------------------
  # alias method: make_item_list
  #-----------------------------------------------------------------------------
  alias single_item_make_item_list make_item_list
  def make_item_list
    single_item_make_item_list
    @data = @data.inject([]){|l,i| l + (i && !TIM::SingleItem.stack_item?(i) ? [i]*original_item_number(i) : [i])}
  end
  
  #-----------------------------------------------------------------------------
  # new method: original_item_number
  #-----------------------------------------------------------------------------
  def original_item_number(item)
    if $imported["TH_ActorInventory"] && !($imported["TIM-AI-addon-SharedItems"] && TIM::ActorInventoryAddon.shared_inventory?(item))
      @actor.item_number(item)
    else
      $game_party.item_number(item)
    end
  end
  
  #-----------------------------------------------------------------------------
  # overwrite method: draw_item_number
  #-----------------------------------------------------------------------------
  def draw_item_number(rect, item)
    return unless TIM::SingleItem::DISPLAY_SINGLE_NUMBER || TIM::SingleItem.stack_item?(item)
    draw_text(rect, sprintf(":%2d", TIM::SingleItem.stack_item?(item) ? original_item_number(item) : 1), 2)
  end
end #Window_ItemList


#==============================================================================
# Compatibility patch with TheoAllen's limited inventory
#==============================================================================
if $imported[:Theo_LimInventory]
  
#==============================================================================
# Window_Base
#==============================================================================
class Window_Base < Window
  #-----------------------------------------------------------------------------
  # new method: original_item_number
  #-----------------------------------------------------------------------------
  def original_item_number(item)
    if $imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"]
      SceneManager.scene.actor.item_number(item)
    else
      $game_party.item_number(item)
    end
  end
  
  unless $imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"]
    #-----------------------------------------------------------------------------
    # overwrite method: draw_item_size (already overwritten by one of my patch)
    #-----------------------------------------------------------------------------
    def draw_item_size(item,x,y,total = true,width = contents.width)
      rect = Rect.new(x,y,width,line_height)
      change_color(system_color)
      draw_text(rect,Theo::LimInv::InvSizeVocab)
      change_color(normal_color)
      #modified here:
      number = get_item_size(item,total)
      draw_text(rect,number,2)
    end
    
    #-----------------------------------------------------------------------------
    # new method: get_item_size (already defined by one of my patch)
    #-----------------------------------------------------------------------------
    def get_item_size(item,total = true)
      if Theo::LimInv::DrawTotal_Size && total
        $game_party.item_size(item)
      else
        item.nil? ? 0 : item.inv_size
      end
    end
  end #$imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"]
  
  #-----------------------------------------------------------------------------
  # alias method: get_item_size
  #-----------------------------------------------------------------------------
  alias single_items_get_item_size get_item_size
  def get_item_size(item,total = true)
    r = single_items_get_item_size(item,total)
    r /= original_item_number(item) unless total
    return r
  end
end #Window_Base
  
#==============================================================================
# Window_DiscardAmount
#==============================================================================
class Window_DiscardAmount < Window_Base
  #-----------------------------------------------------------------------------
  # alias method: lose_item
  #-----------------------------------------------------------------------------
  alias single_item_lose_item lose_item
  def lose_item
    b =  @amount > 0 && !TIM::SingleItem.stack_item?(@item) && @amount < original_item_number(@item)
    single_item_lose_item
    if b
      Sound.play_ok
      @itemlist.activate.refresh
      @itemlist.update_help
      @cmn_window.close.deactivate
      close
    end
  end
end #Window_DiscardAmount
end #$imported[:Theo_LimInventory]