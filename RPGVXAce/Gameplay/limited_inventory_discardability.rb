#==============================================================================
# Limited Inventory addon - Discardability Exception
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 02/06/2025
# Requires: TheoAllen - Limited Inventory
# Supports: Hime's Actor Inventory and my compatibility patch
#==============================================================================
# How to use:
# All items (weapons and armors too) are discardable except key items and 
# items with <non_discardable> in their notetags
# You can modify method self.discardable? for more specificities
#==============================================================================
# Installation: put it below TheoAllen's script and my compatibility patch with 
# Actor Invenrtory if you use it
#==============================================================================
# Terms of use: free for commercial and non-commercial projects
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM_DiscardItemExceptions"] = true

module TIM
  module REGEXP
    DISCARDABILITY_EXCEPTION = /<non_discardable>/i
  end #REGEXP
end #TIM

#============================================================================
# TimPatch
#============================================================================
module TimPatch
  #-----------------------------------------------------------------------------
  # overwrite method: discardable?
  #-----------------------------------------------------------------------------
  def self.discardable?(item)
    return false if item.nil?
    return false if item.is_a?(RPG::Item) && item.key_item?
    return item.discardable?
  end
end #TimPatch

#============================================================================
# DataManager
#============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_discard_exceptions load_database; end
  def self.load_database
    load_database_discard_exceptions
    load_notetags_discard_exceptions
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_instance_exceptions
  #--------------------------------------------------------------------------
  def self.load_notetags_discard_exceptions
    groups = [$data_items,$data_armors,$data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_discard_exceptions
      end
    end
  end
end # DataManager

#============================================================================
# RPG::BaseItem
#============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # common cache: load_notetags_discard_exceptions
  #--------------------------------------------------------------------------
  def load_notetags_discard_exceptions
    @discardable = true
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TIM::REGEXP::DISCARDABILITY_EXCEPTION
        @discardable = false
      end
      #---
    } # self.note.split
    #---
  end
  
  #--------------------------------------------------------------------------
  # new method: discardable?
  #--------------------------------------------------------------------------
  def discardable?
    @discardable
  end
end # RPG::BaseItem

unless $imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"]
  #==============================================================================
  # Window_ItemUseCommand
  #==============================================================================
  class Window_ItemUseCommand < Window_Command
    #-----------------------------------------------------------------------------
    # overwrite method: discardable? -> define the method outside of the window obj
    #-----------------------------------------------------------------------------
    def discardable?(item)
      TimPatch.discardable?(item)
    end
  end #Window_ItemUseCommand
end #$imported["TIM_ACTOR_LIMIT_INSTANCE_INVENTORY_Patch"]