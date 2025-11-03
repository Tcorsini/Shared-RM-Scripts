#==============================================================================
# Hime's Actor Inventory addon - shared items
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 02/06/2025
# Requires: Hime's Actor Inventory and Actor Inventory Scenes
#==============================================================================
# Description: An addon to Hime's Actor Inventory, allow some items, weapons
# or armors to be shared among all inventories.
# To do so, put in the object's notetag <shared_inventory>
# You can also automaties the sharing of key items by setting SHARED_KEY_ITEMS
# to true
#==============================================================================
# Installation: put this below Hime's scripts
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-AI-addon-SharedItems"] = true

#============================================================================
# TIM
#============================================================================
module TIM
  module ActorInventoryAddon
    SHARED_KEY_ITEMS = true
    
    module REGEXP
      SHARED = /<shared_inventory>/i
    end #REGEXP
    
    #--------------------------------------------------------------------------
    # new method: shared_inventory?
    #--------------------------------------------------------------------------
    def self.shared_inventory?(item)
      return false unless item
      return true if item.shared_inventory
      return true if SHARED_KEY_ITEMS && item.is_a?(RPG::Item) && item.key_item?
      false
    end
  end #ActorInventory
end #TIM

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_shared_items load_database; end
  def self.load_database
    load_database_shared_items
    load_notetags_shared_items
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_shared_items
  #--------------------------------------------------------------------------
  def self.load_notetags_shared_items
    groups = [$data_items,$data_armors,$data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_shared_items
      end
    end
  end
end # DataManager

#============================================================================
# RPG::BaseItem
#============================================================================
class RPG::BaseItem
  attr_reader :shared_inventory
  #--------------------------------------------------------------------------
  # common cache: load_notetags_shared_items
  #--------------------------------------------------------------------------
  def load_notetags_shared_items
    @shared_inventory = false
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::ActorInventoryAddon::REGEXP::SHARED
        @shared_inventory = true
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
  alias shared_item_make_item_list make_item_list
  def make_item_list
    shared_item_make_item_list
    @data = $game_party.all_items.select {|item| include?(item) } + @data
  end
end #Window_ItemList

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor
  #--------------------------------------------------------------------------
  # alias method: gain_item
  #--------------------------------------------------------------------------
  alias shared_gain_item gain_item
  def gain_item(item, amount, include_equip = false)
    return shared_gain_item(item, amount, include_equip) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    $game_party.gain_item(item, amount, include_equip)
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_number
  #--------------------------------------------------------------------------
  alias shared_item_number item_number
  def item_number(item)
    return shared_item_number(item) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    $game_party.item_number(item)
  end
  
  #--------------------------------------------------------------------------
  # alias method: has_item?
  #--------------------------------------------------------------------------
  alias shared_has_item? has_item?
  def has_item?(item, include_equip = false)
    return shared_has_item?(item, include_equip) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    $game_party.has_item?(item, include_equip)
  end
end #Game_Actor

#============================================================================
# Game_Party
#============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # alias method: has_item?
  #--------------------------------------------------------------------------
  alias shared_has_item? has_item?
  def has_item?(item, include_equip = false)
    return shared_has_item?(item, include_equip) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    @inventory.has_item?(item, include_equip)
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_number
  #--------------------------------------------------------------------------
  alias shared_item_number item_number
  def item_number(item)
    return shared_item_number(item) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    @inventory.item_number(item)
  end
  
  #--------------------------------------------------------------------------
  # alias method: gain_item
  #--------------------------------------------------------------------------
  alias shared_gain_item gain_item
  def gain_item(item, amount, include_equip = false)
    return shared_gain_item(item, amount, include_equip) unless TIM::ActorInventoryAddon.shared_inventory?(item)
    @inventory.gain_item(item, amount, include_equip)
  end
end #Game_Party