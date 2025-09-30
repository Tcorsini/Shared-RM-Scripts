#==============================================================================
# Yanfly Weapon Attack Replace addon - states and guard skill v1.1
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 29/09/2025
# Requires: YEA - Weapon Attack Replace v1.01
#==============================================================================
# Update history: 
# 23/09/2025: v1.0 - Initial release
# 29/09/2025: v1.1 - Extended support to armors: priority order is now:
#                    state > weapon > armors > actor > class > default
#==============================================================================
# Description: allows the guard skill to be replaced too by weapons, class or
# actors in their notetags. Also allows states and armors to change the attack 
# or guard skill of actors. The armors have an internal priority order based on
# their armor type too (parametrized in constant ARMOR_ORDER).
# Also changes the pattern of the weapons, now if no attack skill is specified
# the weapon will not set the default skill (optional argument).
#
# If multiple states replace the skills, the one the the highest priority (display
# priority) will prevail. Priority order is: 
# state > weapon > armor > actor > class > default_skill
# 
# To replace the skills, put in your notetags:
# <attack skill: x>
# <guard skill: y>
#==============================================================================
# Term of use: free for both commercial and non commercial games
#==============================================================================
# Installation: put it below Yanfly's Weapon Attack Replace script
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-YEA-WeaponAttackReplace-stateGuard_addon"] = true

module TIM
  module WEAPON_ATTACK_REPLACE
    #set the default guard skill here
    DEFAULT_GUARD_SKILL_ID = 2
    #if you use a weapon which does not specify an attack skill, set the value 
    #to true if you want it to replace the attack skill to the default one 
    #(yanfly's script behavior)
    #false if you want the actor or class to overtake the skill
    WEAPON_DEFAULT_ATK_APPLY = false
    #same for guard skill
    WEAPON_DEFAULT_GRD_APPLY = false
    #choose the priority of armor types: 1,2,3,4 are the default armor types,
    #unregistered armor types will have lower priority
    #order should be from highest priority to lowest
    ARMOR_ORDER = [4,1,3,2]
    
    #don't edit this, this is a cast method
    def self.armors_order_id(a)
      i = ARMOR_ORDER.index(a.etype_id)
      i = ARMOR_ORDER.size if i.nil?
      return i
    end
  end # WEAPON_ATTACK_REPLACE
end # TIM

#==============================================================================
# ▼ Editting anything past this point may potentially result in causing
# computer damage, incontinence, explosion of user's head, coma, death, and/or
# halitosis so edit at your own risk.
#==============================================================================

#==============================================================================
# TIM
#==============================================================================
module TIM
  module REGEXP
    GUARD_SKILL = /<(?:GUARD_SKILL|guard skill):[ ](\d+)>/i
  end # WEAPON_ATTACK_REPLACE
end # TIM

#==============================================================================
# DataManager
#==============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # alias method: load_notetags_war
  #--------------------------------------------------------------------------
  class <<self; alias load_notetags_war_sg load_notetags_war; end
  def self.load_notetags_war
    load_notetags_war_sg
    $data_states.each{|s| s.load_notetags_war unless s.nil?}
    $data_armors.each{|a| a.load_notetags_war unless a.nil?}
  end
end # DataManager

#==============================================================================
# RPG::BaseItem
#==============================================================================
class RPG::BaseItem
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :guard_skill
  #--------------------------------------------------------------------------
  # new method: load_notetags_war_setup
  #--------------------------------------------------------------------------
  def load_notetags_war_setup
    @attack_skill = nil
    @guard_skill = nil
  end
  #--------------------------------------------------------------------------
  # overwrite method: load_notetags_war
  #--------------------------------------------------------------------------
  def load_notetags_war
    load_notetags_war_setup
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when YEA::REGEXP::BASEITEM::ATTACK_SKILL
        @attack_skill = $1.to_i
      when TIM::REGEXP::GUARD_SKILL
        @guard_skill = $1.to_i
      #---
      end
    } # self.note.split
  end
end # RPG::BaseItem

#==============================================================================
# RPG::Class
#==============================================================================
class RPG::Class
  #--------------------------------------------------------------------------
  # override method: load_notetags_war_setup
  #--------------------------------------------------------------------------
  def load_notetags_war_setup
    super
    @attack_skill = YEA::WEAPON_ATTACK_REPLACE::DEFAULT_ATTACK_SKILL_ID
    @guard_skill = TIM::WEAPON_ATTACK_REPLACE::DEFAULT_GUARD_SKILL_ID
  end
