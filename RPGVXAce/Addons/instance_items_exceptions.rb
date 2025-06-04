#==============================================================================
# Hime's Instance Items addon - exceptions
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 31/05/2025
# Requires: Hime's Instance Items
# Should be compatible with Hime's Core - Inventory, Actor Inventory and 
# TheoAllen's Limited Inventory
#==============================================================================
# Installation: put this below all the cited scripts, if you use my patch
# for them, put this script below the patch.
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

if $imported["TH_InstanceItems"]
$imported = {} if $imported.nil?
$imported["TIM_InstanceItemsExceptions"] = true

module TIM
  module REGEXP
    INSTANCE_EXCEPTION = /<no_instance>/i
  end #REGEXP
end #TIM

#============================================================================
# InstanceManager
#============================================================================
module InstanceManager
  #--------------------------------------------------------------------------
  # alias method: instance_enabled?
  #--------------------------------------------------------------------------
  class <<self; alias exception_instance_enabled? instance_enabled?; end
  def self.instance_enabled?(obj)
    exception_instance_enabled?(obj) && obj.instanciable?
  end
end #InstanceManager


#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_instance_exceptions load_database; end
  def self.load_database
    load_database_instance_exceptions
    load_notetags_instance_exceptions
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_instance_exceptions
  #--------------------------------------------------------------------------
  def self.load_notetags_instance_exceptions
    groups = [$data_items,$data_armors,$data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_instance_exceptions
      end
    end
  end
end # DataManager

#============================================================================
# RPG::BaseItem
#============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # common cache: load_notetags_height
  #--------------------------------------------------------------------------
  def load_notetags_instance_exceptions
    @instanciable = true
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::REGEXP::INSTANCE_EXCEPTION
        @instanciable = false
      end
      #---
    } # self.note.split
    #---
  end
  
  #--------------------------------------------------------------------------
  # new method: instanciable?
  #--------------------------------------------------------------------------
  def instanciable?
    @instanciable
  end
end # RPG::BaseItem

if $imported[:TH_CoreInventory_InstanceItemPatch]
  #============================================================================
  # Game_Inventory
  #============================================================================
  class Game_Inventory
    #-----------------------------------------------------------------------------
    # alias method: weapons -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_weapons weapons
    def weapons
      TH::Instance_Items::Enable_Weapons ? @weapon_list + th_instance_items_weapons.select{|w| !instance_enabled?(w)} : tim_iex_weapons
    end
    
    #-----------------------------------------------------------------------------
    # alias method: items -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_items items
    def items
      TH::Instance_Items::Enable_Items ? @item_list + th_instance_items_items.select{|i| !instance_enabled?(i)} : tim_iex_items
    end

    #-----------------------------------------------------------------------------
    # alias method: armors -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_armors armors
    def armors
      TH::Instance_Items::Enable_Armors ? @armor_list + th_instance_items_armors.select{|a| !instance_enabled?(a)} : tim_iex_armors
    end
  end #Game_Inventory
else #!$imported[:TH_CoreInventory_InstanceItemPatch]
  #============================================================================
  # Game_Party
  #============================================================================
  class Game_Party < Game_Unit
    #-----------------------------------------------------------------------------
    # alias method: weapons -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_weapons weapons
    def weapons
      TH::Instance_Items::Enable_Weapons ? @weapon_list + th_instance_items_weapons.select{|w| !instance_enabled?(w)} : tim_iex_weapons
    end
    
    #-----------------------------------------------------------------------------
    # alias method: items -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_items items
    def items
      TH::Instance_Items::Enable_Items ? @item_list + th_instance_items_items.select{|i| !instance_enabled?(i)} : tim_iex_items
    end

    #-----------------------------------------------------------------------------
    # alias method: armors -> concatenate instance and non-instances
    #-----------------------------------------------------------------------------
    alias tim_iex_armors armors
    def armors
      TH::Instance_Items::Enable_Armors ? @armor_list + th_instance_items_armors.select{|a| !instance_enabled?(a)} : tim_iex_armors
    end
  end
end #$imported[:TH_CoreInventory_InstanceItemPatch]
end