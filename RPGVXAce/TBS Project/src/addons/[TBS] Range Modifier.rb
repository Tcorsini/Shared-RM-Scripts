#==============================================================================
# TBS Range Modifier
#------------------------------------------------------------------------------
# Author: Timtrack
# date: 27/02/2025
# Requires: [TBS] by Timtrack
# Includes compatibility with script Hidden Skill Types
#==============================================================================

$imported = {} if $imported.nil?
$imported["TIM-TBS-RangeModifier"] = true #set to false if you wish to disable this feature
raise "TBS RangeModifier requires TBS by Timtrack" unless $imported["TIM-TBS"] if $imported["TIM-TBS-RangeModifier"]

#==============================================================================
# Description
#------------------------------------------------------------------------------
# Allows states, equipments, actors, classes and enemies to modify
# the range of specific skills, skill types or the base attack given a weapon type
#
# A modifier is a list [a,b] or [a,b,c,d]
# where a is a modifier to range_min, b a modifier to range_max,
# c a modifier to area min and d a modifier to area_max
# a,b,c,d are positive or negative integers
#
# Notes for Actors, Classes, Weapons, Armors, Enemies or States:
# <change_range s1,s2: modifier> #s1,s2,s3... are skills ids
# <change_range_stype s1,s2: modifier> #s1,s2,s3... are skills type ids
# <change_range_wtype s1,s2: modifier> #s1,s2,s3... are weapons type ids
# example:
# <change_range 8,10: [0,1,0,0]>
#
# Notes for skills and items:
# <constant_range> #will forbid any range modifications to the ability, even if its id or its type(s) are supposed to be modified
#==============================================================================
# Installation: put it below TBS core and HST if used
#==============================================================================
# Terms of use: same as TBS project
#==============================================================================

module TBS
  module REGEXP
    RANGE_MOD       = /<change_range\s*(\d+(?:\s*,\s*\d+)*)\s*:\s*(\[\s*\-*\d+\s*,\s*\-*\d+(\s*,\s*\-*\d+\s*,\s*\-*\d+)?\s*\])>/i
    RANGE_MOD_STYPE = /<change_range_stype\s*(\d+(?:\s*,\s*\d+)*)\s*:\s*(\[\s*\-*\d+\s*,\s*\-*\d+(\s*,\s*\-*\d+\s*,\s*\-*\d+)?\s*\]*)>/i
    RANGE_MOD_WTYPE = /<change_range_wtype\s*(\d+(?:\s*,\s*\d+)*)\s*:\s*(\[\s*\-*\d+\s*,\s*\-*\d+(\s*,\s*\-*\d+\s*,\s*\-*\d+)?\s*\]*)>/i
    RANGE_CST       = /<\s*constant_range\s*>/i
  end

  def self.constant_range(id,type)
    return ((type == :skill and $data_skills[id].constant_range) or (type == :item and $data_items[id].constant_range))
  end

  if $imported["TIM-HiddenSkillTypes"]
    def self.change_range_mod_type(ability_id, ability_type,spellRng,rpg_item)
      abTypes = ability_type == :item ? HST.item_types(ability_id) : HST.skill_types(ability_id)
      for t in abTypes
        mod = rpg_item.stype_range_mod[t]
        spellRng.apply_modifier(mod) if mod
      end
      return spellRng
    end
  else #with vanilla skill/items types
    def self.change_range_mod_type(ability_id, ability_type,spellRng,rpg_item)
      id = ability_type == :item ? 0 : $data_skills[ability_id].stype_id
      mod = rpg_item.stype_range_mod[id]
      spellRng.apply_modifier(mod) if mod
      return spellRng
    end
  end


  def self.change_range_mod(ability_id, ability_type,spellRng,rpg_item)
    if ability_type == :skill
      mod = rpg_item.skill_range_mod[ability_id]
      spellRng.apply_modifier(mod) if mod
    end
    return TBS.change_range_mod_type(ability_id, ability_type,spellRng,rpg_item)
  end

  #when dealing with attack, the range may change based on weapon type
  def self.change_range_mod_weapon(weapon_type_id,spellRng,rpg_item)
    mod = rpg_item.wtype_range_mod[weapon_type_id]
    spellRng.apply_modifier(mod) if mod
    return spellRng
  end
end