end # RPG::Class

#==============================================================================
# RPG::Weapon
#==============================================================================
class RPG::Weapon
  #--------------------------------------------------------------------------
  # override method: load_notetags_war_setup
  #--------------------------------------------------------------------------
  def load_notetags_war_setup
    super
    @attack_skill = YEA::WEAPON_ATTACK_REPLACE::DEFAULT_ATTACK_SKILL_ID if TIM::WEAPON_ATTACK_REPLACE::WEAPON_DEFAULT_ATK_APPLY
    @guard_skill = TIM::WEAPON_ATTACK_REPLACE::DEFAULT_GUARD_SKILL_ID if TIM::WEAPON_ATTACK_REPLACE::WEAPON_DEFAULT_GRD_APPLY
  end
  #--------------------------------------------------------------------------
  # overwrite method: load_notetags_war
  #--------------------------------------------------------------------------
  def load_notetags_war; super; end
end # RPG::Weapon

#==============================================================================
# RPG::Armor
#==============================================================================
class RPG::Armor < RPG::EquipItem
  attr_reader :etype_id
end #RPG::Armor

#==============================================================================
# Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # overwrite method: guard_skill_id
  #--------------------------------------------------------------------------
  def guard_skill_id
    return weapon_guard_skill_id if actor?
    return TIM::WEAPON_ATTACK_REPLACE::DEFAULT_GUARD_SKILL_ID
  end
end # Game_BattlerBase

#==============================================================================
# Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # overwrite method: weapon_attack_skill_id
  #--------------------------------------------------------------------------
  alias weapon_attack_skill_id_war_sg weapon_attack_skill_id
  def weapon_attack_skill_id
    states.each do |s|
      return s.attack_skill if s.attack_skill
    end
    weapons.each do |w|
      return w.attack_skill if w && w.attack_skill
    end
    l = armors.select{|a| a.attack_skill}.sort_by{|a| TIM::WEAPON_ATTACK_REPLACE.armors_order_id(a)}
    return l[0].attack_skill unless l.empty?
    return self.actor.attack_skill unless self.actor.attack_skill.nil?
    return self.class.attack_skill
  end
  #--------------------------------------------------------------------------
  # new method: weapon_guard_skill_id
  #--------------------------------------------------------------------------
  def weapon_guard_skill_id
    states.each do |s|
      return s.guard_skill if s.guard_skill
    end
    weapons.each do |w|
      return w.guard_skill if w && w.guard_skill
    end
    l = armors.select{|a| a.guard_skill}.sort_by{|a| TIM::WEAPON_ATTACK_REPLACE.armors_order_id(a)}
    return l[0].guard_skill unless l.empty?
    return self.actor.guard_skill unless self.actor.guard_skill.nil?
    return self.class.guard_skill
  end
end # Game_Actor

#==============================================================================
# Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # overwrite method: command_guard
  #--------------------------------------------------------------------------
  def command_guard
    @skill = $data_skills[BattleManager.actor.guard_skill_id]
    BattleManager.actor.input.set_skill(@skill.id)
    if $imported["YEA-BattleEngine"]
      status_redraw_target(BattleManager.actor)
      $game_temp.battle_aid = @skill
      if @skill.for_opponent?
        select_enemy_selection
      elsif @skill.for_friend? && @skill.need_selection?
        select_actor_selection
      else
        next_command
        $game_temp.battle_aid = nil
      end
    else
      if !@skill.need_selection?
        next_command
      elsif @skill.for_opponent?
        select_enemy_selection
      else
        select_actor_selection
      end
    end
  end
  #--------------------------------------------------------------------------
  # alias method: on_actor_cancel
  #--------------------------------------------------------------------------
  alias scene_battle_on_actor_cancel_war_sg on_actor_cancel
  def on_actor_cancel
    scene_battle_on_actor_cancel_war_sg
    case @actor_command_window.current_symbol
    when :guard
      @help_window.hide
      @status_window.show
      @actor_command_window.activate
      status_redraw_target(BattleManager.actor)
    end
  end
  #--------------------------------------------------------------------------
  # alias method: on_enemy_cancel
  #--------------------------------------------------------------------------
  alias scene_battle_on_enemy_cancel_war_sg on_enemy_cancel
  def on_enemy_cancel
    scene_battle_on_enemy_cancel_war_sg
    case @actor_command_window.current_symbol
    when :guard
      @help_window.hide
      @status_window.show
      @actor_command_window.activate
      status_redraw_target(BattleManager.actor)
    end
  end
end # Scene_Battle