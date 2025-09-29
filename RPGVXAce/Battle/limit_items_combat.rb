#==============================================================================
# Limit items combat
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 29/04/2025
#==============================================================================
# Puts a limit to the number of times items can be used per turn
#==============================================================================
# Installation: put it below Materials and as high as possible in your load order
#==============================================================================
# Terms of use: free for both commercial and non-commercial
#==============================================================================

module LimitItemCombat
  MAX_USE_PER_TURN = 1
end #LimitItemCombat

#============================================================================
# BattleManager
#============================================================================
module BattleManager
  #--------------------------------------------------------------------------
  # alias method: next_command
  #--------------------------------------------------------------------------
  class <<self; alias lic_next_command next_command; end
  def self.next_command
    SceneManager.scene.nb_item_used += 1 if SceneManager.scene_is?(Scene_Battle) && actor && actor.input.item.is_a?(RPG::Item)
    lic_next_command
  end
  #--------------------------------------------------------------------------
  # alias method: prior_command
  #--------------------------------------------------------------------------
  class <<self; alias lic_prior_command prior_command; end
  def self.prior_command
    ret = lic_prior_command
    SceneManager.scene.nb_item_used -= 1 if ret && SceneManager.scene_is?(Scene_Battle) && actor && actor.input.item.is_a?(RPG::Item)
    ret
  end
end #BattleManager

#============================================================================
# Window_ActorCommand
#============================================================================
class Window_ActorCommand < Window_Command
  #--------------------------------------------------------------------------
  # overwrite method: add_item_command
  #--------------------------------------------------------------------------
  def add_item_command
    add_command(Vocab::item, :item, SceneManager.scene_is?(Scene_Battle) && SceneManager.scene.can_use_items?)
  end
end #Window_ActorCommand

#============================================================================
# Scene_Battle
#============================================================================
class Scene_Battle < Scene_Base
  attr_accessor :nb_item_used
  #--------------------------------------------------------------------------
  # alias method: start
  #--------------------------------------------------------------------------
  alias lic_start start
  def start
    @nb_item_used = 0
    lic_start
  end
  #--------------------------------------------------------------------------
  # new method: can_use_items?
  #--------------------------------------------------------------------------
  def can_use_items?
    @nb_item_used < LimitItemCombat::MAX_USE_PER_TURN
  end
  #--------------------------------------------------------------------------
  # alias method: turn_start
  #--------------------------------------------------------------------------
  alias lic_turn_start turn_start
  def turn_start
    @nb_item_used = 0
    lic_turn_start
  end
end #Scene_Battle