if $imported["TIM-TBS-RangeModifier"]
  #============================================================================
  # DataManager
  #============================================================================
  module DataManager
    #--------------------------------------------------------------------------
    # alias method: load_database
    #--------------------------------------------------------------------------
    class <<self; alias load_database_range_mod load_database; end
    def self.load_database
      load_database_range_mod
      load_notetags_range_mod
    end

    #--------------------------------------------------------------------------
    # new method: load_notetags_range_mod
    #--------------------------------------------------------------------------
    def self.load_notetags_range_mod
      groups = [$data_actors,$data_classes,$data_weapons,$data_armors,$data_enemies,$data_states]
      for group in groups
        for obj in group
          next if obj.nil?
          obj.load_notetags_range_mod
        end
      end
      groups = [$data_skills,$data_items]
      for group in groups
        for obj in group
          next if obj.nil?
          obj.load_notetags_range_cst
        end
      end
    end
  end # DataManager

  #============================================================================
  # RPG::BaseItem
  #============================================================================
  class RPG::BaseItem
    #--------------------------------------------------------------------------
    # public instance variables
    #--------------------------------------------------------------------------
    attr_accessor :skill_range_mod
    attr_accessor :stype_range_mod
    attr_accessor :wtype_range_mod
    attr_accessor :constant_range

    #--------------------------------------------------------------------------
    # common cache: load_notetags_range_cst
    #--------------------------------------------------------------------------
    def load_notetags_range_cst
      @constant_range = false
      #---
      self.note.split(/[\r\n]+/).each { |line|
        case line
        #---
        when TBS::REGEXP::RANGE_CST
          @constant_range = true
        end
      } # self.note.split
      #---
    end

    #--------------------------------------------------------------------------
    # common cache: load_notetags_range_mod
    #--------------------------------------------------------------------------
    def load_notetags_range_mod
      @skill_range_mod = Hash.new
      @stype_range_mod = Hash.new
      @wtype_range_mod = Hash.new
      #---
      self.note.split(/[\r\n]+/).each { |line|
        case line
        #---
        when TBS::REGEXP::RANGE_MOD
          #puts eval($2)
          mod = eval($2)
          $1.scan(/\d+/).each {|id| @skill_range_mod[id.to_i] = mod}
        #---
        when TBS::REGEXP::RANGE_MOD_STYPE
          mod = eval($2)
          $1.scan(/\d+/).each {|id| @stype_range_mod[id.to_i] = mod}
        #---
        when TBS::REGEXP::RANGE_MOD_WTYPE
          mod = eval($2)
          $1.scan(/\d+/).each {|id| @wtype_range_mod[id.to_i] = mod}
        end
      } # self.note.split
      #---
    end
  end # RPG::BaseItem

  #============================================================================
  # Game_Actor
  #============================================================================
  class Game_Actor < Game_Battler
    #--------------------------------------------------------------------------
    # override method: getRange -> takes into account equipments, states, actor and class
    #--------------------------------------------------------------------------
    def getRange(id,type)
      spellRng = super(id,type)
      return spellRng if TBS.constant_range(id,type)
      return change_range_weapon(spellRng) if type == :skill and id == attack_skill_id
      #$data_actors,$data_classes,$data_weapons,$data_armors
      spellRng = TBS.change_range_mod(id,type,spellRng, $data_actors[@actor_id])
      spellRng = TBS.change_range_mod(id,type,spellRng, $data_classes[@class_id])
      for w in weapons
        spellRng = TBS.change_range_mod(id,type,spellRng, w)
      end
      for a in armors
        spellRng = TBS.change_range_mod(id,type,spellRng, a)
      end
      for s_id in @states
        spellRng = TBS.change_range_mod(id,type,spellRng, $data_states[s_id])
      end
      return spellRng
    end

    #--------------------------------------------------------------------------
    # new method: change_range_weapon
    #--------------------------------------------------------------------------
    def change_range_weapon(spellRng)
      wtype = weapons[0] ? weapons[0].wtype_id : 0
      spellRng = TBS.change_range_mod_weapon(wtype,spellRng, $data_actors[@actor_id])
      spellRng = TBS.change_range_mod_weapon(wtype,spellRng, $data_classes[@class_id])
      for w in weapons
        spellRng = TBS.change_range_mod_weapon(wtype,spellRng, w)
      end
      for a in armors
        spellRng = TBS.change_range_mod_weapon(wtype,spellRng, a)
      end
      for s_id in @states
        spellRng = TBS.change_range_mod_weapon(wtype,spellRng, $data_states[s_id])
      end
      return spellRng
    end
  end

  #============================================================================
  # Game_Enemy
  #============================================================================
  class Game_Enemy < Game_Battler
    #--------------------------------------------------------------------------
    # override method: getRange -> takes into account enemy_id and states
    #--------------------------------------------------------------------------
    def getRange(id,type)
      spellRng = super(id,type)
      return spellRng if TBS.constant_range(id,type)
      return change_range_weapon(spellRng) if type == :skill and id == attack_skill_id
      spellRng = TBS.change_range_mod(id,type,spellRng, $data_enemies[@enemy_id])
      for s_id in @states
        spellRng = TBS.change_range_mod(id,type,spellRng, $data_states[s_id])
      end
      return spellRng
    end

    #--------------------------------------------------------------------------
    # new method: change_range_weapon
    #--------------------------------------------------------------------------
    def change_range_weapon(spellRng)
      wtype = 0 #weapons[0] ? weapons[0].wtype : 0
      spellRng = TBS.change_range_mod_weapon(wtype,spellRng, $data_enemies[@enemy_id])
      for s_id in @states
        spellRng = TBS.change_range_mod_weapon(wtype,spellRng, $data_states[s_id])
      end
      return spellRng
    end
  end

  #============================================================================
  # SpellRange
  #============================================================================
  class SpellRange
    #--------------------------------------------------------------------------
    # new method: apply_modifier -> changes the range with an array [min_r,max_r,min_area,max_area]
    #--------------------------------------------------------------------------
    def apply_modifier(mod)
      @range.add_min_range(mod[0])
      @range.add_range(mod[1])
      return if mod.size <= 2
      @area.add_min_range(mod[2])
      @area.add_range(mod[3])
    end
  end
end #imported TIM-TBS-RangeModifier
